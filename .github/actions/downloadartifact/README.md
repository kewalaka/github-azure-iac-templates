# Download Artifact Action

This action is run before a terraform apply and downloads the build artifact to be used by the terraform apply/destroy. It is the downloaded from the terraform state storage account in the artifacts container using azure cli. The file will be `<github.run_id>.zip`.

## Inputs

TF_STATE_SUBSCRIPTION_ID
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

TF_STATE_SUBSCRIPTION_ID
TF_STATE_BLOB_ACCOUNT
ARTIFACT_BLOB_CONTAINER

## Usage

In the calling workflow templates in this repository this action runs at the start of an apply/destroy job. The inputs are similar to those used in other terraform calls apart from the ARTIFACT_BLOB_CONTAINER which should be set in the calling repository.

```yaml
- name: Download Artifact
  id: download
  uses: <org>/<template repository>/.github/actions/downloadartifact@main
  with:
    TF_STATE_SUBSCRIPTION_ID: ${{ env.TF_STATE_SUBSCRIPTION_ID }}
    TF_STATE_BLOB_ACCOUNT: ${{ env.TF_STATE_BLOB_ACCOUNT }}
    ARTIFACT_BLOB_CONTAINER: ${{ env.ARTIFACT_BLOB_CONTAINER }}
```
