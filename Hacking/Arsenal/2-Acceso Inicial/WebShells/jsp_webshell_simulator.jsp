<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
/*
------------------------------------------------------------
 Script: jsp_webshell_simulator.jsp
 Autor: Raul Renales
 Formación y cursos: https://raulrenales.es

 Descripción:
   Simulador educativo de webshell JSP. NO ejecuta comandos.
   Diseñado para prácticas de detección (logs, WAF, reglas, YARA).

 Uso:
   Exclusivamente educativo y en entornos autorizados.
------------------------------------------------------------
*/
String PASSWORD = "changeme"; // Cambiar SIEMPRE en laboratorio

String pass = request.getParameter("password");
if (pass == null || !pass.equals(PASSWORD)) {
  response.setStatus(403);
  out.print("Access denied");
  return;
}

String cmd = request.getParameter("cmd"); // Se captura pero NO se ejecuta
%>
<!DOCTYPE html>
<html>
<head><title>JSP WebShell Simulator (Lab)</title></head>
<body>
  <h3>JSP WebShell Simulator (Lab)</h3>
  <p><strong>Nota:</strong> este simulador no ejecuta comandos. Solo refleja entrada para prácticas defensivas.</p>

  <form method="post">
    <input type="password" name="password" placeholder="Password" required /><br/><br/>
    <input type="text" name="cmd" placeholder="Command" size="70" autofocus /><br/><br/>
    <input type="submit" value="Submit" />
  </form>

  <hr/>
  <h4>Input recibido</h4>
  <pre><%= (cmd == null ? "" : org.apache.commons.text.StringEscapeUtils.escapeHtml4(cmd)) %></pre>
</body>
</html>
