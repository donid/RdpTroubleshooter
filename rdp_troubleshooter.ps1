# rdp remotedesktop msterminalservices troubleshooting

# to test RDP from 'outside'
# Test-NetConnection -ComputerName MYHOSTNAME -CommonTCPPort RDP

<#
TODO:
Application und System eventlog might have usefull entries or maybe this log:
Get-WinEvent -LogName Microsoft-Windows-RemoteDesktopServices-SessionServices/Operational

here are more settings for RDP:
Start  > Run >  “gpedit.msc”
Navigate to “Computer Configuration > Administrative Templates > Windows Components > Remote Desktop Services > Remote Desktop Session Host > Remote Session Environment”.

#>



# is remote desktop access enabled in the settings?
$regKeyDenyCon = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections'
$denyConVal = $regKeyDenyCon.fDenyTSConnections
if($denyConVal -ne 0)
{
    Write-Output "- RDPConnections are not enabled - fDenyTSConnections=$denyConVal"
}
else
{
    Write-Output "+ RDPConnections are enabled";
}

# changing this value might require a Reboot
$regKeyLanAdapter = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name 'LanAdapter'
$lanAdapterVal=$regKeyLanAdapter.LanAdapter
if($lanAdapterVal -ne 0)
{
    Write-Output "- RDPConnections are only allowed on specific network adapters - LanAdapter=$lanAdapterVal"
}
else
{
    Write-Output "+ RDPConnections are allowed on all network adapters";
}

# which local TCP port should be used
$regKeyPort = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name 'PortNumber'
$localRdpPort=$regKeyPort.PortNumber
Write-Output "local RDP-Port: $localRdpPort";


# which UserAuthentication is configured
$regKeyAuth=Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication'
$authVal='unknown'
if($regKeyAuth.UserAuthentication -eq 0)
{
    $authVal='any version of Remote Desktop (less secure)'
}
elseif($regKeyAuth.UserAuthentication -eq 1)
{
    $authVal='force clients to NLA(Network Layer Authentication) (more secure)'
}
Write-Output "UserAuthentication: $authVal";


# is the service running?
$termsvc=get-service termservice
if($termsvc.Status -eq 'Running')
{
    Write-Output "+ termservice is running";
}
else
{
    Write-Output "- termservice status is $($termsvc.Status)";
}


Write-Output ""
Write-Output "Latest 'RDP-Listener has started listening'-Events (should occur after termservice start):"
Get-WinEvent -LogName Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational | where id -eq 258 | select -First 10



# in tcpview portname: ms-wbt-server
# is svchost.exe listening on the local TCP RDP-Port? should be listening on tcpv6, too
$svcs = Get-CimInstance Win32_service | where {$_.Started -eq "True" -and $_.ServiceType -eq "Share Process"}    
$foundConns = Get-NetTCPConnection -LocalPort $localRdpPort
$conn = $foundConns | select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State,AppliedSetting, OwningProcess,
             @{l="ProcessName" ;e= {Get-Process -Id $_.OwningProcess | select -ExpandProperty Name } },
             @{l="ServiceNames" ; e={($svcs | where ProcessId -eq $_.OwningProcess | select -ExpandProperty Name) -join ','}} `
             | Format-Table  -Wrap -AutoSize


#print connections
Write-Output ""
Write-Output ""
Write-Output "TCP connections on the assigned RDP port:";
$conn

Write-Output ""
Write-Output "NetConnectionProfile(s):"
$conProfile = Get-NetConnectionProfile
Write-Output $conProfile
Write-Output ' => your NetworkCategory(ies)'
Write-Output $conProfile.NetworkCategory 


# print firewall status and RDP rules status
Write-Output ""
Write-Output ""
Write-Output "Firewall status:"
$fwProfiles = Get-NetFirewallProfile | select name,enabled | ft
Write-Output $fwProfiles

Write-Output ""
Write-Output ""
Write-Output "RDP Firewall exception rules:"
Get-NetFirewallRule -DisplayGroup 'Remote Desktop' | Select-Object name, enabled, profile,direction,action `
                    | Format-Table  -Wrap -AutoSize

Write-Output ""
Write-Output "Users that are allowed to connect via RDP:"
# on some machines:
# Get-LocalGroupMember: An unspecified error occurred: error code = 1789
$rdpUsers=Get-LocalGroup -Name 'Administrators','Remote Desktop Users'  | Get-LocalGroupMember -ErrorVariable glgmErrorVar
if($glgmErrorVar -ne $null -and $glgmErrorVar[0].ToString().Contains('error code = 1789') -eq $true)
{
    net localgroup "Remote Desktop users"
    net localgroup "Administrators"
} else {
    Write-Output $rdpUsers
}