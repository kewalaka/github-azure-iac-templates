# Run Terraform Lint

This action is run just after a terraform init and before the plan and runs tflint to check the code.

## Inputs

terraform_root_path
tfvars_file

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script. It also downloads tflint and scans the terraform code.

## repository variable/env variables

TF_VAR_FILE

## Usage

In the calling workflow templates in this repository this action runs the tflint step.  It will only run if bypassChecks is set to false.

```yaml
- name: Terraform Lint
  id: tflint
  if: ${{ !inputs.bypassChecks }}
  uses: <org>/<template repository>/.github/actions/tflint@main
  with:
    terraform_root_path: ${{ inputs.terraform_root_path }}
    tfvars_file: ${{ env.TF_VAR_FILE }}
```

## tflint configuration file

TFLint requires configuration file in the terraform_root_path. called `.tflint.hcl`

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
