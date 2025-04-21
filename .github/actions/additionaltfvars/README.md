# Additional TF Vars Action

> [!WARNING]
> This approach should be used sparingly to pass in variables that need to be computed by previous steps,
> most variables should be placed within tfvars or sourced from secrets management

This action will take a comma separated list of key=value string and separate them into variables for use in Terraform Deployments with the pattern `TF_VAR_<key>=<value>`.

These will be set as environment variables for use by the Terraform plan and apply/destroy.

## Inputs

| Name           | Required | Description                                                      | Default |
| :------------- | :------- | :--------------------------------------------------------------- | :------ |
| `tfvar-list`   | `true`   | Comma-separated list of extra variables in the form `key=value`. |         |

## Outputs

none

## Steps and Marketplace Actions

This action uses pwsh shell inline script.

## repository variable/env variables

This action uses the following environment variable via the `tfvar-list` input:

| Name            | Description                                                              |
| :-------------- | :----------------------------------------------------------------------- |
| `EXTRA_TF_VARS` | Comma-separated `key=value` pairs to be set as `TF_VAR_<key>` variables. |

## Usage

In the calling workflow templates in this repository it is expected a variable will be set in the calling repository with the name EXTRA_TF_VARS. If this doesn't exist or is empty then the calling workflow template will skip this action.

```yaml
- name: Set Extra TF_VARS
  id: set-tf-vars
  if: ${{ env.EXTRA_TF_VARS != '' }}
  uses: <org>/<template repository>/.github/actions/additionaltfvars
  with:
    tfvar-list: ${{ env.EXTRA_TF_VARS }}
```
