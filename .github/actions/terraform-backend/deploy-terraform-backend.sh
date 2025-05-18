#!/bin/bash
set -euo pipefail

RESOURCE_GROUP_NAME="$1"
STORAGE_ACCOUNT_NAME="$2"
STATE_CONTAINER_NAME="$3"
ARTIFACT_CONTAINER_NAME="$4"

STORAGE_SKU="Standard_LRS"
TAGS="Purpose=Terraform Backend"
RETENTION_DAYS=7

echo "🔍 Checking environment setup..."

if [[ -z "${ARM_CLIENT_ID:-}" ]]; then
  echo "❌ ARM_CLIENT_ID environment variable must be set."
  exit 1
fi

DEPLOY_PRINCIPAL_ID=$(az ad sp show --id "$ARM_CLIENT_ID" --query id -o tsv 2>/dev/null || true)
if [[ -z "$DEPLOY_PRINCIPAL_ID" ]]; then
  echo "❌ Could not find Service Principal with Application ID '$ARM_CLIENT_ID'."
  exit 1
fi
echo "✅ Found Principal ID: $DEPLOY_PRINCIPAL_ID"

# Check if the resource group exists (required for everything else)
LOCATION=$(az group show --name "$RESOURCE_GROUP_NAME" --query location -o tsv 2>/dev/null || true)
if [[ -z "$LOCATION" ]]; then
  echo "❌ Resource Group '$RESOURCE_GROUP_NAME' does not exist."
  exit 1
fi

function ensure_container_and_rbac() {
  local container_name="$1"
  local container_scope="/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Storage/storageAccounts/${STORAGE_ACCOUNT_NAME}/blobServices/default/containers/${container_name}"

  echo "🔍 Checking RBAC on: $container_scope"

  ASSIGNED=$(az role assignment list \
    --assignee "$DEPLOY_PRINCIPAL_ID" \
    --scope "$container_scope" \
    --role "Storage Blob Data Contributor" \
    --query "[].id" -o tsv 2>/dev/null || true)

  if [[ -n "$ASSIGNED" ]]; then
    echo "✅ RBAC already assigned for container '$container_name'"
    return 0
  fi

  echo "⚠️ RBAC not assigned — checking if container '$container_name' exists..."

  # Get storage account key for access
  ACCOUNT_KEY=$(az storage account keys list \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "[0].value" -o tsv 2>/dev/null || true)

  if [[ -z "$ACCOUNT_KEY" ]]; then
    echo "⚠️ Storage account or keys not found — triggering full creation flow."
    create_storage_account_and_containers
    return 0
  fi

  EXISTS=$(az storage container exists \
    --name "$container_name" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$ACCOUNT_KEY" \
    --query exists -o tsv)

  if [[ "$EXISTS" == "true" ]]; then
    echo "✅ Container '$container_name' exists — assigning RBAC"
  else
    echo "🚫 Container '$container_name' not found — creating full backend"
    create_storage_account_and_containers
    return 0
  fi

  echo "🔒 Assigning 'Storage Blob Data Contributor' on '$container_scope'"
  az role assignment create \
    --assignee "$DEPLOY_PRINCIPAL_ID" \
    --role "Storage Blob Data Contributor" \
    --scope "$container_scope" \
    --only-show-errors || echo "ℹ️ Role may already be assigned (race condition)."
}

function create_storage_account_and_containers() {
  echo "🔧 Creating Storage Account '$STORAGE_ACCOUNT_NAME' in '$LOCATION'"
  az storage account create \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --sku "$STORAGE_SKU" \
    --kind StorageV2 \
    --access-tier Hot \
    --allow-blob-public-access false \
    --https-only true \
    --min-tls-version TLS1_2 \
    --tags $TAGS \
    --allow-shared-key-access true \
    --output none

  ACCOUNT_ID=$(az storage account show \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query id -o tsv)
  ACCOUNT_KEY=$(az storage account keys list \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "[0].value" -o tsv)

  echo "📦 Creating containers: '$STATE_CONTAINER_NAME' and '$ARTIFACT_CONTAINER_NAME'"
  for container in "$STATE_CONTAINER_NAME" "$ARTIFACT_CONTAINER_NAME"; do
    az storage container create \
      --name "$container" \
      --account-name "$STORAGE_ACCOUNT_NAME" \
      --account-key "$ACCOUNT_KEY" \
      --output none
  done

  echo "📜 Configuring blob versioning and retention"
  az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --enable-versioning true \
    --delete-retention-days "$RETENTION_DAYS" \
    --output none

  echo "🔒 Disabling shared key access post-setup"
  az storage account update \
    --name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --allow-shared-key-access false \
    --output none

  echo "🔁 Recursively re-running RBAC check for each container..."
  ensure_container_and_rbac "$STATE_CONTAINER_NAME"
  ensure_container_and_rbac "$ARTIFACT_CONTAINER_NAME"
}

# Start by checking RBAC for both containers
ensure_container_and_rbac "$STATE_CONTAINER_NAME"
ensure_container_and_rbac "$ARTIFACT_CONTAINER_NAME"

echo "✅ Backend storage and RBAC verified."
