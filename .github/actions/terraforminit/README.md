# Run Terraform Init

This action is run just before the terraform plan/apply/destroy steps and initialises the backend for terraform steps.

## Inputs

terraform_root_path

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script.

## repository variable/env variables

TF_SUBSCRIPTION_ID
TF_STATE_RESOURCE_GROUP
TF_STATE_BLOB_ACCOUNT
TF_STATE_BLOB_CONTAINER
TF_BLOB_FILE

## Usage

In the calling workflow templates in this repository this action runs at the just before the terraform plan/apply/destroy steps. This requires the environment variables are set with the terraform state file information.

```yaml
- name: Terraform Init
  id: init
  uses: <org>/<template repository>/.github/actions/terraforminit@main
  with:
    terraform_root_path: ${{ inputs.terraform_root_path }}
```
