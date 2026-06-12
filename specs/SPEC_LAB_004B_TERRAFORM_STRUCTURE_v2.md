# SPEC_LAB_004B_TERRAFORM_STRUCTURE
# Version 2.1

> **Changelog v2.1**
> - Se compacta la especificacion para que funcione como contrato tecnico del laboratorio.
> - Se distinguen recursos obligatorios de notas de contexto.
> - Se unifican variables, outputs y tags obligatorios en secciones unicas.
> - Se hace explicita la dependencia entre subnets etiquetadas, NAT Gateway, ECR y `Service` tipo `LoadBalancer`.

---

## Objetivo

Definir la infraestructura minima en Terraform necesaria para ejecutar el laboratorio sobre Amazon EKS.

El objetivo del spec es describir **que debe existir** al terminar el aprovisionamiento, no proponer variantes de arquitectura.

---

## Alcance del Aprovisionamiento

Terraform debe crear como minimo:

- red para EKS
- roles IAM para cluster y nodos
- cluster EKS
- managed node group
- backend remoto de Terraform en S3

Terraform puede organizar estos recursos en archivos o modulos, pero la implementacion final debe producir exactamente las capacidades descritas en este documento.

---

## Providers y Versiones

Se deben pinnear versiones para asegurar reproducibilidad entre alumnos.

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

---

## Recursos Obligatorios

### Networking

Responsabilidad:

Proveer conectividad y discovery correcto para EKS y para el `Service` tipo `LoadBalancer`.

Recursos obligatorios:

- VPC
  - `enable_dns_support = true`
  - `enable_dns_hostnames = true`
- Public Subnets
  - tag `kubernetes.io/role/elb = "1"`
  - tag `kubernetes.io/cluster/<cluster_name> = "shared"`
- Private Subnets
  - tag `kubernetes.io/role/internal-elb = "1"`
  - tag `kubernetes.io/cluster/<cluster_name> = "shared"`
- Internet Gateway
- NAT Gateway en subnet publica
- Route tables publica y privada

### IAM

Responsabilidad:

Permitir que EKS cree y opere el cluster, y que los nodos descarguen imagenes desde Amazon ECR.

Recursos obligatorios:

- Role del cluster EKS
  - trust principal: `eks.amazonaws.com`
  - politica requerida: `AmazonEKSClusterPolicy`
- Role del node group
  - trust principal: `ec2.amazonaws.com`
  - politicas requeridas:
    - `AmazonEKSWorkerNodePolicy`
    - `AmazonEC2ContainerRegistryPullOnly`
    - `AmazonEKS_CNI_Policy`

### EKS

Responsabilidad:

Crear el cluster Kubernetes y los nodos donde se ejecutara `invoice-processor`.

Recursos obligatorios:

- EKS Cluster
- Managed Node Group

Configuracion inicial obligatoria:

- 2 nodos
- tipo `t3.medium`
- capacidad minima `2`
- capacidad maxima `3`

---

## Dependencias Tecnicas Clave

Estas relaciones deben quedar explicitas en la implementacion y en la revision tecnica:

1. Los nodos EKS viven en subnets privadas.
2. Los nodos necesitan salida a internet para hacer pull de imagenes desde Amazon ECR.
3. Esa salida la provee el NAT Gateway.
4. El `Service` de tipo `LoadBalancer` necesita subnets correctamente etiquetadas para que AWS pueda aprovisionar el Load Balancer.
5. Si faltan tags de subnet, el `Service` puede quedar en estado `<pending>`.
6. Si falta salida a internet o permisos ECR, los Pods pueden quedar en `ImagePullBackOff`.

---

## Backend Remoto

Se debe utilizar backend remoto en S3 para mantener estado compartido y consistente.

Ejemplo esperado:

```hcl
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

## Variables Obligatorias

Las variables requeridas por el laboratorio son:

- `aws_region` - region AWS del laboratorio
- `project_name` - nombre base del proyecto
- `environment` - entorno del laboratorio, valor recomendado `dev`
- `cluster_name` - nombre del cluster EKS

Convencion recomendada:

```text
cluster_name = ${project_name}-eks-${environment}
```

---

## Tags Obligatorios

Todos los recursos deben incluir como minimo:

```text
Environment = <var.environment>
Project     = <var.project_name>
ManagedBy   = Terraform
Lab         = LAB-004
```

Tags recomendados adicionales:

```text
Owner       = <responsable>
CostCenter  = <centro-de-costo>
```

---

## Outputs Obligatorios

Los siguientes outputs son obligatorios porque son usados por la guia de ejecucion:

- `cluster_name`
- `cluster_endpoint`
- `cluster_ca_certificate`

Los siguientes outputs son obligatorios por trazabilidad tecnica y continuidad de laboratorios futuros:

- `cluster_security_group`
- `oidc_provider`

---

## Advertencia de Costo

Costo aproximado del laboratorio:

- EKS Cluster: ~$0.10/hora
- 2 x `t3.medium`: ~$0.08/hora
- NAT Gateway: ~$0.045/hora

Costo total estimado:

`~$0.23/hora`

Ejecutar `terraform destroy` al finalizar el laboratorio es obligatorio.
