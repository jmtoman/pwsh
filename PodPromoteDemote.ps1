<#
#Requires -Module PureStoragePowerShellSDK2

.SYNOPSIS
Connects to a FlashArray and runs a promotion or demotion on all available pods, excluding pods referencing Veeam per customer request.

.PARAMETER Array
FQDN or IP address of the FlashArray to connect to.

.NOTES 
This script requires PureStoragePowerShellSDK2 to be installed.  It will attempt to import the module.

.EXAMPLE
PS> .\ProdPromotion.ps1 -Array 192.168.10.10 -Promote

#>
param(
    [parameter(Mandatory = $true)][string]$Array,
    [Parameter(Mandatory=$false)][switch]$demote,
    [Parameter(Mandatory=$false)][switch]$promote

)

#Prework
Import-Module -Name PureStoragePowerShellSDK2
$outputDate = Get-Date –f "MM-dd-yyyy-HHmm"
$logFile = "$pwd\PodPromoteDemote_"+$outputDate+".log"

# Connect to the array
Try {
    $pfa = Connect-Pfa2Array -Endpoint $Array -Credential (Get-Credential -Message "FlashArray Administrator Login") -IgnoreCertificateError
}
Catch {
    Throw "Failed to log in to Pure Storage FlashArray $($Array)"
}

# Send all output to a log file
Start-Transcript -Path $logFile

#Collect PODs that are demoted and not in the eradication bucket
If ($promote -eq $true) {
    $Pods = Get-Pfa2Pod -Array $pfa | Where-Object {($_.Destroyed -ne $true) -and ($_.PromotionStatus -eq 'demoted') -and ($_.Name -notlike '*Veeam*')}
    ForEach ($Pod in $Pods){
        Try {
            Update-Pfa2Pod -Array $pfa -Name $Pod.Name -RequestedPromotionState "promoted"        
        }
        Catch {
            Throw "Failed to promote pod $pod"
        } 
    }
}

If ($demote -eq $true) {
    $Pods = Get-Pfa2Pod -Array $pfa | Where-Object {($_.Destroyed -ne $true) -and ($_.PromotionStatus -eq 'promoted') -and ($_.Name -notlike 'Veeam*')}
    ForEach ($Pod in $Pods){
        Try {
            Update-Pfa2Pod -Array $pfa -Name $Pod.Name -RequestedPromotionState "demoted"        
        }
        Catch {
            Throw "Failed to demote pod $pod"
        } 
    }
}

# Stop logging
Stop-Transcript

# Disconnect from the FlashArray
Disconnect-Pfa2array -Array $pfa


