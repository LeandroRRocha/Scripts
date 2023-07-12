Import-Module Microsoft.Graph.Identity.SignIns
Import-Module Microsoft.Graph.Users

$tenantID = "<Your Tenant ID>" 
$ApplicationId = "<App ID>"
$SecuredPassword = "<secret>"
$TenantName = "<Your Tenant Name>"
$Report = @()

$SecuredPasswordPassword = ConvertTo-SecureString -String $SecuredPassword -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecuredPasswordPassword
 
Connect-MgGraph -TenantId $tenantID -ClientSecretCredential $ClientSecretCredential

$AllUsers = Get-MgUser -Property "UserPrincipalName,displayName,id,userType"
$scope = "https%3A%2F%2Fgraph.microsoft.com%2F.default"
$grant_type = "client_credentials"
$AccessTokenRequestBody = "client_id="+$ApplicationId+"&client_secret="+$SecuredPassword+"&scope="+$scope+"&grant_type="+$grant_type
$TokenEndpoint = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"

$AccessTokenRequest = Invoke-RestMethod -Method Post $TokenEndpoint -Body $AccessTokenRequestBody
$AccessToken = $AccessTokenRequest.access_token

Foreach ($UserId in $AllUsers) {
  $uri = "https://graph.microsoft.com/beta/users/"+$userId.Id+"/authentication/signInPreferences"
  $UserMFA = Invoke-RestMethod -Headers @{Authorization = "Bearer $($AccessToken)"} -Uri $uri -Method Get

  $Result = New-Object -TypeName PSObject -Property @{            
    "User" = $userId.UserPrincipalName
    "Uer Preferred MFA" = $UserMFA.userPreferredMethodForSecondaryAuthentication
    "System Preferred MFA" = $UserMFA.systemPreferredAuthenticationMethod
  }
  $Report += $Result
}

$Report | Export-Csv <CSV path> -NoClobber -NoTypeInformation
