#Install these modules before running the script#
#################################################
#Install-Module -Name PureStoragePowerShellSDK
#Install-Module VMware.PowerCLI
#Install-Module -Name PureStorage.FlashArray.VMware

#Import modules needed, assuming they have already been installed
Import-Module VMware.VimAutomation.Core 
Import-Module PureStoragePowerShellSDK
Import-Module PureStorage.FlashArray.VMware  

Write-Host -foregroundcolor DarkRed "
This script will clone all matching disks from a source VM to a target VM.  The first disk is assumed to the OS/boot disk and will be excluded. 
If capacities between source and target differ the script will skip them and move on to the next."

#Connect to FlashArray, change username and password
$FlashArray = New-PfaArray -EndPoint 1.1.1.1 -UserName pureuser -Password (ConvertTo-SecureString -String 'pureuser' -AsPlainText -Force) -IgnoreCertificateError
#Connect to vCenter
$vcenter = '1.1.1.1' # ENTER IP OR DNS NAME OF VCENTER
$UserName = 'administrator@vsphere.local' # vCenter username
$SecurePassword = 'password' | ConvertTo-SecureString -AsPlainText -Force #Etner your password
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false | Out-Null
Connect-VIServer -server $vcenter -Credential $cred -WarningAction SilentlyContinue | Out-Null

#Capture user inputs for VM names and check if they exist, no current error checking to reenter a VM name, can be added later
$SourceVM = Read-Host "Please enter the name of the source VM"
$Exists = get-vm -name $SourceVM -ErrorAction SilentlyContinue
If ($Exists){
	Write-Host "Cool, we found the VM!"
}
Else {
	Write-Host "VM doesn't exist, fat finger?"
}

$TargetVM = Read-Host "Please enter the name of the target VM" 
$Exists = get-vm -name $TargetVM -ErrorAction SilentlyContinue
If ($Exists){
	Write-Host "Cool, we found the VM!"
}
Else {
	Write-Host "VM doesn't exist, fat finger?"
}

#Build disk lists and skip boot drive
$SourceDisks = Get-VM $SourceVM | Get-HardDisk
$SourceDisks = $SourceDisks | Select -Skip 1

$TargetDisks = Get-VM $TargetVM | Get-HardDisk
$TargetDisks = $TargetDisks | Select -Skip 1


#Shutdown the target VM before we clone the disks, wait for guest VM to be poweroff before continuing
$TargetGuest = Get-VM $TargetVM
If ($TargetGuest.PowerState -eq "PoweredOn")
    {
            Shutdown-VMGuest -VM $TargetGuest -Confirm:$False -ErrorAction SilentlyContinue
                  Do {        
                    Start-Sleep -s 5             
             }Until ((Get-VM -Name $TargetGuest).PowerState -eq "PoweredOff")
    }

#Overwrite the source hard disks, skip disks where capacities do not match   
ForEach($SourceDisk in $SourceDisks)
{
	ForEach($TargetDisk in $TargetDisks)
	{
		If($SourceDisk.CapacityGB -eq $TargetDisk.CapacityGB)
		{
			Copy-PfaVvolVmdkToExistingVvolVmdk -SourceVmdk $SourceDisk -targetVmdk $TargetDisk -FlashArray $FlashArray
		}
	}
}

#Start our VM back up
Start-VM -VM $TargetVM



