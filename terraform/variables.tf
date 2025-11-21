variable "location" { default = "westeurope" }
variable "prefix" { default = "devops-lab" }
variable "admin_username" { default = "azureuser" }
variable "ssh_public_key" {
  description = "Tu clave pública local (cat ~/.ssh/id_rsa.pub)"
  type        = string
}