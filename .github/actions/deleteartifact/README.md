# Delete Artifact Action

This action is run after a terraform apply and deletes the build artifact used by the terraform apply/destroy. It is the deleted to the terraform state storage account in the artifacts container using azure cli. The file will be `<github.run_id>.zip`.

## Inputs

| Name                       | Required | Description                                     | Default      |
| :------------------------- | :------- | :---------------------------------------------- | :----------- |
| `TF_STATE_SUBSCRIPTION_ID` | `true`   | Specifies the subscription ID for the Terraform state storage account. | |
| `TF_STATE_BLOB_ACCOUNT`    | `true`   | Specifies the Terraform storage account name.   |  |
| `ARTIFACT_BLOB_CONTAINER`  | `false`  | Specifies the container name where the artifact resides. | `tfartifact` |

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script.

Marketplace actions:

- azure/login
- azure/cli

## repository variable/env variables

This action relies on the following environment variables being set in the calling workflow's job for Azure authentication:

| Name                  | Description                         |
| :-------------------- | :---------------------------------- |
| `ARM_CLIENT_ID`       | Client ID of the deploying identity. |
| `ARM_TENANT_ID`       | Tenant ID for Azure authentication. |

The following are used indirectly via inputs:

| Name                       | Description                                                    |
| :------------------------- | :------------------------------------------------------------- |
| `TF_STATE_SUBSCRIPTION_ID` | Subscription ID for the Terraform state storage account.       |
| `TF_STATE_BLOB_ACCOUNT`    | Terraform storage account name.                                |
| `ARTIFACT_BLOB_CONTAINER`  | Container name where the artifact resides.                     |

## Usage

In the calling workflow templates in this repository this action runs when an apply/destroy job has run. The inputs are similar to those used in other terraform calls apart from the ARTIFACT_BLOB_CONTAINER which should be set in the calling repository.

```yaml
- name: Delete Artifact
  id: delete
  if: ${{ always() }}
  uses: <org>/<template repository>/.github/actions/deleteartifact
  with:
    TF_STATE_SUBSCRIPTION_ID: ${{ env.TF_STATE_SUBSCRIPTION_ID }}
    TF_STATE_BLOB_ACCOUNT: ${{ env.TF_STATE_BLOB_ACCOUNT }}
    ARTIFACT_BLOB_CONTAINER: ${{ env.ARTIFACT_BLOB_CONTAINER }}
```
