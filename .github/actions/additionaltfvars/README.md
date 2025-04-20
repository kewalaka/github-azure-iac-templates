# Additional TF Vars Action

This action will take a comma separated list of key=value string and separate them into variables for use in Terraform Deployments with the pattern
`TF_VAR_<key>=<value>`. These will be set as environment variables for use by the Terraform plan and apply/destroy.

## Inputs

tfvar-list

## Outputs

none

## Steps and Marketplace Actions

This action uses pwsh shell inline script.

## repository variable/env variables

EXTRA_TF_VARS

## Usage

In the calling workflow templates in this repository it is expected a variable will be set in the calling repository with the name EXTRA_TF_VARS. If this doesn't exist or is empty then the calling workflow template will skip this action.

```yaml
- name: Set Extra TF_VARS
  id: set-tf-vars
  if: ${{ env.EXTRA_TF_VARS != '' }}
  uses: <org>/<template repository>/.github/actions/additionaltfvars@main
  with:
    tfvar-list: ${{ env.EXTRA_TF_VARS }}
```