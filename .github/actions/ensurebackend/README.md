# Ensure Terraform Backend Action

This composite action checks for the existence of the required Azure Storage Account and containers for Terraform state and plan artifacts within a pre-existing Resource Group. If they don't exist, it creates them with secure defaults and grants the necessary RBAC permissions (`Storage Blob Data Contributor`) on the containers to the identity running the workflow.

## Prerequisites

* The target Azure Resource Group must already exist.
* The identity running the workflow (specified by `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `TF_STATE_SUBSCRIPTION_ID` environment variables) must have permissions to:
  * Read the target Resource Group (`Microsoft.Resources/subscriptions/resourcegroups/read`).
  * Read its own Service Principal details (`Microsoft.Graph/servicePrincipals/read.all` or similar directory read permission).
  * Create, Read, and Write Storage Accounts within the target Resource Group (`Microsoft.Storage/storageAccounts/...`).
  * Assign Roles at the container scope (e.g., `Microsoft.Authorization/roleAssignments/write` scoped to the RG or subscription, or the `User Access Administrator` role).

## Inputs

| Name                    | Required | Description                                                                          | Default      |
| :---------------------- | :------- | :----------------------------------------------------------------------------------- | :----------- |
| `resource_group_name`   | `true`   | Name of the **existing** Resource Group for the backend.                             |              |
| `storage_account_name`  | `true`   | Name of the Storage Account for the backend (max 24 chars, lowercase alphanumeric). |              |
| `state_container_name`  | `true`   | Name of the container for Terraform state.                                           | `tfstate`    |
| `artifact_container_name` | `true`   | Name of the container for Terraform plan artifacts.                                  | `tfartifact` |

## Environment Variables Used

This action relies on the following environment variables being set in the calling workflow's job (typically sourced from GitHub Environment variables):

* `ARM_CLIENT_ID`: Client ID of the identity performing the check/creation.
* `ARM_TENANT_ID`: Tenant ID for Azure authentication.
* `TF_STATE_SUBSCRIPTION_ID`: Subscription ID where the backend resources reside.

## Example Usage

```yaml
jobs:
  plan:
    # ... other job settings ...
    env:
      ARM_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
      ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
      TF_STATE_SUBSCRIPTION_ID: ${{ vars.TF_STATE_SUBSCRIPTION_ID || vars.AZURE_SUBSCRIPTION_ID }}
      TF_STATE_RESOURCE_GROUP: ${{ vars.TF_STATE_RESOURCE_GROUP }}
      TF_STATE_BLOB_ACCOUNT: ${{ vars.TF_STATE_BLOB_ACCOUNT }}
      TF_STATE_BLOB_CONTAINER: ${{ vars.TF_STATE_BLOB_CONTAINER || 'tfstate' }}
      ARTIFACT_BLOB_CONTAINER: ${{ vars.ARTIFACT_BLOB_CONTAINER || 'tfartifact' }}
      # ... other env vars ...

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Ensure Terraform Backend Storage and RBAC
        # Use relative path if in the same repo
        uses: ./.github/actions/ensure-backend
        # Or full path if calling from another repo
        # uses: your-org/your-repo/.github/actions/ensure-backend@v1.0
        with:
          resource_group_name: ${{ env.TF_STATE_RESOURCE_GROUP }}
          storage_account_name: ${{ env.TF_STATE_BLOB_ACCOUNT }}
          state_container_name: ${{ env.TF_STATE_BLOB_CONTAINER }}
          artifact_container_name: ${{ env.ARTIFACT_BLOB_CONTAINER }}

      # ... subsequent steps (Terraform Init, Plan, etc.) ...
```
