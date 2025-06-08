# Run Checkov Terraform Scan

This action scans the terraform plan output for security issues with resource creation.

## Inputs

| Name                                   | Required | Description                                                                                      | Default         |
| :-------------------------------------- | :------- | :----------------------------------------------------------------------------------------------- | :-------------- |
| `root_module_folder_relative_path`      | `true`   | Relative path to root of Terraform code (usually `./iac`).                                       |                 |
| `tfvars_file`                          | `false`  | Comma separated list of paths to optional tfvars files. Paths are relative to the terraform root. | `""`            |
| `checkov_environment_variables`         | `false`  | JSON object of additional environment variables to export before running Checkov.                 | `{}`            |

## Additional parameters syntax

Additional parameters should be formatted as a JSON object. Each key/value will be exported as an environment variable before Checkov runs. This allows you to pass any supported Checkov environment variable or custom variable.

```json
{ "LOG_LEVEL": "WARNING", "IGNORED_DIRECTORIES": ".terraform", "CHECKOV_SKIP_CHECK": "CKV_AWS_20,CKV_AWS_57" }
```

For a list of supported environment variables, check the [Checkov code](https://github.com/bridgecrewio/checkov/blob/main/checkov/common/util/env_vars_config.py).

## Example usage

```yaml
- name: Terraform security scan with Checkov
  id: tfcheckov
  uses: <org>/<template repository>/.github/actions/checkov-terraform
  with:
    root_module_folder_relative_path: ${{ inputs.root_module_folder_relative_path }}
    tfvars_file: ${{ inputs.tfvars_file }}
    checkov_environment_variables: |
      {
        "LOG_LEVEL": "DEBUG",
        "CHECKOV_SKIP_CHECK": "CKV_AWS_20,CKV_AWS_57"
      }
```

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script.

Marketplace actions:

- bridgecrewio/checkov-action

## repository variable/env variables

none

## Usage

In the calling workflow templates in this repository this action runs at the just after the terraform plan. It will only run if `enable_checkov` is set to true.

```yaml
- name: Terraform security scan with Checkov
  id: tfcheckov
  if: ${{ inputs.enable_checkov }}
  uses: <org>/<template repository>/.github/actions/checkov-terraform
  with:
    root_module_folder_relative_path: ${{ inputs.root_module_folder_relative_path }}
```

## Suppress errors

If Checkov errors are found and need suppressing there are two ways to do this. If the error shows a line and file in the local terraform code and not the tfplan file then a comment inline will suppress that error.

The format of this is the skip rule and a suppression message. `#checkov:skip=<rule name>:<message>`

```HCL
  zone_redundancy_enabled       = false
  #checkov:skip=CKV_AZURE_233:Zone redundacy not required

  data_endpoint_enabled    = false
  #checkov:skip=CKV_AZURE_237:Data endpoint not required

  enable_trust_policy = true
  #checkov:skip=CKV_AZURE_164:Trust policy not required
```

Otherwise create a `.checkov.yml` file at the root level of the repository (not the iac folder)

```text
Check: CKV_SECRET_6: "Base64 High Entropy String"
 FAILED for resource: ba74cf8e3b29d889a051eb720a87c8962fb4b315
Error:  File: /iac/tfplan.json:442-443
```

```yml
skip-check:
  - CKV_SECRET_6
```
