<#PSScriptInfo
.VERSION 1.0.3
.GUID 71977474-9f23-435f-afb9-b3c200852310
.AUTHOR Dr. Raymond Zheng
.COMPANYNAME Telstra Health
.COPYRIGHT 2019 Telstra Health
.TAGS Raymond start stop startvm stopvm startup shutdown
.PRIVATEDATA Written by Dr. Raymond Zheng @ Telstra Health Sydney Australia on 6 March 2019.
.DESCRIPTION
    Start Up or Shut Down or Restart Azure Virtual Machines in Current Subscription.
    Resource group and VM list are supported.
    Requirement: Make sure the default AzureServicePrincipal named 'AzureRunAsConnection' exists in Automation Account --> Connections.
#>

Workflow VM02
{
    Param
    (   
        # Action to perform (startup or shutdown)
        [Parameter(Mandatory=$true)][ValidateSet("start","stop","restart")][String]$Action,
        # Resource group where the vm belongs to
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$ResourceGroup,
        # The list of the VM's to perform action to (separate by ',')
        [Parameter(Mandatory=$false)][String]$VMList

    ) 
    # Suppress Warnings
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    # Authenticate with your Automation Account
    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationID $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
    # Get the Azure VM list
    if($VMList)
    {
        $AzureVMs = $VMList.Split(",")
        [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs
    }
    else
    {
        $AzureVMs = (Get-AzureRmVM $ResourceGroup).Name
        [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs

    }
    # Get the existing VM's
    $VMs = Get-AzureRmVM $ResourceGroup
    # Check the existence of each VM
    foreach($AzureVM in $AzureVMsToHandle)
    {
        if(!($VMs| ? {$_.Name -eq $AzureVM}))
        {
            Write-Error "AzureVM : [$AzureVM] - Does not exist! - Check your inputs!" -TargetObject $_
            throw " AzureVM : [$AzureVM] - Does not exist!"
        }
    }
    #Shut down or Start up VM's
    if($Action -eq "start")
    {
        foreach -parallel ($AzureVM in $AzureVMsToHandle)
        {
            $status = $VMs | ? {$_.Name -eq $AzureVM} | Start-AzureRmVM -ErrorAction Continue;
            if($status.IsSuccessStatusCode){
                Write-Output "Starting VMs: [$AzureVM] - Succeeded!"
            }else{
                Write-Output "Starting VMs: [$AzureVM] - Failed!"
            }
        }
    }elseif($Action -eq "Stop")
    {
        foreach -parallel ($AzureVM in $AzureVMsToHandle)
        {
            $status = $VMs | ? {$_.Name -eq $AzureVM} | Stop-AzureRmVM -Force -ErrorAction Continue;
            if($status.IsSuccessStatusCode){
                Write-Output "Stopping VMs: [$AzureVM] - Succeeded!"
            }else{
                Write-Output "Stopping VMs: [$AzureVM] - Failed!"
            }
        }
    }elseif($Action -eq "restart")
    {
        foreach -parallel ($AzureVM in $AzureVMsToHandle)
        {
            $status = $VMs | ? {$_.Name -eq $AzureVM} | Restart-AzureRmVM -ErrorAction Continue;
            if($status.IsSuccessStatusCode){
                Write-Output "Retarting VMs: [$AzureVM] - Succeeded!"
            }else{
                Write-Output "Retarting VMs: [$AzureVM] - Failed!"
            }
        }
    }else{
        Write-Error "Action: [$Action] - Input Error! - Check your inputs! (Only 'start', 'stop' and 'restart' are allowed!)" -TargetObject $_
    }
}
