# ----------------------------------------------------------
# get-user-licenses-and-plans.ps1
# Get all users of a Office 365 tenant and all assigned licenses and plans.
# One plan assignment is in one column.
# based on these articles & script:
# Source: https://gallery.technet.microsoft.com/scriptcenter/Export-a-Licence-b200ca2a
# article. https://mymicrosoftexchange.wordpress.com/2015/03/23/office-365-script-to-get-detailed-report-of-assigned-licenses/
# TP, 16.09.2016
# ----------------------------------------------------------
# https://technet.microsoft.com/en-us/library/dn771773.aspx
# Get the license informations: Connect-MsolService and authenticate then use Get-MsolAccountSku
# Get-MsolAccountSku | Select-Object *
#
# AccountSkuId                  ActiveUnits WarningUnits ConsumedUnits
# ------------                  ----------- ------------ -------------
# pfoten:ENTERPRISEPACK_FACULTY 360         0            343          
# $license = "pfoten:ENTERPRISEPACK_FACULTY"
# Use the commands Get-MsolAccountSku and (Get-MsolAccountSku | where {$_.AccountSkuId -eq '<AccountSkuId>'}).ServiceStatus to find the following information:
# The licensing plans that are available in your organization.
# (Get-MsolAccountSku | where {$_.AccountSkuId -eq $license}).ServiceStatus

# The Output will be written to this file in the current working directory
$LogFile = ".\Office_365_Licenses-overview3.csv"

# Connect to Microsoft Online
# Import-Module MSOnline
# Connect-MsolService -Credential $Office365credentials
# write-host "Connecting to Office 365..."

# Get a list of all licences that exist within the tenant
$licensetype = Get-MsolAccountSku | Where {$_.ConsumedUnits -ge 1}

# Loop through all licence types found in the tenant
$i = 1
foreach ($license in $licensetype) 
{	
	# Build and write the Header for the CSV file
	$headerstring = "DisplayName,UserPrincipalName,AccountSku"
	
	foreach ($row in $($license.ServiceStatus)) 
	{
		$headerstring = ($headerstring + "," + $row.ServicePlan.servicename)
	}
	
	Out-File -FilePath $LogFile -InputObject $headerstring -Encoding UTF8
	
    # Now get the user licenses and plans
	write-host ("Gathering users with the following subscription: " + $license.accountskuid)

	# Gather users for this particular AccountSku
	#$users = Get-MsolUser -all | where {$_.isLicensed -eq "True" -and $_.licenses.accountskuid -contains $license.accountskuid}
    $users = Get-MsolUser -all | where {$_.licenses.accountskuid -contains $license.accountskuid}

	# Loop through all users and write them to the CSV file
	foreach ($user in $users) {
		
        $dn = $($user.displayname).Replace(","," ")
	    write-host ("$i. $dn")
        $i++

        $thislicense = $user.licenses | Where-Object {$_.accountskuid -eq $license.accountskuid}
		$datastring = ($dn + "," + $user.userprincipalname + "," + $license.SkuPartNumber)
		
		foreach ($row in $($thislicense.servicestatus)) {
			# Build data string: PendingActivation, Disabled, Success
            $st = $row.provisioningstatus
            if ($st -eq "PendingActivation") {$st = '1'}
            if ($st -eq "Success") {$st = '1'}
            if ($st -eq "Disabled") {$st = '0'}
			$datastring = ($datastring + "," + $st)
		}
		
		Out-File -FilePath $LogFile -InputObject $datastring -Encoding UTF8 -append
	}
}			

if (1 -eq 1) {
    # added: users without license
    $users = Get-MsolUser -all | where {$_.isLicensed -ne "True"}
    foreach ($user in $users) {
		
        $dn = $($user.DisplayName).Replace(","," ")
	    write-host ("$i. $dn")
        $i++

	    $datastring = ($dn + "," + $user.userprincipalname + ",No License")
		
	    Out-File -FilePath $LogFile -InputObject $datastring -Encoding UTF8 -append
    }
}
#Out-File -FilePath $LogFile -InputObject " " -Encoding UTF8 -append

write-host ("Done. Check " + $LogFile)
