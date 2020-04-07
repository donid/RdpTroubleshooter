# RdpTroubleshooter
## Powershell script for RDP / Remote Desktop / MS-Terminal-Services troubleshooting

This script simplifies troubleshooting when RDP connections to a host do not work.
Run it on the host that you want to connect to with RDP (for example with *'Enter-PSSession'* or *'Windows Admin Center'*).
It will show settings and eventlog-entries related to RDP connections, which should help you to find the root cause of the connection problem.

For a quick check, if the connection works use this Powershell command on the client:
>Test-NetConnection -ComputerName MYHOSTNAME -CommonTCPPort RDP

**The script will not change any settings!**