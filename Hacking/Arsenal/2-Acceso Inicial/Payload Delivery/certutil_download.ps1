<#
 Script: certutil_download.ps1
 Autor: Raul Renales
 Formación y cursos: https://raulrenales.es

 Descripción:
   Demuestra el uso de certutil para descarga de archivos
   con un recurso inocuo (texto) para formación.

 Uso:
   Exclusivamente educativo y en entornos autorizados.
#>

$Url = "https://example.com/"
$OutFile = "download_demo.txt"

cmd.exe /c "certutil -urlcache -split -f $Url $OutFile"

if (Test-Path $OutFile) {
  Write-Output "Descarga educativa completada: $OutFile"
} else {
  Write-Output "No se pudo completar la descarga."
}
