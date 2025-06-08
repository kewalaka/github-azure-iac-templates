# Run Terraform Lint

This action is run just after a terraform init and before the plan and runs tflint to check the code.

## Inputs

| Name                  | Required | Description                  | Default |
| :-------------------- | :------- | :--------------------------- | :------ |
| `root_module_folder_relative_path` | `true`   | Relative path to root of Terraform code (usually `./iac`).  |  |
| `tfvars_file`         | `true`   | Comma-separated list of paths to optional tfvars files. Paths are relative to the `root_module_folder_relative_path`. | |

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script. It also downloads tflint and scans the terraform code.

## repository variable/env variables

This action uses the following environment variable indirectly via the `tfvars_file` input:

| Name          | Description                                    |
| :------------ | :--------------------------------------------- |
| `TF_VAR_FILE` | Defines the variable files passed to `tflint`. |

## Usage

In the calling workflow templates in this repository this action runs the tflint step.  It will run unless `enable_static_analysis_checks` is set to false.

```yaml
- name: Terraform Lint
  id: tflint
  if: ${{ inputs.enable_static_analysis_checks }}
  uses: <org>/<template repository>/.github/actions/tflint
  with:
    root_module_folder_relative_path: ${{ inputs.root_module_folder_relative_path }}
    tfvars_file: ${{ env.TF_VAR_FILE }}
```

## tflint configuration file

TFLint requires configuration file in the root_module_folder_relative_path. called `.tflint.hcl`

Contents:

```text

config {
  format     = "default"
  plugin_dir = "~/.tflint.d/plugins"

  call_module_type    = "all"
  force               = false
  disabled_by_default = false

  ignore_module = {
  }

  # varfile is passed in via CLI since this is only known during pipeline run
}

plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

```
