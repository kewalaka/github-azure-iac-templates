# Run Terraform Plan

This action is run just after a terraform init and runs the terraform plan step.

## Inputs

terraform_root_path
tfvars_file
destroyResources

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script. It also downloads tfplandoc and generates a visual representation of the terraform plan.

## repository variable/env variables

TF_VAR_FILE

## Usage

In the calling workflow templates in this repository this action runs the terraform plan step.

```yaml
- name: "Terraform Plan${{ inputs.destroyResources && ' Destroy' || '' }}"
  id: plan
  uses: <org>/<template repository>/.github/actions/terraformplan@main
  with:
    terraform_root_path: ${{ inputs.terraform_root_path }}
    destroyResources: ${{ inputs.destroyResources }}
    tfvars_file: ${{ env.TF_VAR_FILE }}
```
