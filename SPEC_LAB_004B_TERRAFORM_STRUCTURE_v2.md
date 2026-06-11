# SPEC_LAB_004B_TERRAFORM_STRUCTURE
# Versión 2.0

> **Changelog v2.0**
> - HC-03: Se agrega NAT Gateway al módulo Networking (requerido para pull de imágenes desde subnets privadas).
> - HC-03: Se agregan etiquetas obligatorias de subnet para discovery del Load Balancer (`kubernetes.io/role/elb` y `kubernetes.io/role/internal-elb`).
> - HC-03: Se agrega DNS support explícito en la VPC (`enable_dns_support`, `enable_dns_hostnames`).
> - HI-03: Se actualiza la política del Node Group Role de `AmazonEC2ContainerRegistryReadOnly` a `AmazonEC2ContainerRegistryPullOnly`.
> - HI-03: Se agrega `AmazonEKSWorkerNodePolicy` al Node Group Role (requerida, no listada en v1).
> - HI-07: Se mantiene `cluster_name` como variable explícita para claridad pedagógica, con nota de relación recomendada con `project_name`.
> - hm-06: Se especifica contenido del `versions.tf` con providers pinneados.
> - IC-04: Se documenta el propósito del output `oidc_provider` para futura referencia (IRSA).
> - R-10: Se agregan etiquetas de costo recomendadas en los módulos.

---

## Objetivo

Crear la infraestructura mínima necesaria para ejecutar Kubernetes sobre Amazon EKS.

---

# Arquitectura Terraform

```text
terraform/
│
├── backend/
│
├── environments/
│   └── dev/
│
├── modules/
│   ├── eks/
│   ├── iam/
│   └── networking/
│
├── providers.tf
├── variables.tf
├── outputs.tf
└── versions.tf
```

---

# versions.tf

Especificar versiones de providers para garantizar comportamiento reproducible entre alumnos.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}
```

> **Nota pedagógica:** Pinear versiones de providers garantiza que todos los alumnos obtengan el mismo comportamiento durante la ejecución del laboratorio, independientemente de la fecha en que lo realicen.

---

# Módulo Networking

Responsabilidad:

Crear la red requerida por EKS, incluyendo conectividad de salida para los nodos y etiquetas de subnet requeridas para el aprovisionamiento automático de Load Balancers.

Recursos:

- VPC
  - `enable_dns_support = true` (requerido por EKS)
  - `enable_dns_hostnames = true` (requerido por EKS)

- Public Subnets
  - Etiqueta: `kubernetes.io/role/elb = "1"`
  - Etiqueta: `kubernetes.io/cluster/<cluster_name> = "shared"`

- Private Subnets
  - Etiqueta: `kubernetes.io/role/internal-elb = "1"`
  - Etiqueta: `kubernetes.io/cluster/<cluster_name> = "shared"`

- Internet Gateway

- NAT Gateway
  - Desplegado en subnet pública
  - Requerido para que los nodos en subnets privadas puedan hacer pull de imágenes desde Amazon ECR y registros externos

- Route Tables
  - Tabla pública: ruta a Internet Gateway
  - Tabla privada: ruta a NAT Gateway

> **Por qué es necesario el NAT Gateway:** Los nodos del cluster EKS se despliegan en subnets privadas por seguridad. Para que el kubelet en cada nodo pueda descargar imágenes de contenedor desde Amazon ECR (u otros registries), necesita acceso a internet de salida. El NAT Gateway provee esta conectividad sin exponer los nodos directamente a internet.

> **Por qué son necesarias las etiquetas de subnet:** El controlador de Load Balancers de AWS utiliza estas etiquetas para descubrir automáticamente en qué subnets debe crear el Load Balancer. Sin estas etiquetas, el Service de tipo `LoadBalancer` puede quedar en estado `<pending>` indefinidamente.

Outputs:

- `vpc_id`
- `private_subnet_ids`
- `public_subnet_ids`

---

# Módulo IAM

Responsabilidad:

Crear roles necesarios para EKS con políticas actualizadas según las recomendaciones vigentes de AWS (2025).

Recursos:

**EKS Cluster Role**

Políticas requeridas:
- `AmazonEKSClusterPolicy`

Trust principal: `eks.amazonaws.com`

**EKS Node Group Role**

Políticas requeridas:
- `AmazonEKSWorkerNodePolicy` — permite al kubelet describir recursos EC2 en la VPC y unirse al cluster
- `AmazonEC2ContainerRegistryPullOnly` — permite a los nodos hacer pull de imágenes desde Amazon ECR (política de menor privilegio, reemplaza a `AmazonEC2ContainerRegistryReadOnly`)
- `AmazonEKS_CNI_Policy` — requerida por el plugin VPC CNI para gestión de ENIs

Trust principal: `ec2.amazonaws.com`

> **Cambio respecto a v1:** Se reemplaza `AmazonEC2ContainerRegistryReadOnly` por `AmazonEC2ContainerRegistryPullOnly`. La nueva política aplica el principio de menor privilegio, restringiendo el acceso solo a las operaciones de descarga (pull) de imágenes, sin permitir operaciones de listado de repositorios adicionales.

Outputs:

- `cluster_role_arn`
- `node_role_arn`

---

# Módulo EKS

Responsabilidad:

Crear el cluster Kubernetes.

Recursos:

- EKS Cluster

- Managed Node Group

Configuración Inicial:

- 2 nodos
- t3.medium
- Capacidad mínima: 2
- Capacidad máxima: 3

> **Advertencia de costo:** El cluster EKS tiene un costo base de $0.10/hora. Cada instancia t3.medium tiene un costo de ~$0.0416/hora. El costo total aproximado es **$0.19-0.25/hora**. Ejecutar `terraform destroy` al finalizar el laboratorio es obligatorio.

Outputs:

- `cluster_name`
- `cluster_endpoint`
- `cluster_security_group`
- `oidc_provider` — ARN del OIDC Provider del cluster. No se utiliza en este laboratorio pero es el prerequisito para IAM Roles for Service Accounts (IRSA), que permite a los Pods asumir roles IAM. Se exporta como referencia para laboratorios futuros.

---

# Backend Remoto

Utilizar:

- S3 Backend

Objetivo:

Mantener consistencia con laboratorios previos y garantizar que el estado de Terraform sea compartido y consistente.

```hcl
# backend/backend.tf
terraform {
  backend "s3" {
    bucket         = "<nombre-del-bucket-del-curso>"
    key            = "lab-004/terraform.tfstate"
    region         = "<region>"
    encrypt        = true
    dynamodb_table = "<tabla-de-lock>"
  }
}
```

---

# Variables Requeridas

- `aws_region` — Región AWS donde se despliega el laboratorio
- `project_name` — Nombre base del proyecto (p. ej. `invoice-lab`)
- `environment` — Entorno del laboratorio (valor recomendado: `dev`)
- `cluster_name` — Nombre del cluster EKS (p. ej. `invoice-eks-dev`)

> **Nota de diseño:** Se recomienda que `cluster_name` siga la convención `${project_name}-eks-${environment}` para mantener consistencia y facilitar la identificación de recursos en la consola AWS.

Etiquetas recomendadas (aplicar en todos los recursos):

```text
Environment = <valor de var.environment>
Project     = <valor de var.project_name>
ManagedBy   = Terraform
Lab         = LAB-004
```

---

# Outputs Principales

- `cluster_name` — Nombre del cluster, necesario para el comando `aws eks update-kubeconfig`
- `cluster_endpoint` — Endpoint de la API de Kubernetes
- `cluster_ca_certificate` — Certificado CA del cluster

Estos outputs serán utilizados posteriormente para configurar kubectl.
