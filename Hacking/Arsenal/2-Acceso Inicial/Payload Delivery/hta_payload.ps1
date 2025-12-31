<#
 Script: hta_payload.ps1
 Autor: Raul Renales
 Formación y cursos: https://raulrenales.es

 Descripción:
   Genera un HTA educativo que demuestra el vector HTA
   sin ejecutar acciones dañinas (abre Notepad).

 Uso:
   Exclusivamente educativo y en entornos autorizados.
#>

$OutFile = "demo.hta"

$hta = @"
<html>
<head>
<hta:application
  applicationname="HTA Demo"
  border="thin"
  showintaskbar="yes"
/>
<script language="VBScript">
  MsgBox "HTA educativo: demostración del vector HTA.", 64, "Demo"
  CreateObject("WScript.Shell").Run "notepad.exe"
</script>
</head>
<body>
  <h3>HTA educativo</h3>
  <p>Este archivo es solo para formación.</p>
</body>
</html>
"@

$hta | Out-File -Encoding ASCII $OutFile
Write-Output "HTA educativo creado: $OutFile"
