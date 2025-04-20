# Run Checkov Terraform Scan

This action scans the terraform plan output for security issues with resource creation.

## Inputs

terraform_root_path

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script.

Marketplace actions:

- bridgecrewio/checkov-action

## repository variable/env variables

none

## Usage

In the calling workflow templates in this repository this action runs at the just after the terraform plan. It will only run if bypassChecks is set to false.

```yaml
- name: Terraform Scan
  id: tfcheckov
  if: ${{ !inputs.bypassChecks }}
  uses: <org>/<template repository>/.github/actions/runcheckov@main
  with:
    terraform_root_path: ${{ inputs.terraform_root_path }}
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
