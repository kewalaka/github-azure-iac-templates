<#
    .SYNOPSIS
    Changes the default action of Key Vault and Storage Accounts from Azure DevOps pipeline

    .DESCRIPTION
    Changes the default action of Key Vault and Storage Accounts to enable terraform access to resources from Azure DevOps agents

    .PARAMETER operation
    Specifies the default action and public endpoint. Valid values are Allow,Deny

    .PARAMETER tfstateSubscriptionID
    Specifies the subscription id for the terraform state storage account.
    Can be left empty if the tfstateStorageAccountName is in the same subscription as the current service connection for
    the Azure DevOps pipeline

    .PARAMETER tfstateStorageAccountName
    Specifies the terraform storage account name

    .PARAMETER tfstateResourceGroupName
    Specifies the terraform storage account resource group

    .PARAMETER extraFirewallUnlocks
    Specifies a list of resources in json syntax to unlock. Can be in separate subscriptions

    Json fields required are
    - public - true/false
    - subscriptionID
    - resourceGroupName
    - name
    - type - valid values are keyvault or storageaccount

    The access is determined by the operation desired by the main parameter and the public setting for the extra unlocks:

      if Public is true then on Allow this will be set to Enabled
      If Public is false then on Deny this will be set to Disabled and on Allow this will be set to Enabled

      -  Allow    - Default action Allow, Public to Enabled (Enabled from all networks)
      -  Deny     - Default action Deny,  Public to Enabled (Enabled from selected virtual networks and IP addresses)

      - Enabled  - Default action Allow, Public to Enabled  (Enabled from all networks)
      - Disabled - Default action Deny,  Public to Disabled (Disabled)

    Json list of objects [{<object 1},{object 2}]

    [{"public":"true","subscriptionID" : "<subscription guid>", "resourceGroupName": "<resource group name>", "name": "<kv resource name>", "type" : "keyvault"}
    ,{"public":"false","subscriptionID" : "<subscription guid>", "resourceGroupName": "<resource group name>", "name": "<sa resource name>", "type" : "storageaccount"}]

    .EXAMPLE
    ##ADO Pipeline

    variables:
      operation: "Allow"
      azureSubscription: "<ado service connection>"
      tfstateSubscriptionID: "<subscription guid>"
      tfstateStorageAccountName: "<tfstate sa resource name>"
      tfstateResourceGroupName: "<tfstate resource group name>"
      extraFirewallUnlocks: >-
    [{"public":"true",
    "subscriptionID" : "<subscription guid>",
    "resourceGroupName": "<resource group name>",
    "name": "<kv resource name>",
    "type" : "keyvault"}
    ,{"public":"false",
    "subscriptionID" : "280574c4-955c-4869-b1b5-0126321a46b9",
    "resourceGroupName": "<resource group name>",
    "name": "<sa resource name>",
    "type" : "storageaccount"}]

    ...
    ...
    ...

    steps:
    - task: AzurePowerShell@5
      displayName: Modify rules to ${{ variables.operation }} network access
      inputs:
        ConnectedServiceNameARM: ${{ variables.azureSubscription }}
        scriptType: "filePath"
        scriptPath: $(System.DefaultWorkingDirectory)/pipelines/resourceunlock/Update-IPDefaultAction.ps1
        scriptArguments: |
          -operation ${{ variables.operation }} `
          -tfstateSubscriptionID ${{ coalesce( variables.tfstateSubscriptionID, '""' ) }} `
          -tfstateStorageAccountName ${{ variables.tfstateStorageAccountName }} `
          -tfstateResourceGroupName ${{ variables.tfstateResourceGroupName }} `
          -extraFirewallUnlocks '${{ variables.extraFirewallUnlocks }}'
        azurePowerShellVersion: LatestVersion

#>
[CmdletBinding()]
param (
  [parameter (Mandatory= $true)]
  [string]$operation,

  [string]$tfstateSubscriptionID = "",

  [parameter (Mandatory= $true)]
  [string]$tfstateStorageAccountName,

  [parameter (Mandatory= $true)]
  [string]$tfstateResourceGroupName,

  [string]$extraFirewallUnlocks = "[]"
)

$resList = ConvertFrom-Json $extraFirewallUnlocks

$update_all = $false

Write-Host "Current working directory is: '$($pwd.Path)'"

$context = Get-AzContext

Write-Host "Start Subscription is set to: '$($context.Subscription.Name)', id: '$($context.Subscription.Id)'"

$tfstateSub = $tfstateSubscriptionID
$currentSub = $context.Subscription.Id

## TF State Sub not supplied so assume in same sub
if ($tfstateSub -eq "")
{
  Write-Host "Subscription for tfstate not supplied. Setting to current sub: '$($context.Subscription.Name)', id: '$currentSub'"
  $tfstateSub = $currentSub
}

Write-Host "Subscription for tfstate: '$tfstateSub'"
$tfcontext = Set-AzContext -Subscription $tfstateSub
Write-Host "Subscription is set to: '$($tfcontext.Subscription.Name)', id: '$($tfcontext.Subscription.Id)'"
Write-Host "Setting default action to '$operation' on tfstate storage account '$tfstateStorageAccountName' in resource group '$tfstateResourceGroupName'."
Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $tfstateResourceGroupName -Name $tfstateStorageAccountName -DefaultAction $operation
# this is used to track the last storage account firewall that has been modified for the test at the end of this script.
$latestStorageAccountName = $tfstateStorageAccountName

## Extra resources supplied
if ($null -ne $resList)
{
  Write-Host "---------------------------"
  Write-Host "Processing extra resources"
  foreach ( $res in $resList ) {
    $rescontext = Set-AzContext -Subscription $res.subscriptionID
    Write-Host "-----------------------------------------------------------------------------------"
    Write-Host "Subscription is set to: '$($rescontext.Subscription.Name)', id: '$($rescontext.Subscription.Id)'"
    Write-Host "Processing resource : '$($res.resourceGroupName)/$($res.name)'"

    if (($operation -eq "Deny") -and ($res.public -eq "false"))
    {
      $publicAction = "Disabled"
    }
    else
    {
      $publicAction = "Enabled"
    }

    if (($res.Type -eq "storageaccount" ) -and ($res.name -ne $tfstateStorageAccountName)) {

      Write-Host "Setting default action to '$operation' and public to '$publicAction' on storage account: '$($res.name)'"
      $resultDefault = Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $res.resourceGroupName -Name $res.name -DefaultAction $operation
      $resultPublic  = Set-AzStorageAccount -ResourceGroupName $res.resourceGroupName -Name $res.name -PublicNetworkAccess $publicAction
      Write-Host "Updated default action to '$($resultDefault.DefaultAction)' and public to '$($resultPublic.PublicNetworkAccess)' on storage account: '$($res.name)'"
      $latestStorageAccountName = $res.name
    }

    if ($res.Type -eq "keyvault") {
      Write-Host "Setting default action to '$operation' and public to '$publicAction' on key vault: '$($res.name)'"
      Update-AzKeyVaultNetworkRuleSet -ResourceGroupName $res.resourceGroupName -VaultName $res.name -DefaultAction $operation -WarningAction SilentlyContinue
      $resultPublic  = Update-AzKeyVault -ResourceGroupName $res.resourceGroupName -VaultName $res.name -PublicNetworkAccess $publicAction
      Write-Host "Updated default action to '$($resultPublic.NetworkAcls.DefaultAction)' and public to '$($resultPublic.PublicNetworkAccess)' on key vault: '$($res.name)'"
    }
  }
  Write-Host "-----------------------------------------------------------------------------------"
}

# test the last of the storage accounts added to make sure the firewall is likely to be ready.
if ($operation -eq "Allow") {
  Write-Host "Waiting for firewall rules to apply"
  $sac = New-AzStorageContext -UseConnectedAccount -StorageAccountName $latestStorageAccountName
  Write-Host "Testing with storage account: $latestStorageAccountName"
  $firewallNotReady = $true
  $attempts = 0
  while ( $firewallNotReady -and $attempts -lt 10) {
    try {
      Start-Sleep -Seconds 5
      $container = Get-AzStorageContainer -context $sac -ErrorAction Stop | Select-Object -First 1
      Get-AzStorageContainerAcl -Context $sac -Container $container.name -ErrorAction Stop | Out-Null
      # success
      $firewallNotReady = $false
    }
    catch {
      Write-Host "...still waiting."
      $attempts += 1
    }

  }
  If ($firewallNotReady) {
    Write-Error "Firewall is still not ready after 10 attempts checking $latestStorageAccountName."
  }
  else {
    Write-Host "Firewall is allegedly ready to accept connections, pausing for 10 more seconds to improve reliability."
    Start-Sleep -Seconds 10
  }
}