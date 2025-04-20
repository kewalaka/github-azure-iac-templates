# Create Artifact Action

This action is run after a terraform plan and creates the build artifact to be used by the terraform apply/destroy. It is the uploaded to the terraform state storage account in the artifacts container using azure cli. The file will be `<github.run_id>.zip`.

## Inputs

terraform_root_path
TF_SUBSCRIPTION_ID
TF_STATE_BLOB_ACCOUNT
ARTIFACT_BLOB_CONTAINER

## Outputs

none

## Steps and Marketplace Actions

This action uses pwsh shell inline script.

Marketplace actions:
- azure/login
- azure/cli

## repository variable/env variables

TF_SUBSCRIPTION_ID
TF_STATE_BLOB_ACCOUNT
ARTIFACT_BLOB_CONTAINER

## Usage

In the calling workflow templates in this repository this action runs when there is an apply/destroy job required. It is skipped if there is only a terraform plan. This is determined by the deploy template expression. `uploadArtifact: ${{ contains(fromJSON('["destroy", "apply"]'), inputs.terraform_action) }}`. The inputs are similar to those used in other terraform calls apart from the ARTIFACT_BLOB_CONTAINER which should be set in the calling repository.

```yaml
- name: "Upload Artifact"
  id: upload
  if: ${{ inputs.uploadArtifact }}
  uses: <org>/<template repository>/.github/actions/createartifact@main
  with:
    terraform_root_path: ${{ inputs.terraform_root_path }}
    TF_SUBSCRIPTION_ID: ${{ env.TF_SUBSCRIPTION_ID }}
    TF_STATE_BLOB_ACCOUNT: ${{ env.TF_STATE_BLOB_ACCOUNT }}
    ARTIFACT_BLOB_CONTAINER: ${{ env.ARTIFACT_BLOB_CONTAINER }}
```
