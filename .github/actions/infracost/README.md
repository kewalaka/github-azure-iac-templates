# Infracost Action

This action runs [Infracost](https://www.infracost.io/) to generate cost estimates for Terraform infrastructure changes.

When enabled, cost estimates are automatically included in the plan summary posted to pull requests.

## Setting up Infracost

1. **Sign up for Infracost:** Create a free account at [infracost.io](https://www.infracost.io/) to get your API key.
1. **Add the API key:** Add `INFRACOST_API_KEY` as a **Secret** in your repository or environment settings.
1. **Enable in workflow:** Set `enable_infracost: true` in your workflow file (see example above).

## Features

- **Cost Diff:** Shows the monthly cost difference between current and planned infrastructure
- **PR Integration:** Cost estimates are automatically posted to pull request comments alongside the plan summary
- **Optional:** The feature is disabled by default and must be explicitly enabled

## Limitations

- Requires network access to Infracost's pricing API
- Cost estimates are approximations and may not include all Azure pricing factors
- Some Terraform resources may not be supported by Infracost

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `terraform_root_path` | Relative path to root of Terraform code (usually ./infra) | Yes | - |
| `tfvars_file` | Comma separated list of paths to optional tfvars files. Paths are relative to the terraform root path. | No | - |
| `infracost_api_key` | Infracost API key for cost estimation | Yes | - |
| `github_token` | Authenticate for posting to PR comments | No | - |

## Outputs

| Output | Description |
|--------|-------------|
| `cost_summary` | Formatted cost estimation summary in Markdown format |

## Requirements

- A valid Infracost API key (sign up at <https://www.infracost.io/>)
- Terraform plan file (tfplan) must exist in the terraform root path
- Terraform configuration compatible with Infracost

## Usage

```yaml
- name: Generate Cost Estimate
  id: infracost
  uses: ./.github/actions/infracost
  with:
    terraform_root_path: './infra'
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
