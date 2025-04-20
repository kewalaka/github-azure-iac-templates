# Login to AKS for Kubernetes terraform

This action is used to login to AKS for kubernetes terraform provider or k8s manifest deployment.

## Inputs

subscription_id
resource_group
cluster_name

## Outputs

none

## Steps and Marketplace Actions

This action uses bash shell inline script.

Marketplace actions:

- azure/use-kubelogin
- azure/login
- azure/aks-set-context

## repository variable/env variables

ARM_CLIENT_ID
ARM_TENANT_ID

## Usage

In the calling workflow templates in this repository this action must run before the terraform init on plan or apply.

```yaml
- name: "Login to AKS"
  id: login-aks
  uses: <org>/<template repository>/.github/actions/loginaks@main
  with:
    subscription_id: ${{ env.AKS_SUBSCRIPTION_ID }}
    resource_group: ${{ env.AKS_RESOURCE_GROUP }}
    cluster_name: ${{ env.AKS_CLUSTER_NAME }}
```
