# Terraform Init Action

This composite action initializes Terraform with optional backend configuration.

## Features

- Supports both backend and non-backend initialization
- Centralizes Terraform init logic across workflows
- Reduces code duplication

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `root_iac_folder_relative_path` | Relative path to root of Terraform code | No | `./infra` |
| `backend_config` | Whether to configure backend (true) or use -backend=false (false) | No | `true` |
| `tf_state_subscription_id` | Azure subscription ID for Terraform state storage | No | `''` |
| `tf_state_resource_group_name` | Resource group name containing the Terraform state storage account | No | `''` |
| `tf_state_storage_account_name` | Storage account name for Terraform state | No | `''` |
| `tf_state_storage_container_name` | Container name for Terraform state | No | `tfstate` |
| `tf_state_storage_container_key` | Key (file name) for Terraform state | No | `terraform.tfstate` |

## Usage

### With Backend Configuration

```yaml
- name: Terraform Init
  uses: kewalaka/github-azure-iac-templates/.github/actions/terraform-init@main
  with:
    root_iac_folder_relative_path: './infra'
    backend_config: 'true'
    tf_state_subscription_id: ${{ env.TF_STATE_SUBSCRIPTION_ID }}
    tf_state_resource_group_name: ${{ env.TF_STATE_RESOURCE_GROUP_NAME }}
    tf_state_storage_account_name: ${{ env.TF_STATE_STORAGE_ACCOUNT_NAME }}
    tf_state_storage_container_name: ${{ env.TF_STATE_STORAGE_CONTAINER_NAME }}
    tf_state_storage_container_key: ${{ env.TF_STATE_STORAGE_CONTAINER_KEY }}
```

### Without Backend (for validation/linting)

```yaml
- name: Terraform Init
  uses: kewalaka/github-azure-iac-templates/.github/actions/terraform-init@main
  with:
    root_iac_folder_relative_path: './infra'
    backend_config: 'false'
```

## Notes

- When `backend_config` is `false`, Terraform initializes without a backend, useful for validation and linting
- When `backend_config` is `true`, all backend configuration inputs should be provided
