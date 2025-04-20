# IP Default Action

This action is run before and after the terraform init/plan/apply/destroy steps. This is required when using public runners to execute the terraform steps to allow access to the terraform state storage account and any key vaults and storage accounts specified in the EXTRA_FIREWALL_UNLOCKS. Full details of each parameter can be found in the powershell script `Update-IPDefaultAction.ps1`.

## Inputs

OPERATION
TF_SUBSCRIPTION_ID
TF_STATE_RESOURCE_GROUP
TF_STATE_BLOB_ACCOUNT
EXTRA_FIREWALL_UNLOCKS

## Outputs

none

## Steps and Marketplace Actions

Marketplace actions:
- azure/login
- azure/powershell

## repository variable/env variables

TF_SUBSCRIPTION_ID
TF_STATE_RESOURCE_GROUP
TF_STATE_BLOB_ACCOUNT
EXTRA_FIREWALL_UNLOCKS

## Usage

In the calling workflow templates in this repository this action runs at the start and end of an plan/apply/destroy job. The inputs are similar to those used in other terraform calls apart from the EXTRA_FIREWALL_UNLOCKS which should be set in the calling repository. The extra quote marks around the EXTRA_FIREWALL_UNLOCKS is required as this is a json object that causes issues with yaml parsing.

```yaml
- name: Unlock Resource Firewalls
  if: ${{ inputs.requireStorageAccountFirewallAction }}
  uses: <org>/<template repository>/.github/actions/ipdefault@main
  with:
    OPERATION: "Allow"
    TF_SUBSCRIPTION_ID: ${{ env.TF_SUBSCRIPTION_ID  }}
    TF_STATE_RESOURCE_GROUP: ${{ env.TF_STATE_RESOURCE_GROUP }}
    TF_STATE_BLOB_ACCOUNT: ${{ env.TF_STATE_BLOB_ACCOUNT }}
    EXTRA_FIREWALL_UNLOCKS: "${{ env.EXTRA_FIREWALL_UNLOCKS }}"

- name: Lock Resource Firewalls
  if: ${{ always() && inputs.requireStorageAccountFirewallAction }}
  uses: <org>/<template repository>/.github/actions/ipdefault@main
  with:
    OPERATION: "Deny"
    TF_SUBSCRIPTION_ID: ${{ env.TF_SUBSCRIPTION_ID  }}
    TF_STATE_RESOURCE_GROUP: ${{ env.TF_STATE_RESOURCE_GROUP }}
    TF_STATE_BLOB_ACCOUNT: ${{ env.TF_STATE_BLOB_ACCOUNT }}
    EXTRA_FIREWALL_UNLOCKS: "${{ env.EXTRA_FIREWALL_UNLOCKS }}"
```
