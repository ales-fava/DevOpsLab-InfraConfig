# This block defines the required providers and their versions.
terraform {
  required_providers {
    # Specify Azure Resource Manager provider
    azurerm = {
      # Use the official HashiCorp azurerm provider
      source = "hashicorp/azurerm"
      # Specify a version range for the provider
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-tfstate"
    storage_account_name = "sttfstate58286"
    container_name       = "tfstate"
    key                  = "devops-lab.tfstate"
  }
}

# This block configures the Azure Resource Manager provider.
provider "azurerm" {
  # Leave the features block empty as we don't use any specific features in this example.
  features {}
}