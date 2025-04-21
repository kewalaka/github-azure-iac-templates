# Login to Azure Kubernetes Services (AKS)

This action is used to login to AKS for kubernetes terraform provider or k8s manifest deployment.

## Inputs

| Name              | Required | Description                                    | Default |
| :---------------- | :------- | :--------------------------------------------- | :------ |
| `subscription_id` | `true`   | Specifies the subscription ID for the AKS cluster. |  |
| `resource_group`  | `true`   | Specifies the resource group for the AKS cluster. |  |
| `cluster_name`    | `true`   | Specifies the Name for the AKS cluster.        |  |

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script.

Marketplace actions:

- azure/use-kubelogin
- azure/login
- azure/aks-set-context

## repository variable/env variables

This action relies on the following environment variables being set in the calling workflow's job for Azure authentication:

| Name            | Description                          |
| :-------------- | :----------------------------------- |
| `ARM_CLIENT_ID` | Client ID of the deploying identity. |
| `ARM_TENANT_ID` | Tenant ID for Azure authentication.  |

## Usage

In the calling workflow templates in this repository this action must run before the terraform init on plan or apply.

```yaml
- name: "Login to AKS"
  id: login-aks
  uses: <org>/<template repository>/.github/actions/loginaks
  with:
    subscription_id: ${{ env.AKS_SUBSCRIPTION_ID }}
    resource_group: ${{ env.AKS_RESOURCE_GROUP }}
    cluster_name: ${{ env.AKS_CLUSTER_NAME }}
```
