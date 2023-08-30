

#
# EDIT VARIABLES BELOW FOR YOUR ENVIRONMENT
#
$apitoken = "x-x-x-x" #Your API token, assumes Api v1.x
$endpoint = 'x.x.x.x' #Your array IP or DNS
$PGroup = "TestPGroup" #Enter the name of the Protection Group you want to copy snapshots to volumes for
$FilterDate = (Get-Date).AddDays(-30) #How many days in the past to filter on

#
# DO NOT EDIT BELOW
#

$FlashArray = New-PfaArray -EndPoint $endpoint -ApiToken $apitoken -IgnoreCertificateError 
$Volumes = Get-PfaProtectionGroup -Array $FlashArray -Name $PGroup
$VolumeList = $Volumes.Volumes
ForEach ($Volume in $VolumeList){
    $Snapshots = Get-PfaVolumeSnapshots -Array $FlashArray -VolumeName $Volume | Where-Object {$_.Created -ge $FilterDate}
    ForEach ($Snap in $Snapshots) {
            $DateTime = $Snap.Created 
            $TimeStamp = $DateTime.ToString("yyyyMMddHHmmss")
            New-PfaVolume -Array $FlashArray -VolumeName SAVE-$Volume-$TimeStamp -Source $Snap.Name
    }
}


