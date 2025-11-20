# backend.ps1
# Purpose: Create an Azure resource group, storage account, and blob container for Terraform state.
# Usage:
#   1. Run `az login` if not already logged in
#   2. Execute with: powershell -ExecutionPolicy Bypass -File .\backend.ps1

# ------------------------------
# Variables
# ------------------------------
$RESOURCE_GROUP_NAME = "rg-terraform-tfstate"
$LOCATION = "westeurope"
$STORAGE_ACCOUNT_NAME = ("sttfstate" + (Get-Random -Minimum 10000 -Maximum 99999)).ToLower()
$CONTAINER_NAME = "tfstate"

# ------------------------------
# Create Resource Group
# ------------------------------
Write-Host "Creating resource group '$RESOURCE_GROUP_NAME' in location '$LOCATION'..." -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# ------------------------------
# Create Storage Account
# ------------------------------
Write-Host "Creating storage account '$STORAGE_ACCOUNT_NAME'..." -ForegroundColor Cyan
az storage account create `
    --name $STORAGE_ACCOUNT_NAME `
    --resource-group $RESOURCE_GROUP_NAME `
    --location $LOCATION `
    --sku Standard_LRS `
    --encryption-services blob

# ------------------------------
# Create Blob Container
# ------------------------------
Write-Host "Creating blob container '$CONTAINER_NAME'..." -ForegroundColor Cyan
az storage container create `
  --name $CONTAINER_NAME `
  --account-name $STORAGE_ACCOUNT_NAME `
  --auth-mode login

# ------------------------------
# Output details
# ------------------------------
Write-Host ""
Write-Host "✅ Terraform backend resources created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Resource Group:     $RESOURCE_GROUP_NAME"
Write-Host "Storage Account:    $STORAGE_ACCOUNT_NAME"
Write-Host "Container:          $CONTAINER_NAME"
Write-Host ""
Write-Host "Use these values later in your backend configuration (backend.tf)."