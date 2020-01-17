
<#
    Download plink.exe from https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
    Save it to the same location than this script
    Edit the account, password
    Edit the host list separated by commas
#>

$root = "root"
$Passwd = "VMware123!"
#$esxlist = "esxi65a.lab.local","esxi65b.lab.local","esxi65c.lab.local","esxi65d.lab.local"
$esxlist = "esxi65a.lab.local"

$cmd550 = ""
$cmd600 = ""
$cmd650 = "vim-cmd hostsvc/advopt/update UserVars.ESXiVPsDisabledProtocols string 'sslv3,tlsv1,tlsv1.1'"
$cmd670 = ""

$plink = "echo y | .\plink.exe"
$remoteCommand = '"' + $cmd + '"'

foreach ($esx in $esxlist){
    $thisHost = Connect-VIServer $esx -User  $root -Password $Passwd
    $ESXiVersion = $thisHost.Version -replace "\.", ""
    Write-Host -Object "Host is running version $ESXiVersion"
    
    Write-Host -Object "starting ssh services on $esx"
    $sshstatus= Get-VMHostService  -VMHost $esx| where {$psitem.key -eq "tsm-ssh"}
    if ($sshstatus.Running -eq $False){
        Get-VMHostService | where {$psitem.key -eq "tsm-ssh"} | Start-VMHostService -Confirm:$false
    }
    Write-Host -Object "Executing Command on $esx"

    if($ESXiVersion -eq 550){
        $output = "$plink -ssh $root@$esx -pw $Passwd $cmd550"
    }
    if($ESXiVersion -eq 600){
        $output = "$plink -ssh $root@$esx -pw $Passwd $cmd600"
    }
    if($ESXiVersion -eq 650){
        $output = "$plink -ssh $root@$esx -pw $Passwd $cmd650"
    }
    if($ESXiVersion -eq 670){
        $output = "$plink -ssh $root@$esx -pw $Passwd $cmd670"
    }

    $message = Invoke-Expression -command $output
    $message
    Get-VMHostService | where {$psitem.key -eq "tsm-ssh"} | Stop-VMHostService -Confirm:$false
    Disconnect-VIServer $esx -Confirm:$false
}

$global:defaultviserver

