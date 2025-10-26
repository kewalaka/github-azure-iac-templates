# Run Terraform Plan

This action runs `terraform plan` after `terraform init`. It generates a plan file (`tfplan`) and uses `tfplandoc` to generate a human-readable summary of the plan changes, which is output to the action logs.

Optionally, if triggered by a `pull_request` event and provided with a suitable GitHub token, it will post this plan summary as a comment on the Pull Request.

## Inputs

| Name                  | Required | Description                                                                                                | Default   |
| :-------------------- | :------- | :--------------------------------------------------------------------------------------------------------- | :-------- |
| `root_iac_folder_relative_path` | `true`   | Relative path to the root of the Terraform code (usually `./infra`).                                         |           |
| `tfvars_file`         | `true`   | Comma-separated list of paths to optional tfvars files. Paths are relative to the `root_iac_folder_relative_path`. |           |
| `destroy_resources`    | `false`  | Set to `true` to generate a destroy plan instead of a standard plan.                                       | `'false'` |
| `github_token`        | `false`  | GitHub token (`secrets.GITHUB_TOKEN`) used for posting plan summaries to Pull Requests. Required for PR commenting. | `''`      |

## Outputs

None. (The plan summary is printed to logs and optionally posted as a PR comment).

## Optional PR Commenting

* If this action is run as part of a workflow triggered by a `pull_request` event, **and** a valid `github_token` is provided as input, the action will attempt to post the `tfplandoc` summary as a comment on the associated Pull Request.
* The comment includes a link back to the GitHub Actions run for viewing the full plan output.
* **Permission Requirement:** For PR commenting to succeed, the workflow *calling* this action must have the `permissions: pull-requests: write` permission granted.

## Steps and Marketplace Actions

* Uses bash shell inline script for Terraform commands.
* Downloads and installs `tfplandoc` from the [Azure/tfplandoc](https://github.com/Azure/tfplandoc) repository.
* Uses `actions/github-script` to interact with the GitHub API for posting PR comments (if conditions are met).

## Repository Variable/Env Variables

This action uses the following environment variable indirectly via the `tfvars_file` input:

| Name          | Description                                    |
| :------------ | :--------------------------------------------- |
| `TF_VAR_FILE` | Defines the variable files passed to the plan. |

## Usage

In the calling workflow templates in this repository, this action runs the `terraform plan` step.

```yaml
# Example within a calling workflow (e.g., terraform-deploy-template.yml)

- name: "Terraform Plan${{ inputs.destroy_resources && ' Destroy' || '' }}"
  id: plan
  uses: <org>/<template repository>/.github/actions/terraform-plan # Adjust path/version
  with:
    root_iac_folder_relative_path: ${{ inputs.root_iac_folder_relative_path }}
    destroy_resources: ${{ inputs.destroy_resources }}
    tfvars_file: ${{ env.TF_VAR_FILE }}
    # Pass the token to enable PR commenting when applicable
    github_token: ${{ secrets.GITHUB_TOKEN }}

# Note: The workflow triggering the above template needs 'permissions: pull-requests: write'
# if it runs on a pull_request event and commenting is desired.
```
