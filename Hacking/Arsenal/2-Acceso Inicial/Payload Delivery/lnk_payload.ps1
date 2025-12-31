<#
 Script: lnk_payload.ps1
 Autor: Raul Renales
 Formación y cursos: https://raulrenales.es

 Descripción:
   Crea un acceso directo (.lnk) educativo que abre Notepad.
   Demuestra el vector LNK sin comportamiento malicioso.

 Uso:
   Exclusivamente educativo y en entornos autorizados.
#>

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$PWD\Demo_Notepad.lnk")

$Shortcut.TargetPath = "C:\Windows\System32\notepad.exe"
$Shortcut.WorkingDirectory = "C:\Windows\System32"
$Shortcut.IconLocation = "C:\Windows\System32\notepad.exe,0"
$Shortcut.Description = "Acceso directo educativo (LNK demo)"

$Shortcut.Save()
Write-Output "Acceso directo educativo creado: Demo_Notepad.lnk"
