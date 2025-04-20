# Run Terraform Apply

This action is run just after a terraform init and performs the actions in the tfplan file.

## Inputs

| Name                  | Required | Description                                                      | Default |
| :-------------------- | :------- | :--------------------------------------------------------------- | :------ |
| `terraform_root_path` | `true`   | Relative path to root of Terraform code (usually `./iac`).       |         |
| `destroyResources`    | `true`   | Set to `true` if applying a destroy plan.                        |         |

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script.

## repository variable/env variables

none

## Usage

In the calling workflow templates in this repository this action runs at the just after the terraform init in the apply job. This requires the download artifact step to supply the iac folder and tfplan file from the plan job.

```yaml
- name: "Terraform Apply${{ inputs.destroyResources && ' Destroy' || '' }}"
  id: apply
  uses: <org>/<template repository>/.github/actions/terraformapply@main
  with:
    terraform_root_path: ${{ inputs.terraform_root_path }}
    destroyResources: ${{ inputs.destroyResources }}
```
