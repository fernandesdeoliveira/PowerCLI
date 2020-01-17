
#Download plink.exe from https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
#Save it to the same location than this script
#Edit the account, password
#Edit the host list separated by commas

$root = "root"
$Passwd = "VMware123!"
$esxlist = "192.168.65.201"
$cmd55 = ""
$cmd60 = ""
$cmd65 = "vim-cmd hostsvc/advopt/update UserVars.ESXiVPsDisabledProtocols string 'sslv3,tlsv1'"
$cmd67 = ""

$plink = "echo y | .\plink.exe"

foreach ($esx in $esxlist){
    Connect-VIServer $esx -User  $root -Password $Passwd
    Write-Host -Object "starting ssh services on $esx"
    $sshstatus= Get-VMHostService  -VMHost $esx| where {$psitem.key -eq "tsm-ssh"}
    if ($sshstatus.Running -eq $False){
        Get-VMHostService | where {$psitem.key -eq "tsm-ssh"} | Start-VMHostService -Confirm:$false
    }
    Write-Host -Object "Executing Command on $esx"
    $output = "$plink -ssh $root@$esx -pw $Passwd $cmd65"
    $message = Invoke-Expression -command $output
    $message
    Get-VMHostService | where {$psitem.key -eq "tsm-ssh"} | Stop-VMHostService -Confirm:$false
}

