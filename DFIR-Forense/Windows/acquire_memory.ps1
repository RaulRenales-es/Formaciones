<#
.SYNOPSIS
    acquire_memory.ps1

.DESCRIPTION
    Script DFIR para adquisición de memoria RAM en Windows mediante herramientas externas
    (p.ej., winpmem / DumpIt / Magnet RAM Capture) SI están disponibles localmente.
    El script:
      - Verifica ejecución como Administrador
      - Crea un directorio de evidencias
      - Detecta herramientas soportadas en rutas habituales (mismo directorio / tools\)
      - Ejecuta captura de memoria (si encuentra herramienta)
      - Calcula hashes SHA256 de:
          - Binario de la herramienta usada
          - Fichero(s) de salida
      - Registra todo en Transcript y ficheros auxiliares

    IMPORTANTE:
      - Este script NO descarga herramientas (por licencias/cadena de custodia).
      - No realiza volcado de procesos específicos (p.ej., LSASS). Solo captura de RAM completa
        cuando la herramienta lo permite.

.NOTES
    Autor: Raul Renales
    Uso DFIR - Minimiza cambios, pero la adquisición de memoria SIEMPRE impacta el sistema.
    Requiere PowerShell 5.1+
#>

param(
    # Carpeta base donde buscar herramientas (por defecto, el mismo directorio del script)
    [string]$ToolsRoot = $(Split-Path -Parent $MyInvocation.MyCommand.Path),

    # Carpeta de salida (si no se indica, se crea una con timestamp)
    [string]$OutputRoot = $(Get-Location).Path,

    # Prefijo para el nombre de la evidencia
    [string]$CaseTag = "case",

    # Fuerza el uso de una herramienta concreta si está disponible: winpmem | dumpit | magnet
    [ValidateSet("auto","winpmem","dumpit","magnet")]
    [string]$PreferredTool = "auto"
)

############################
# CONFIGURACIÓN GENERAL
############################

$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$HostName  = $env:COMPUTERNAME
$OutputDir = Join-Path $OutputRoot ("memory_{0}_{1}_{2}" -f $HostName, $CaseTag, $TimeStamp)

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
Start-Transcript -Path (Join-Path $OutputDir "resultados.txt") -Force

function Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================"
    Write-Host "[*] $Title"
    Write-Host "========================================"
}

function Is-Admin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p  = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Write-EnvSnapshot {
    Section "SNAPSHOT DEL ENTORNO (pre-captura)"
    try {
        Get-ComputerInfo | Out-File -Encoding UTF8 -FilePath (Join-Path $OutputDir "computerinfo.txt") -Force
        Write-Host "[+] Guardado computerinfo.txt"
    } catch {
        Write-Host "[!] No se pudo ejecutar Get-ComputerInfo: $($_.Exception.Message)"
    }

    try {
        Get-Process | Sort-Object ProcessName | Select-Object Id,ProcessName,Path,StartTime `
            | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $OutputDir "procesos.csv") -Force
        Write-Host "[+] Guardado procesos.csv"
    } catch {
        Write-Host "[!] No se pudo exportar procesos: $($_.Exception.Message)"
    }

    try {
        Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture,LastBootUpTime `
            | Format-List | Out-File -Encoding UTF8 -FilePath (Join-Path $OutputDir "os.txt") -Force
        Write-Host "[+] Guardado os.txt"
    } catch {
        Write-Host "[!] No se pudo obtener Win32_OperatingSystem: $($_.Exception.Message)"
    }

    try {
        Get-NetTCPConnection | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess `
            | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $OutputDir "net_tcp.csv") -Force
        Write-Host "[+] Guardado net_tcp.csv"
    } catch {
        Write-Host "[!] No se pudo exportar conexiones TCP (Get-NetTCPConnection): $($_.Exception.Message)"
    }
}

function Safe-Hash {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path $Path)) { return $null }
    try {
        return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash
    } catch {
        return $null
    }
}

function Find-Tool {
    param([string]$Name)

    # Rutas típicas: raíz, tools\, bin\
    $candidates = @(
        Join-Path $ToolsRoot $Name,
        Join-Path $ToolsRoot ("tools\{0}" -f $Name),
        Join-Path $ToolsRoot ("bin\{0}" -f $Name)
    )

    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

function Select-Tool {
    # Herramientas soportadas (si están presentes localmente)
    # - winpmem.exe (Rekall/WinPmem)
    # - DumpIt.exe
    # - MagnetRAMCapture.exe (varía según distribución; se incluye nombre común)
    $winpmem = Find-Tool "winpmem.exe"
    $dumpit  = Find-Tool "DumpIt.exe"
    $magnet  = Find-Tool "MagnetRAMCapture.exe"

    $available = [PSCustomObject]@{
        winpmem = $winpmem
        dumpit  = $dumpit
        magnet  = $magnet
    }

    Section "DETECCIÓN DE HERRAMIENTAS"
    $available | Format-List

    if ($PreferredTool -ne "auto") {
        $chosen = $available.$PreferredTool
        if ($chosen) { return [PSCustomObject]@{ Name=$PreferredTool; Path=$chosen } }
        Write-Host "[!] PreferredTool '$PreferredTool' no disponible. Se intentará auto."
    }

    if ($winpmem) { return [PSCustomObject]@{ Name="winpmem"; Path=$winpmem } }
    if ($dumpit)  { return [PSCustomObject]@{ Name="dumpit";  Path=$dumpit  } }
    if ($magnet)  { return [PSCustomObject]@{ Name="magnet";  Path=$magnet  } }

    return $null
}

function Acquire-WithWinpmem {
    param([string]$ToolPath)

    # WinPmem típicamente soporta salida raw. Sintaxis puede variar por versión.
    # Usamos un modo conservador: especificar output y dejar que la herramienta determine formato.
    $out = Join-Path $OutputDir ("{0}_{1}_mem.raw" -f $HostName, $TimeStamp)

    Section "ADQUISICIÓN (winpmem)"
    Write-Host "[+] Herramienta: $ToolPath"
    Write-Host "[+] Salida: $out"

    # Intento 1: argumentos habituales
    $args1 = @("--output", $out)

    try {
        $p = Start-Process -FilePath $ToolPath -ArgumentList $args1 -Wait -PassThru -NoNewWindow
        return [PSCustomObject]@{ OutputFiles=@($out); ExitCode=$p.ExitCode; Args=($args1 -join " ") }
    } catch {
        Write-Host "[!] Error ejecutando winpmem con '--output': $($_.Exception.Message)"
    }

    # Intento 2: algunas builds usan: -o <file>
    $args2 = @("-o", $out)
    try {
        $p = Start-Process -FilePath $ToolPath -ArgumentList $args2 -Wait -PassThru -NoNewWindow
        return [PSCustomObject]@{ OutputFiles=@($out); ExitCode=$p.ExitCode; Args=($args2 -join " ") }
    } catch {
        Write-Host "[!] Error ejecutando winpmem con '-o': $($_.Exception.Message)"
        return $null
    }
}

function Acquire-WithDumpIt {
    param([string]$ToolPath)

    # DumpIt normalmente genera el fichero en el directorio actual por defecto.
    # Ejecutamos desde OutputDir para controlar dónde cae la evidencia.
    Section "ADQUISICIÓN (DumpIt)"
    Write-Host "[+] Herramienta: $ToolPath"
    Write-Host "[+] Directorio de trabajo: $OutputDir"

    $before = Get-ChildItem -Path $OutputDir -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

    try {
        $p = Start-Process -FilePath $ToolPath -WorkingDirectory $OutputDir -Wait -PassThru -NoNewWindow
    } catch {
        Write-Host "[!] Error ejecutando DumpIt: $($_.Exception.Message)"
        return $null
    }

    Start-Sleep -Seconds 2

    $after = Get-ChildItem -Path $OutputDir -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    $newFiles = Compare-Object $before $after | Where-Object { $_.SideIndicator -eq "=>"} | Select-Object -ExpandProperty InputObject

    if (-not $newFiles -or $newFiles.Count -eq 0) {
        Write-Host "[!] No se detectaron ficheros nuevos tras DumpIt. Revisa manualmente."
        $newFiles = @()
    }

    return [PSCustomObject]@{ OutputFiles=$newFiles; ExitCode=$p.ExitCode; Args="" }
}

function Acquire-WithMagnet {
    param([string]$ToolPath)

    # Magnet RAM Capture suele aceptar /output o similares dependiendo de versión.
    # Ejecutamos con un intento conservador: /output <dir>
    Section "ADQUISICIÓN (Magnet RAM Capture)"
    Write-Host "[+] Herramienta: $ToolPath"
    Write-Host "[+] Directorio de trabajo: $OutputDir"

    $before = Get-ChildItem -Path $OutputDir -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName

    $args1 = @("/output", $OutputDir)

    try {
        $p = Start-Process -FilePath $ToolPath -ArgumentList $args1 -WorkingDirectory $OutputDir -Wait -PassThru -NoNewWindow
    } catch {
        Write-Host "[!] Error ejecutando Magnet RAM Capture: $($_.Exception.Message)"
        return $null
    }

    Start-Sleep -Seconds 2
    $after = Get-ChildItem -Path $OutputDir -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    $newFiles = Compare-Object $before $after | Where-Object { $_.SideIndicator -eq "=>"} | Select-Object -ExpandProperty InputObject

    if (-not $newFiles -or $newFiles.Count -eq 0) {
        Write-Host "[!] No se detectaron ficheros nuevos. Revisa parámetros/versión de la herramienta."
        $newFiles = @()
    }

    return [PSCustomObject]@{ OutputFiles=$newFiles; ExitCode=$p.ExitCode; Args=($args1 -join " ") }
}

############################
# EJECUCIÓN
############################

Section "COMPROBACIONES"

if (-not (Is-Admin)) {
    Write-Host "[!] Este script debe ejecutarse como Administrador para capturar memoria y acceder a ciertos artefactos."
    Write-Host "[!] Salida parcial disponible en: $OutputDir"
    Stop-Transcript
    exit 1
}

Write-Host "[+] Ejecutando como Administrador"
Write-Host "[+] OutputDir: $OutputDir"

Write-EnvSnapshot

$Tool = Select-Tool
if (-not $Tool) {
    Section "SIN HERRAMIENTA DE CAPTURA"
    Write-Host "[!] No se encontró ninguna herramienta soportada (winpmem.exe, DumpIt.exe, MagnetRAMCapture.exe)."
    Write-Host "[!] Coloca la herramienta en una de estas rutas y reintenta:"
    Write-Host "    - $ToolsRoot\winpmem.exe"
    Write-Host "    - $ToolsRoot\DumpIt.exe"
    Write-Host "    - $ToolsRoot\MagnetRAMCapture.exe"
    Write-Host "    - $ToolsRoot\tools\ (subcarpeta)"
    Write-Host ""
    Write-Host "[+] Se han guardado snapshots (procesos/red) en: $OutputDir"
    Stop-Transcript
    exit 2
}

Section "HERRAMIENTA SELECCIONADA"
Write-Host "[+] Tool: $($Tool.Name)"
Write-Host "[+] Path: $($Tool.Path)"

# Hash de la herramienta
$ToolHash = Safe-Hash -Path $Tool.Path
if ($ToolHash) {
    Write-Host "[+] SHA256 herramienta: $ToolHash"
    "ToolName,ToolPath,SHA256" | Out-File -Encoding UTF8 -FilePath (Join-Path $OutputDir "hashes.csv") -Force
    "{0},{1},{2}" -f $Tool.Name, $Tool.Path, $ToolHash | Out-File -Encoding UTF8 -FilePath (Join-Path $OutputDir "hashes.csv") -Append
} else {
    Write-Host "[!] No se pudo calcular hash de la herramienta."
}

# Ejecutar adquisición según herramienta
$result = $null
switch ($Tool.Name) {
    "winpmem" { $result = Acquire-WithWinpmem -ToolPath $Tool.Path }
    "dumpit"  { $result = Acquire-WithDumpIt  -ToolPath $Tool.Path }
    "magnet"  { $result = Acquire-WithMagnet  -ToolPath $Tool.Path }
}

Section "RESULTADO ADQUISICIÓN"
if (-not $result) {
    Write-Host "[!] La adquisición no devolvió resultado. Revisa el transcript."
    Stop-Transcript
    exit 3
}

Write-Host "[+] ExitCode: $($result.ExitCode)"
if ($result.Args) { Write-Host "[+] Args: $($result.Args)" }

# Hashes de salida
Section "HASHES DE EVIDENCIA (SHA256)"
if ($result.OutputFiles -and $result.OutputFiles.Count -gt 0) {
    foreach ($f in $result.OutputFiles) {
        if (Test-Path $f) {
            $h = Safe-Hash -Path $f
            Write-Host ("[+] {0} -> {1}" -f $f, $h)
            if ($h) {
                if (-not (Test-Path (Join-Path $OutputDir "hashes.csv"))) {
                    "ToolName,ToolPath,SHA256" | Out-File -Encoding UTF8 -FilePath (Join-Path $OutputDir "hashes.csv") -Force
                }
                "EvidenceFile,{0},{1}" -f $f, $h | Out-File -Encoding UTF8 -FilePath (Join-Path $OutputDir "hashes.csv") -Append
            }
        } else {
            Write-Host "[!] No existe fichero esperado: $f"
        }
    }
} else {
    Write-Host "[!] No se detectaron ficheros de salida automáticamente. Revisa el directorio:"
    Write-Host "    $OutputDir"
}

Section "FINAL"
Write-Host "[+] Evidencias en: $OutputDir"
Write-Host "[+] Script finalizado"

Stop-Transcript
exit 0
