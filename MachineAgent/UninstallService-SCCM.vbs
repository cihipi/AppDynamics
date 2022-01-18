'
' Copyright (c) AppDynamics, Inc., and its affiliates, 2014, 2015
' All Rights Reserved
'

' Require explicitly declaring variables
Option Explicit

' quote character
Const QUOTE = """"

' Force this script to run using cscript
Sub forceCScriptExecution
    Dim Arg, Str
    If Not LCase( Right( WScript.FullName, 12 ) ) = "\cscript.exe" Then
        For Each Arg In WScript.Arguments
            If InStr( Arg, " " ) Then Arg = """" & Arg & """"
            Str = Str & " " & Arg
        Next
        CreateObject( "WScript.Shell" ).Run _
            "cscript //nologo """ & _
            WScript.ScriptFullName & _
            """ " & Str
        WScript.Quit
    End If
End Sub
forceCScriptExecution

Dim fsObject
Set fsObject = CreateObject("Scripting.FileSystemObject")

Dim scriptDir, serviceExe
scriptDir = fsObject.GetParentFolderName(WScript.ScriptFullName)
serviceExe = QUOTE & scriptDir & "\bin\MachineAgentService.exe" & QUOTE

' Executes a command and prints anything the process writes to stdout
' Returns Exit code of the command
Function execute(cmd)
    Dim shell, shellExec
    Set shell = CreateObject("WScript.Shell")
    Set shellExec = shell.exec(cmd)
    Do Until shellExec.Status
        WScript.Sleep 100
    Loop
    Dim out
    out = shellExec.StdOut.ReadAll()
    If Not IsEmpty(out) Then
        WScript.Echo out
    End If
    execute = shellExec.ExitCode
End Function

WScript.Echo "Attempting to Stop Machine Agent Service"
execute(serviceExe & " /stop")

WScript.Echo "Uninstalling AppDynamics Machine AgentService from the Service Manager"
Dim exitCode
exitCode = execute(serviceExe & " /uninstall")
If exitCode <> 0 Then
    WScript.Echo "Failed to uninstall Machine Agent as a Service. Please run this command as an administrator"
    WScript.Quit
End If
WScript.Echo "Done."
WScript.Echo "Removing Machine Agent VM options"
execute("cmd /c DEL /Q " & QUOTE & scriptDir & "\bin\MachineAgentService.vmoptions" & QUOTE)
WScript.Echo "Done."

' Wait for user input - Disabled for SCCM
' WScript.StdIn.Read(1)
