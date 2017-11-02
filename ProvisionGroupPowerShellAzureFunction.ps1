# ProvisionGroup-PowerShell-Azure-Function.ps1

# atwork.at, Martina Grom



$requestBody = Get-Content $req -Raw | ConvertFrom-Json

$GroupName = $requestBody.GroupName

$upn = $requestBody.upn



Write-Output "TenantID $env:TenantID -ClientKey $env:AppSecret -AppID $env:AppID"



function Initialize-Authorization {

    param

    (

      [string]

      $ResourceURL = 'https://graph.microsoft.com',

  

      [string]

      [parameter(Mandatory)]

      $TenantID,

      

      [string]

      [Parameter(Mandatory)]

      $ClientKey,

  

      [string]

      [Parameter(Mandatory)]

      $AppID

    )



    $Authority = "https://login.windows.net/$TenantID/oauth2/token"



    [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null

    $EncodedKey = [System.Web.HttpUtility]::UrlEncode($ClientKey)



    $body = "grant_type=client_credentials&client_id=$AppID&client_secret=$EncodedKey&resource=$ResourceUrl"



    # Request a Token from the graph api

    $result = Invoke-RestMethod -Method Post `

                        -Uri $Authority `

                        -ContentType 'application/x-www-form-urlencoded' `

                        -Body $body



    $script:APIHeader = @{'Authorization' = "Bearer $($result.access_token)" }

}





# Initialize Authorization

Initialize-AUthorization -TenantID $env:TenantID -ClientKey $env:AppSecret -AppID $env:AppID



# Create the Office 365 group

$json = @"

{ "displayName": "$GroupName",

"mailenabled" : true,

"mailnickname":"$GroupName",

"securityenabled" : true,

"description": "$GroupName",

"groupTypes": ["Unified"]

}

"@



try {

$result = Invoke-RestMethod -Method Post `

                            -Uri "https://graph.microsoft.com/v1.0/groups" `

                            -ContentType 'application/json' `

                            -Headers $script:APIHeader `

                            -Body $json `

                            -ErrorAction Stop



# and save the generated Group ID

$GroupID = $result.id

} catch {

    Write-Output "ERROR! $_"

}



# Get the User ID

$OwnerObject = Invoke-RestMethod -Method Get `

                            -Uri "https://graph.microsoft.com/v1.0/users/$upn" `

                            -ContentType 'application/json' `

                            -Headers $script:APIHeader `

                            -ErrorAction Stop



# Add User as Owner

$json = @"

{ "@odata.id": "https://graph.microsoft.com/v1.0/users/$($OwnerObject.id)" }

"@



try {

$result = Invoke-RestMethod -Method Post `

                            -Uri "https://graph.microsoft.com/v1.0/groups/$GroupID/owners/`$ref" `

                            -ContentType 'application/json' `

                            -Headers $script:APIHeader `

                            -Body $json `

                            -ErrorAction Stop

} catch {

    Write-Output "ERROR! $_"

}





# add user as Member

try {

$result = Invoke-RestMethod -Method Post `

                            -Uri "https://graph.microsoft.com/v1.0/groups/$GroupID/members/`$ref" `

                            -ContentType 'application/json' `

                            -Headers $script:APIHeader `

                            -Body $json `

                            -ErrorAction Stop

} catch {

    Write-Output "ERROR! $_"

}



# return value

Out-File -Encoding Ascii -FilePath $res -inputObject "End of group creation $GroupName"
