# Unlock resource firewalls during CI

> [!WARNING]
> Using either self-hosted or managed runners is preferred to this mechanism.  This is a hacky workaround!

This action temporarily modifies Azure resource firewall rules to grant access during deployment, and then closes the firewall afterwards.

This allows the usage of the GitHub public runners out of the box whilst keeping certain resources secure
(out of the box, it supports the Terraform storage account, other storage accounts and keyvaults can be unlocked using the `EXTRA_FIREWALL_UNLOCKS` parameter).

To use with the `terraform-deploy-template.yml` workflow, simply add `unlock_resource_firewall` option, and make sure the deployment principal has rights to unlock the firewall (e.g. Storage Contributor)

```yaml
jobs:
  call-terraform-deploy:
    name: "Run terraform ${{ inputs.terraform_action }} for ${{ inputs.target_environment }}"
    uses: kewalaka/github-azure-iac-templates/.github/workflows/terraform-deploy-template.yml@main
    with:
      terraform_action: ${{ inputs.terraform_action }}
      environment_name_plan: "${{ inputs.target_environment }}-iac-plan"
      environment_name_apply: "${{ inputs.target_environment }}-iac-apply"
      tfvars_file: "./environments/${{ inputs.target_environment }}.terraform.tfvars"
      destroy_resources: ${{ inputs.destroy_resources == true || inputs.terraform_action == 'destroy' }}
      unlock_resource_firewalls: true # Add this (and don't forget to grant RBAC permissions as noted above)!
    secrets: inherit
```

The action will run before and after the terraform init/plan/apply/destroy steps.

For more complex options, or to use this action directly, see the notes below.  Full details of each parameter can be found in the powershell script [Set-ResourceFirewallAction.ps1](Set-ResourceFirewallAction.ps1).

## Inputs

| Name                       | Required | Description           | Default |
| :------------------------- | :------- | --------------------- | :------ |
| `OPERATION`                | `true`   | Specifies the default action and public endpoint. Valid values are `Allow` or `Deny`.  |         |
| `TF_STATE_SUBSCRIPTION_ID` | `true`   | Specifies the subscription ID for the Terraform state storage account.  | |
| `TF_STATE_RESOURCE_GROUP`  | `true`   | Specifies the resource group name for the Terraform state storage account. |  |
| `TF_STATE_STORAGE_ACCOUNT_NAME`    | `true`   | Specifies the name of the Terraform state storage account. |  |
| `EXTRA_FIREWALL_UNLOCKS`   | `false`  | Specifies a JSON string defining additional resources (Key Vaults, Storage Accounts) to unlock. Can be in separate subscriptions. See script. | `''`  |

## Outputs

none

## Steps and Marketplace Actions

Marketplace actions:

- azure/login
- azure/powershell

## repository variable/env variables

| Name                       | Description  |
| :------------------------- | :----------- |
| `ARM_CLIENT_ID`            | Client ID of the identity performing the firewall update. |
| `ARM_TENANT_ID`            | Tenant ID for Azure authentication.   |
| `ARM_SUBSCRIPTION_ID`      | Default Azure subscription ID (used for login, though specific resources use `TF_STATE_SUBSCRIPTION_ID` or IDs within `EXTRA_FIREWALL_UNLOCKS`). |
| `TF_STATE_SUBSCRIPTION_ID` | (Used indirectly via input) Subscription ID for the Terraform state storage account. |
| `TF_STATE_RESOURCE_GROUP`  | (Used indirectly via input) Resource group name for the Terraform state storage account. |
| `TF_STATE_STORAGE_ACCOUNT_NAME`    | (Used indirectly via input) Name of the Terraform state storage account.|
| `EXTRA_FIREWALL_UNLOCKS`   | (Used indirectly via input) JSON string defining additional resources to unlock. |

## Usage

In the calling workflow templates in this repository this action runs at the start and end of an plan/apply/destroy job. The inputs are similar to those used in other terraform calls apart from the EXTRA_FIREWALL_UNLOCKS which should be set in the calling repository. The extra quote marks around the EXTRA_FIREWALL_UNLOCKS is required as this is a json object that causes issues with yaml parsing.

```yaml
- name: Unlock Resource Firewalls
  if: ${{ inputs.unlock_resource_firewalls }}
  uses: <org>/<template repository>/.github/actions/azure-unlock-firewall
  with:
    OPERATION: "Allow"
    TF_STATE_SUBSCRIPTION_ID: ${{ env.TF_STATE_SUBSCRIPTION_ID  }}
    TF_STATE_RESOURCE_GROUP_NAME: ${{ env.TF_STATE_RESOURCE_GROUP_NAME }}
    TF_STATE_STORAGE_ACCOUNT_NAME: ${{ env.TF_STATE_STORAGE_ACCOUNT_NAME }}
    EXTRA_FIREWALL_UNLOCKS: "${{ env.EXTRA_FIREWALL_UNLOCKS }}"

- name: Lock Resource Firewalls
  if: ${{ always() && inputs.unlock_resource_firewalls }}
  uses: <org>/<template repository>/.github/actions/azure-unlock-firewall
  with:
    OPERATION: "Deny"
    TF_STATE_SUBSCRIPTION_ID: ${{ env.TF_STATE_SUBSCRIPTION_ID  }}
    TF_STATE_RESOURCE_GROUP_NAME: ${{ env.TF_STATE_RESOURCE_GROUP_NAME }}
    TF_STATE_STORAGE_ACCOUNT_NAME: ${{ env.TF_STATE_STORAGE_ACCOUNT_NAME }}
    EXTRA_FIREWALL_UNLOCKS: "${{ env.EXTRA_FIREWALL_UNLOCKS }}"
```
