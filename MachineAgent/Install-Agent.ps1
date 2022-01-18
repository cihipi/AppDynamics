# This script installs the machine agent for appdynamics
#
# Version 0.3 - February 2022

# This script has hard coded paths & variables. You will need to edit them.
# The key is that you can spit your sites into production and non production, with different 
# service accounts, proxies, keys and saas endpoints - based on the hostname of where it is being installed.

# Create a log file for refrence
Start-Transcript -Path "C:\temp\machineagent-install-ps1.txt"

# Config in C:, application in D:
md -force "c:\programdata\appdynamics"
md -force "d:\program files\appdynamics\Machine Agent"

# Replace the scripts supplied with ones that don't pause on completion
copy-item -force InstallService-SCCM.vbs "d:\program files\appdynamics\Machine Agent"
copy-item -force UnInstallService-SCCM.vbs "d:\program files\appdynamics\Machine Agent"

# Fetch the server name
$curServer = $env:computername

if (($curServer -like "*stg*") -or ($curServer -like "*tst*")) {
    # Non production
    copy-item -force proxy-tst.txt c:\programdata\appdynamics\proxy.txt

    $arg = @('-Dappdynamics.controller.hostName=sccm-test.saas.appdynamics.com', '-Dappdynamics.controller.port=443', '-Dappdynamics.machine.agent.dotnetCompatibilityMode=true', '-Dappdynamics.http.proxyHost=prdpxylb-app.sccm.local', '-Dappdynamics.http.proxyPasswordFile=c:/programdata/appdynamics/proxy.txt', '-Dappdynamics.http.proxyPort=8080', '-Dappdynamics.http.proxyUser=sccm\svc_appdynamics_tst', '-Dappdynamics.agent.maxMetrics=5000', '-Dappdynamics.agent.accountName=sccm-test', '-Dappdynamics.sim.enabled=true', '-Dappdynamics.agent.accountAccessKey=YourKey', '-Dappdynamics.controller.ssl.enabled=true', '-Xms20m', '-Xmx256m')
} elseif ($curServer -like "*prd*") {
    # Production
    copy-item -force proxy-prd.txt c:\programdata\appdynamics\proxy.txt

    $arg = @('-Dappdynamics.controller.hostName=sccm-prod.saas.appdynamics.com', '-Dappdynamics.controller.port=443', '-Dappdynamics.machine.agent.dotnetCompatibilityMode=true', '-Dappdynamics.http.proxyHost=prdpxylb-app.sccm.local', '-Dappdynamics.http.proxyPasswordFile=c:/programdata/appdynamics/proxy.txt', '-Dappdynamics.http.proxyPort=8080', '-Dappdynamics.http.proxyUser=sccm\svc_appdynamics_prd', '-Dappdynamics.agent.maxMetrics=5000', '-Dappdynamics.agent.accountName=sccm-prod', '-Dappdynamics.sim.enabled=true', '-Dappdynamics.agent.accountAccessKey=YourKey', '-Dappdynamics.controller.ssl.enabled=true', '-Xms20m', '-Xmx256m')
}

if (test-path "d:\program files\appdynamics\Machine Agent\bin\MachineAgentService.vmoptions") {
    Write-Host "Uninstalling old version"

    cscript.exe "d:\program files\appdynamics\machine agent\Uninstallservice-SCCM.vbs"
}

# To deal with not knowing what machine agent version we are using, we use a wildcard
Write-Host "Unzipping new version"
Expand-Archive -Force machineagent*.zip "d:\program files\appdynamics\machine agent"

Write-Host "Installing new version"
cscript.exe "d:\program files\appdynamics\machine agent\installservice-SCCM.vbs" @arg

get-date | out-file -force "c:\programdata\appdynamics\machineinstalled.txt"

write-host "Finished"

Stop-Transcript
