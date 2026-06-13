# LAB-004 — Kubernetes sobre Amazon EKS

Laboratorio educativo: despliegue de una API FastAPI (`invoice-processor`) en un
cluster Amazon EKS provisionado con Terraform, y validación end-to-end del
flujo (deploy, self-healing, escalamiento, rolling update).

Especificaciones completas: [specs/SPEC_LAB_004A_KUBERNETES_USE_CASE_v2.md](specs/SPEC_LAB_004A_KUBERNETES_USE_CASE_v2.md)
a [specs/SPEC_LAB_004E_CLAUDE_CODE_PROMPTS_v2.md](specs/SPEC_LAB_004E_CLAUDE_CODE_PROMPTS_v2.md).
Guía de ejecución paso a paso: [specs/SPEC_LAB_004D_LAB_EXECUTION_GUIDE_v2.md](specs/SPEC_LAB_004D_LAB_EXECUTION_GUIDE_v2.md).

## Estructura del repositorio

```
infra/      Terraform — VPC, IAM, cluster EKS (módulos: network, iam, eks)
app/        Código fuente de invoice-processor (FastAPI)
k8s/        Manifiestos Kubernetes (deployment.yaml, service.yaml)
tests/aws/  Scripts de validación post-despliegue (PowerShell + bash)
specs/      Especificaciones del laboratorio
```

## Prerequisitos

- AWS CLI configurado contra la cuenta del curso
- Terraform `>= 1.5.0`
- `kubectl`
- Docker
- Acceso a un registry ECR

## Flujo del laboratorio

### 1. Infraestructura (Terraform)

```bash
cd infra
terraform init
terraform plan
terraform apply
```

El backend es **local** por defecto (estado en `infra/terraform.tfstate`).
Para usar un backend remoto S3, copiar `infra/backend.tf.example` a
`infra/backend.tf` y completar el bucket. Configurar variables en
`infra/terraform.tfvars` (ver `infra/terraform.tfvars.example`).

Validación mínima:

```bash
terraform output cluster_name
terraform output cluster_endpoint
```

### 2. Configurar kubectl

```bash
aws eks update-kubeconfig --region <aws_region> --name <cluster_name>
kubectl get nodes
```

Los nodos deben aparecer en estado `Ready` (esperar 2-3 min si están
`NotReady`).

### 3. Publicar la imagen en Amazon ECR

```bash
aws ecr create-repository --repository-name invoice-processor --region <aws_region>

aws ecr get-login-password --region <aws_region> | \
  docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com

docker build -t invoice-processor:v1 app/
docker tag invoice-processor:v1 <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
docker push <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
```

### 4. Revisar manifiestos Kubernetes

Antes de aplicar, editar [k8s/deployment.yaml](k8s/deployment.yaml) y
reemplazar `<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1`
con el URI real de ECR. Checklist:

- nombre de la app: `invoice-processor`, namespace `default`
- imagen apunta al URI completo de ECR (tag `v1`)
- `containerPort` / `targetPort` = `8000`, `port` del Service = `80`
- Service tipo `LoadBalancer`
- réplicas iniciales: `2`

### 5. Deploy en Kubernetes

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 6. Validación

Scripts en [tests/aws/](tests/aws/) (leen identificadores vía
`terraform output`, sin valores hardcodeados):

```powershell
# Precheck — recursos, IAM y tags
.\tests\aws\precheck\smoke_resources.ps1
.\tests\aws\precheck\validate_iam.ps1
.\tests\aws\precheck\validate_tags.ps1

# Smoke — conectividad del cluster y la app
.\tests\aws\smoke\smoke_cloudwatch.ps1
.\tests\aws\smoke\smoke_eks.ps1

# Logs — exportar outputs y logs del control plane
.\tests\aws\logs\export_pipeline_outputs.ps1
.\tests\aws\logs\download_cloudwatch_logs.ps1
```

Equivalente bash/CI: `bash tests/aws/gitbash/precheck.sh`.

Verificación manual adicional:

```bash
kubectl get deployments,pods,services -n default -l app=invoice-processor
```

- Deployment `READY 2/2`, 2 Pods `Running`, Service `LoadBalancer`
- `EXTERNAL-IP` puede tardar 2-5 min en asignarse (Classic Load Balancer)

### 7. Consumo de la API

```bash
curl http://<EXTERNAL-IP>
```

Respuesta esperada:

```json
{
  "service": "invoice-processor",
  "version": "1.0",
  "status": "healthy"
}
```

### 8. Self-healing

```bash
kubectl get pods
kubectl delete pod <POD_NAME>
kubectl get pods
```

Un nuevo Pod debe reemplazar automáticamente al eliminado.

### 9. Escalamiento

Cambiar `replicas: 2` a `replicas: 5` en `k8s/deployment.yaml`, luego:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl get pods
```

### 10. Rolling update (v1 → v2)

Build, tag y push de `invoice-processor:v2` (con `version: "2.0"` en la app),
actualizar la imagen en `k8s/deployment.yaml` y:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment invoice-processor
curl http://<EXTERNAL-IP>
```

## Cleanup (obligatorio)

```bash
kubectl delete -f k8s/service.yaml
kubectl delete -f k8s/deployment.yaml

cd infra
terraform destroy
```

Eliminar primero los recursos de Kubernetes evita dejar un Load Balancer
huérfano en AWS antes de destruir la infraestructura.

## Criterio de éxito

1. Imagen publicada en ECR
2. Aplicación desplegada en EKS
3. API consumida externamente vía Load Balancer
4. Self-healing observado
5. Escalamiento a 5 Pods
6. Rolling update visible de `v1` a `v2`
7. Infraestructura destruida ordenadamente
