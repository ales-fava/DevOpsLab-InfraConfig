# 🏗️ Infraestructura y Automatización DevOps - Lab Azure/K8s

Este repositorio aloja la definición de Infraestructura como Código (IaC) y la configuración de Gestión de Configuración para un entorno completo de DevOps. El proyecto despliega un clúster de Kubernetes ligero sobre una Máquina Virtual en Azure, orquestado automáticamente mediante GitHub Actions.

## ☁️ 1. Recursos Desplegados con Terraform (Azure)

Se utiliza Terraform para el provisionamiento de la infraestructura inmutable en Microsoft Azure. El estado (tfstate) se almacena remotamente en un Azure Storage Account.

Los recursos desplegados son:

- **Resource Group**: Contenedor lógico para todos los recursos del entorno (`devops-lab-rg`).
- **Virtual Network (VNet) & Subnet**: Red virtual (`10.0.0.0/16`) y subred interna (`10.0.1.0/24`) para alojar la computación.
- **Network Security Group (NSG)**: Firewall de capa 4 que controla el tráfico.
  - **Reglas de Entrada**: SSH (22), NodePorts de K8s (30000-32767).
- **Public IP Address**: Dirección IP estática con SKU Standard (requerido para zonas de disponibilidad y seguridad moderna).
- **Network Interface (NIC)**: Interfaz de red asociada a la VM y al NSG.
- **Virtual Machine (Linux)**:
  - **SKU**: `Standard_D2s_v3` (2 vCPU, 8GB RAM).
  - **OS**: Ubuntu Server 22.04 LTS.
  - **Feature**: Soporte para Nested Virtualization (necesario para correr Docker/K8s dentro de la VM).
- **Azure Key Vault**: Almacenamiento seguro de secretos y claves (preparado para integración futura).
- **Azure App Configuration**: Servicio para gestión centralizada de configuraciones y Feature Flags.

## ⚙️ 2. Recursos Configurados con Ansible

Una vez provisionada la infraestructura, Ansible se conecta vía SSH para configurar el software y las herramientas dentro de la VM.

### Herramientas Instaladas y Propósito

| Herramienta | Rol / Propósito |
|---|---|
| Docker CE | Runtime de Contenedores. Motor base para ejecutar los contenedores de Kubernetes. (Sustituye a Podman por compatibilidad con Minikube). |
| Minikube | Orquestación K8s. Clúster de Kubernetes de un solo nodo. Se inicia con el driver docker y recursos dedicados (6GB RAM / 2 CPU). |
| Kubectl | CLI. Herramienta de línea de comandos para interactuar con el clúster de Kubernetes. |
| Helm | Gestor de Paquetes. Utilizado para instalar charts complejos como el stack de monitorización. |
| ArgoCD | GitOps / Despliegue. Controlador de entrega continua instalado en el clúster. Sincroniza el estado de Git con K8s. |
| Prometheus | Monitorización. Sistema de recolección de métricas y alertas del clúster (CPU, Memoria, Estado de Pods). |
| Grafana | Visualización. Dashboards interactivos para visualizar las métricas recolectadas por Prometheus. |

## 📂 3. Estructura del Proyecto

```plaintext
infra-repo/
├── .github/
│   └── workflows/      # Pipelines de CI/CD (infra-deploy.yml)
├── terraform/          # Definición de IaC
│   ├── main.tf         # Recursos principales de Azure
│   ├── variables.tf    # Definición de variables
│   ├── providers.tf    # Configuración del backend remoto
│   └── outputs.tf      # Salidas (ej. IP Pública para Ansible)
├── ansible/            # Gestión de Configuración
│   ├── playbook.yml    # Tareas de instalación y configuración
│   └── inventory       # Plantilla de inventario (sobreescrita por CI)
└── helm/               # Charts de Kubernetes
    └── mywebapp/       # Chart personalizado para la App Angular
        ├── values.yaml # Configuración de la App (Imagen, Feature Flags)
        └── templates/  # Manifiestos (Deployment, Service, ConfigMap)
```

## 💻 4. Requisitos Previos (Pruebas en Local)

Para ejecutar este proyecto desde tu máquina local, necesitas:
- **Azure CLI:** Instalado y autenticado (`az login`).
- **Terraform:** v1.7.0+
- **Ansible:** v2.10+
- **Par de Claves SSH:** Generadas localmente (`ssh-keygen -f devops_lab_key`).
- **Service Principal de Azure:** Con permisos de Contributor sobre la suscripción.

### Configuración de Secretos
Si deseas replicar el pipeline, configura los siguientes secretos en GitHub o variables de entorno locales:
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `SSH_PUBLIC_KEY` (Contenido de .pub)
- `SSH_PRIVATE_KEY` (Contenido de la llave privada)

---

## 🚀 5. CI/CD con GitHub Actions

El despliegue de la infraestructura es totalmente automático y se define en `.github/workflows/infra-deploy.yml`.

**Flujo del Pipeline:**
1. **Trigger:** Push a la rama main (filtrando cambios en carpetas `terraform/` o `ansible/`).
2. **Job Terraform:**
   - Inicializa el backend remoto.
   - Ejecuta `terraform plan` y `terraform apply`.
   - Output: Extrae la IP Pública de la nueva VM y la pasa al siguiente job.
3. **Job Ansible:**
   - Recibe la IP del job anterior.
   - Genera un archivo de inventario dinámico.
   - Se conecta por SSH usando la clave privada almacenada en Secrets.
   - Ejecuta el playbook para instalar K8s, ArgoCD y Monitorización.

---

## 🔗 6. Repositorios Relacionados

Este proyecto funciona en conjunto con el repositorio de la aplicación:
- [Repositorio de la App Angular](https://github.com/ales-fava/DevOpsLab-MyWebApp): Contiene el código fuente, Dockerfile y pipeline de CI que actualiza la versión en este repositorio de infraestructura.

---

## ⚠️ 7. Notas Importantes y Accesos

### Accesos a Servicios (Tras despliegue)

| Servicio  | URL                              | Credenciales                                    |
|-----------|-----------------------------------|-------------------------------------------------|
| ArgoCD    | https://<IP_VM>:30443            | User: admin / Pass: (Ver secret argocd-initial-admin-secret) |
| Grafana   | http://<IP_VM>:31000             | User: admin / Pass: (Ver secret monitoring-grafana) |
| Web App   | http://<IP_VM>:30080             | N/A (Público)                                   |

#### Recuperación tras Reinicio de VM
Minikube no arranca automáticamente si la VM de Azure se detiene. Pasos de recuperación:
1. Entrar por SSH: `ssh -i key azureuser@<IP>`
2. Iniciar clúster: `minikube start`
3. Exponer servicios (Port-Forwarding manual para saltar limitación Docker Driver):
   ```bash
   kubectl port-forward svc/mywebapp 30080:80 --address 0.0.0.0 &
   kubectl port-forward svc/argocd-server -n argocd 30443:443 --address 0.0.0.0 &

## 🔮 8. Mejoras Futuras

- **Migración a AKS:** Sustituir la VM con Minikube por un clúster gestionado Azure Kubernetes Service (AKS) para producción real.
- **External Secrets:** Implementar External Secrets Operator para sincronizar secretos desde Azure Key Vault en lugar de usar variables de entorno.
- **Persistencia:** Configurar un servicio systemd para que Minikube arranque automáticamente al reiniciar la VM.
- **SSL/TLS:** Implementar Cert-Manager y LetsEncrypt para tener HTTPS válido en la aplicación web en lugar de HTTP.