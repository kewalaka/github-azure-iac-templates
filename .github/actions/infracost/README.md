# Infracost Action

This action runs [Infracost](https://www.infracost.io/) to generate cost estimates for Terraform infrastructure changes.

## Features

- Generates cost estimates for planned Terraform changes
- Provides baseline cost analysis of current infrastructure
- Outputs formatted cost summary for inclusion in PR comments
- Handles missing plan files gracefully

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `terraform_root_path` | Relative path to root of Terraform code (usually ./iac) | Yes | - |
| `tfvars_file` | Comma separated list of paths to optional tfvars files. Paths are relative to the terraform root path. | No | - |
| `infracost_api_key` | Infracost API key for cost estimation | Yes | - |

## Outputs

| Output | Description |
|--------|-------------|
| `cost_summary` | Formatted cost estimation summary in Markdown format |

## Requirements

- A valid Infracost API key (sign up at https://www.infracost.io/)
- Terraform plan file (tfplan) must exist in the terraform root path
- Terraform configuration compatible with Infracost

## Usage

```yaml
- name: Generate Cost Estimate
  id: infracost
  uses: ./.github/actions/infracost
  with:
    terraform_root_path: './iac'
    tfvars_file: 'dev.tfvars,common.tfvars'
    infracost_api_key: ${{ secrets.INFRACOST_API_KEY }}

- name: Use Cost Summary
  run: |
    echo "${{ steps.infracost.outputs.cost_summary }}"
```

## Notes

- Cost estimates are approximations and may not include all Azure pricing factors
- The action requires network access to communicate with Infracost's pricing API
- Some Terraform resources may not be supported by Infracost