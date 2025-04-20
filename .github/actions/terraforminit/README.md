# Run Terraform Init

This action is run just before the terraform plan/apply/destroy steps and initialises the backend for terraform steps.

## Inputs

| Name                  | Required | Description                                                      | Default |
| :-------------------- | :------- | :--------------------------------------------------------------- | :------ |
| `terraform_root_path` | `true`   | Relative path to root of Terraform code (usually `./iac`).       |         |

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script.

## repository variable/env variables

This action uses the following environment variables directly in the `terraform init` command:

| Name                       | Description                                    |
| :------------------------- | :--------------------------------------------- |
| `TF_STATE_SUBSCRIPTION_ID` | Subscription ID for the state storage account. |
| `TF_STATE_RESOURCE_GROUP`  | Resource group for the state storage account.  |
| `TF_STATE_BLOB_ACCOUNT`    | Name of the state storage account.             |
| `TF_STATE_BLOB_CONTAINER`  | Container name for the state file.             |
| `TF_BLOB_FILE`             | Name/key of the state file within the container. |

## Usage

In the calling workflow templates in this repository this action runs at the just before the terraform plan/apply/destroy steps. This requires the environment variables are set with the terraform state file information.

```yaml
- name: Terraform Init
  id: init
  uses: <org>/<template repository>/.github/actions/terraforminit@main
  with:
    terraform_root_path: ${{ inputs.terraform_root_path }}
```
