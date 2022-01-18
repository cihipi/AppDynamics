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
            If InStr( Arg, " " ) Then Arg = QUOTE & Arg & QUOTE
            Str = Str & " " & Arg
        Next
        CreateObject( "WScript.Shell" ).Run _
            "cscript //nologo " & _
            QUOTE & WScript.ScriptFullName & QUOTE & _
            " " & Str
        WScript.Quit
    End If
End Sub
forceCScriptExecution

' Name of the service
Const AGENT_SVC_NAME = """Appdynamics Machine Agent"""
' Open file in overwrite mode
Const OVERWRITE = 2

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

Function installNetVizExtension()
    Dim machineAgentHome
    machineAgentHome = fsObject.GetParentFolderName(WScript.ScriptFullName)
    WScript.Echo machineAgentHome
    Dim netvizExtensionPath, netvizInstallScript, exists
    netvizExtensionPath = machineAgentHome + "\extensions\NetVizExtension\"
    netvizInstallScript = netvizExtensionPath + "install-extension.bat"
    exists = fsObject.FolderExists(netvizExtensionPath)
    if (exists) then
        execute(netvizInstallScript)
        WScript.Echo "NetViz Agent is installed"
    end if
End Function

installNetVizExtension()

WScript.Echo "Installing AppDynamics Machine Agent into the Service Manager, configured to auto-start."
Dim exitCode
exitCode = execute(serviceExe & " /install-auto non-interactive")
If exitCode <> 0 Then
    WScript.Echo "Failed to install Machine Agent as a Service. Please run this command as an administrator"
Else
    WScript.Echo "Done."

    WScript.Echo "Configure Service to restart on failure"
    execute("SC failure " & AGENT_SVC_NAME & " reset= 432000  actions= restart/30000/restart/60000/run/60000")
    ' On 3rd failure, run a custom action. The default implementation will restart the service.
    Dim failureActionPath
    failureActionPath = QUOTE & scriptDir & "\bin\agent-failure-action.cmd" & QUOTE
    execute("SC failure " & AGENT_SVC_NAME & " command= " & failureActionPath)
    WScript.Echo "Done."

    WScript.Echo "Adding VM parameters for machine agent"
    Dim vmOptionsFile
    Set vmOptionsFile = fsObject.OpenTextFile(scriptDir & "\bin\MachineAgentService.vmoptions", OVERWRITE, True)
    ' Do not create MiniDump on crash. If the option is not supported by the JRE the exe will ignore it.
    vmOptionsFile.WriteLine("-XX:-CreateMinidumpOnCrash")
    vmOptionsFile.WriteLine("-Xms256m")
    vmOptionsFile.WriteLine("-Xmx256m")
    ' Add command line parameters to the vmoptions file
    Dim arg
    For Each arg in WScript.Arguments
        vmOptionsFile.WriteLine(arg)
    Next
    vmOptionsFile.Close

    WScript.Echo "Starting Service"
    execute(serviceExe & " /start")
    WScript.Echo "Done."
End If

' Wait for user input - Disabled for SCCM
' WScript.StdIn.Read(1)
