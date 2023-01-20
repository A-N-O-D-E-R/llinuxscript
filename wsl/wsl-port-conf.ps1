function CheckSecurityLevel {
  param(
      [Parameter (Mandatory = $true)] [String] $PathScript,
      [Parameter (Mandatory = $false)] [String] $PathEnvWsl
  )
  if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
      $CommandLine = "-File `"" + $PathScript + "`" `"" +$PathEnvWsl+ "`""
      Write-Host "Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine $PathEnvWsl"
      Start-Process -FilePath PowerShell.exe -Verb Runas  -ArgumentList $CommandLine
      Exit
    }
  }
}


function CheckifWslRunnig {
  if($Null -eq (get-process "wsl" -ea SilentlyContinue))
  {
    Write-Host (" " * $indent) "wsl not running" -ForegroundColor Yellow -BackgroundColor Red
    Write-Host (" " * $indent) "Invoke-Expression $wsl $StopWSL" -ForegroundColor Yellow
    Invoke-Expression "$wsl $StopWSL " -Verbose
    Write-Host (" " * $indent) "Start-Process -FilePath $wsl -ArgumentList $StartWSL" -ForegroundColor Yellow
    Start-Process -FilePath $wsl -ArgumentList $StartWSL -WindowStyle Hidden
    $script:Restarted=$True
    Write-Host (" " * $indent)
  }
}

function CheckNetIP{
  if($Null -eq ( Get-NetIPAddress -InterfaceAlias "vEthernet (WSL)" -ea SilentlyContinue))
  {
      New-NetIPAddress -InterfaceAlias "vEthernet (WSL)" –IPAddress $script:vEthIP –PrefixLength 20
  }
}

function LoadParams{
  param(
      [Parameter (Mandatory = $true)] [String] $YAML_CONT
  )
  Write-Host "Load $PSScriptRoot\wsl_params.yml..." -ForegroundColor DarkCyan
  Write-Host (" " * $indent)
  $script:Params    = ConvertFrom-Yaml -Yaml $YAML_CONT
  $script:Killall   = $Params.WSLCommon.KillallBeforeStarting
  $script:Distrib   = $Params.WSLCommon.Distro
  $script:StopWSL   = $ExecutionContext.InvokeCommand.ExpandString($Params.WSLCommon.StopWSL)
  $script:GetWSLVer = $Params.WSLCommon.GetWSLVer
  $script:GetWSLIP  = $Params.WSLCommon.GetWSLIP
  $script:wsl       = $(get-command wsl.exe).Path
  $script:WSLVer    = $(Invoke-Expression "$wsl $GetWSLVer" ).split(" ")[-3]
  $script:WSLIP     = $(Invoke-Expression "$wsl $GetWSLIP"  ).Replace(' ','')


  # Proxy command
  $script:ShowProxyV4ToV4 = $Params.ProxyV4.ShowProxyV4ToV4
  $script:DelProxyV4ToV4  = $Params.ProxyV4.DelProxyV4ToV4
  $script:AddProxyV4ToV4  = $Params.ProxyV4.AddProxyV4ToV4
  $script:SetProxyV4ToV4  = $Params.ProxyV4.SetProxyV4ToV4
  # "vEthernet (WSL)" @IP
  $script:vEthAlias   = $Params.WSLCommon.vEthAlias
  $script:vEthIP      = $Params.WSLCommon.vEthIP
  $script:vEthMasq    = $Params.WSLCommon.vEthMasq
  $script:DisableIPV6 = $Params.WSLCommon.DisableIPV6
}


function CheckProxyV4 {
param(
      [Parameter (Mandatory = $true)] [System.Int32] $Port
  )

Write-Host (" " * $indent)
Write-Host (" " * $indent) "ProxyV4" -ForegroundColor Gray
# Write-Host (" " * $indent) "vEthIP:$vEthIP., $($vEthIP.Substring(0, 3))" -ForegroundColor Yellow

$v4tov4IP   = [regex]::matches($(Invoke-Expression $ShowProxyV4ToV4), "("+$($vEthIP.Substring(0, 3))+"\.\d{1,3}\.\d{1,3}\.\d{1,3})").value
$v4tov4Port = [regex]::matches($(Invoke-Expression "netsh interface portproxy show v4tov4"), "($Port)").value[0]
$WSLIP      = (Invoke-Expression "$wsl $GetWSLIP"  ).trim()

Write-Host (" " * $indent)
# Write-Host (" " * $indent)( " " * "1" ) "v4tov4IP:$v4tov4IP, v4tov4Port:$v4tov4Port" -ForegroundColor Yellow
# Write-Host (" " * $indent)( " " * "1" ) "$(Invoke-Expression $ShowProxyV4ToV4)" -ForegroundColor Yellow

Write-Host $Port
if ( ($WSLIP -ne $v4tov4IP) -or ($Port -ne $v4tov4Port) ) {
  # Delete Rule
  Write-Host (" " * $indent)( " " * 1 )  "$DelProxyv4Tov4  "  -ForegroundColor Red -NoNewline
  Invoke-Expression $DelProxyv4Tov4 -verbose

  # Create Rule
  Write-Host (" " * $indent)( " " * 1 )  "$AddProxyV4ToV4" -ForegroundColor Green -NoNewline
  Invoke-Expression -Command $AddProxyV4ToV4 -Verbose #| out-null

  $script:v4tov4IP   = [regex]::matches($(Invoke-Expression $ShowProxyV4ToV4), "("+$($vEthIP.Substring(0, 3))+"\.\d{1,3}\.\d{1,3}\.\d{1,3})").value

  }else{
    Write-Color -Text "   ProxyV4 OK : v4tov4IP:","$v4tov4IP", ", WSLIP:", "$WSLIP", ", v4tov4Port:", "$v4tov4Port"  -color Gray,Yellow,Gray,Yellow,Gray,Yellow
  }

Write-Host (" " * $indent)
}
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color) {
for ($i = 0; $i -lt $Text.Length; $i++) {
    Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
}
Write-Host
}


CheckSecurityLevel $MyInvocation.MyCommand.Path $args[0]
$PATH=(Join-Path $PSScriptRoot 'wsl_params.yaml')
LoadParams (Get-Content -Path $PATH -Raw)
CheckifWslRunnig
CheckNetIP
CheckProxyV4 $args[1]
wsl -e sh -c "echo ORIGIN=$(wsl -e sh -c "ip addr show eth0 | grep 'inet\b' | awk '{print `$2}' | cut -d/ -f1")  > $($args[0])"


Write-Color -Text "Distrib:","$Distrib",", version:","$WSLVer",", Restarted:","$Restarted",", state:","$State",", WSLIP:", "$WSLIP", ", ProxyV4:","$v4tov4IP"  `
          -color Gray,Yellow,Yellow,Yellow,Gray,Yellow,Gray,Yellow,Gray,Green,Gray,Green

Write-Host (" " * $indent)
