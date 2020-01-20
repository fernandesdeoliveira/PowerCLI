<#
    Created by Fabiano Oliveira 2020-01-20
    https://github.com/fernandesdeoliveira/PowerCLI/blob/master/AdjustESXiTLS.ps1
    
    USE AT YOUR OWN RISK!
    
    This script is only for ESXi hosts, not for vCenters
    The script will define which TLS versions must be disabled in the ESXi hosts 
        With no necessary action being performed using vmware-TlsReconfigurator/EsxTlsReconfigurator/reconfigureEsx tool
        You can disable/enable TLS version on a cluster with mixed ESXi versions

    Lockdown mode must be turned off

    Tested on ESXi hosts 5.5, 6.0, 6.5 and 6.7 using PowerCLI 11.5, it may works on different versions
    
    The script will enable SSH and disable it after the operation on each host
    
    Download plink.exe from https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
    Save it to the same location than this script
    Edit the account, password
    Edit the host list separated by commas with double quotes for each hostname or IP
    Edit the list of TLS version that you require to be disabled

    Note: a good result for each host will report red lines like these:
        .\plink.exe : Keyboard-interactive authentication prompts from server:
        At line:1 char:10
        + echo y | .\plink.exe -ssh root@esxi65a.lab.local -pw VMware123! vim-c ...
        +          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (Keyboard-intera...ts from server::String) [], RemoteException
        + FullyQualifiedErrorId : NativeCommandError
         
        End of keyboard-interactive prompts from server

#>

$root = "root"
$Passwd = "VMware123!"
$esxlist = "esxi55a.lab.local","esxi60a.lab.local","esxi65a.lab.local"
$TLSDisable = "'sslv3,tlsv1,tlsv1.1'"

#Warning! no changes required beyond this point

$plink = "echo y | .\plink.exe"

foreach ($esx in $esxlist){
    $thisHost = Connect-VIServer $esx -User  $root -Password $Passwd
    $ESXiVersion = $thisHost.Version -replace "\.", ""
    Write-Host -Object "starting ssh services on $esx"
    $sshstatus= Get-VMHostService  -VMHost $esx| where {$psitem.key -eq "tsm-ssh"}
    if ($sshstatus.Running -eq $False){
        Get-VMHostService | where {$psitem.key -eq "tsm-ssh"} | Start-VMHostService -Confirm:$false
    }
    Write-Host -Object "Host is running version $ESXiVersion"
    Write-Host -Object "Executing Command on $esx"
    if($ESXiVersion -eq 550){
        Invoke-Expression -command "$plink -ssh $root@$esx -pw $Passwd esxcli system settings advanced set -o /UserVars/ESXiRhttpproxyDisabledProtocols -s $TLSDisable"
        Invoke-Expression -command "$plink -ssh $root@$esx -pw $Passwd esxcli system settings advanced set -o /UserVars/VMAuthdDisabledProtocols -s $TLSDisable"
        Invoke-Expression -command "$plink -ssh $root@$esx -pw $Passwd esxcli system settings advanced set -o /UserVars/ESXiVPsDisabledProtocols -s $TLSDisable"
    }
    if($ESXiVersion -eq 600){
        Invoke-Expression -command "$plink -ssh $root@$esx -pw $Passwd vim-cmd hostsvc/advopt/update UserVars.ESXiRhttpproxyDisabledProtocols string $TLSDisable"
        Invoke-Expression -command "$plink -ssh $root@$esx -pw $Passwd vim-cmd hostsvc/advopt/update UserVars.VMAuthdDisabledProtocols string $TLSDisable"
        Invoke-Expression -command "$plink -ssh $root@$esx -pw $Passwd vim-cmd hostsvc/advopt/update UserVars.ESXiVPsDisabledProtocols string $TLSDisable"
    }
    if($ESXiVersion -eq 650){
        Invoke-Expression -command "$plink -ssh $root@$esx -pw $Passwd vim-cmd hostsvc/advopt/update UserVars.ESXiVPsDisabledProtocols string $TLSDisable"
    }
    if($ESXiVersion -eq 670){
        Invoke-Expression -command "$plink -ssh $root@$esx -pw $Passwd vim-cmd hostsvc/advopt/update UserVars.ESXiVPsDisabledProtocols string $TLSDisable"
    }
    Get-VMHostService | where {$psitem.key -eq "tsm-ssh"} | Stop-VMHostService -Confirm:$false
    Disconnect-VIServer $esx -Confirm:$false
}

Write-Host -Object "Hosts that may still connected:"
$global:defaultviserver

Write-Host -Object "End of the process"

