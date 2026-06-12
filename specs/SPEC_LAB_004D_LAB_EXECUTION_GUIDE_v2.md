# SPEC_LAB_004D_LAB_EXECUTION_GUIDE
# Version 2.1

> **Changelog v2.1**
> - Se hace mas consistente el flujo operativo de extremo a extremo.
> - Se refuerzan las validaciones humanas previas a `kubectl apply`.
> - Se eliminan supuestos no documentados entre Terraform, ECR y los manifests.
> - Se compactan notas de tiempos, estados transitorios y cleanup.

---

## Objetivo

Guiar al alumno paso a paso en el despliegue y validacion del laboratorio de Kubernetes sobre Amazon EKS.

---

## Flujo del Laboratorio

El flujo obligatorio es:

1. Prerequisitos y variables
2. Terraform apply
3. Configuracion de `kubectl`
4. Publicacion de imagen en Amazon ECR
5. Generacion y revision de YAML
6. Deploy en Kubernetes
7. Verificacion
8. Consumo de API
9. Self-healing
10. Escalamiento
11. Rolling update
12. Cleanup

---

## Estimacion de Tiempo

| Paso | Actividad | Tiempo estimado |
|---|---|---|
| 0 | Prerequisitos y costo | 2 min |
| 1 | Infraestructura EKS | 15-20 min |
| 2 | Kubeconfig | 5 min |
| 3 | ECR | 10 min |
| 4 | YAML con Claude Code | 15 min |
| 5 | Deploy | 5 min |
| 6 | Verificacion | 5 min |
| 7 | Consumo de API | 5 min |
| 8 | Self-healing | 5 min |
| 9 | Escalamiento | 5 min |
| 10 | Rolling update | 10 min |
| 11 | Cleanup | 10 min |
| **Total** | | **~3 horas** |

---

## Paso 0 - Prerequisitos y Costo

Prerequisitos:

- AWS CLI configurado
- Terraform `>= 1.5.0`
- `kubectl` instalado
- Docker instalado
- acceso a la cuenta AWS del curso

Variables a configurar:

```bash
export TF_VAR_aws_region="us-east-1"
export TF_VAR_project_name="invoice-lab"
export TF_VAR_environment="dev"
export TF_VAR_cluster_name="invoice-eks-dev"
```

Costo estimado:

- EKS Cluster: ~$0.10/hora
- 2 x `t3.medium`: ~$0.08/hora
- NAT Gateway: ~$0.045/hora
- Total: `~$0.23/hora`

`terraform destroy` es obligatorio al finalizar el laboratorio.

---

## Paso 1 - Aprovisionamiento de Infraestructura

Objetivo:

Crear el cluster EKS y sus dependencias.

Comandos:

```bash
terraform init
terraform plan
terraform apply
```

Validaciones minimas despues del apply:

```bash
terraform output cluster_name
terraform output cluster_endpoint
```

Resultado esperado:

- cluster EKS creado
- node group creado
- outputs disponibles

---

## Paso 2 - Configuracion de kubectl

Objetivo:

Conectar el entorno local con el cluster.

Comando:

```bash
aws eks update-kubeconfig \
  --region $TF_VAR_aws_region \
  --name $TF_VAR_cluster_name
```

Validacion:

```bash
kubectl get nodes
```

Resultado esperado:

Nodos en estado `Ready`.

Si aparecen como `NotReady`, esperar 2 a 3 minutos y volver a consultar.

Todos los recursos del laboratorio usan el namespace `default`.

---

## Paso 3 - Publicacion de Imagen en Amazon ECR

Objetivo:

Publicar la imagen `invoice-processor:v1` en un registry accesible por los nodos EKS.

### 3.1 Crear el repositorio

```bash
aws ecr create-repository \
  --repository-name invoice-processor \
  --region $TF_VAR_aws_region
```

Registrar el `repositoryUri`.

### 3.2 Autenticar Docker

```bash
aws ecr get-login-password --region $TF_VAR_aws_region | \
  docker login --username AWS --password-stdin \
  <account_id>.dkr.ecr.<region>.amazonaws.com
```

### 3.3 Build local

```bash
docker build -t invoice-processor:v1 .
```

### 3.4 Tag hacia ECR

```bash
docker tag invoice-processor:v1 \
  <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
```

### 3.5 Push

```bash
docker push \
  <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
```

Validacion humana:

- la imagen existe en ECR
- el tag es `v1`
- el URI completo sera el mismo usado en `deployment.yaml`

---

## Paso 4 - Generacion y Revision de YAML

Archivos esperados:

- `deployment.yaml`
- `service.yaml`

Prompts a utilizar:

- Prompt 1: genera `deployment.yaml`
- Prompt 2: explica `deployment.yaml`
- Prompt 3: genera `service.yaml`
- Prompt 4: explica `service.yaml`

Checklist obligatorio antes de `kubectl apply`:

- el nombre de la aplicacion es `invoice-processor`
- el namespace es `default`
- la imagen apunta al URI completo de ECR
- el puerto del contenedor es `8000`
- `imagePullPolicy: IfNotPresent` esta presente
- los labels del Deployment coinciden con el selector del Service
- el Service es `LoadBalancer`
- `targetPort` es `8000`
- `port` es `80`
- replicas iniciales: `2`

---

## Paso 5 - Despliegue de Recursos

Comandos:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

Resultado esperado:

```text
deployment.apps/invoice-processor created
service/invoice-processor-service created
```

---

## Paso 6 - Verificacion

Comandos:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

Resultados esperados:

- Deployment con `READY 2/2`
- 2 Pods en `Running`
- Service `LoadBalancer`

Notas importantes:

- `EXTERNAL-IP` puede aparecer como `<pending>` durante 2 a 5 minutos
- en este escenario EKS crea un **Classic Load Balancer**

---

## Paso 7 - Consumo de la API

Obtener el `EXTERNAL-IP` o hostname del Service:

```bash
kubectl get services
```

Consumir la API:

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

---

## Paso 8 - Self-Healing

Eliminar un Pod:

```bash
kubectl get pods
kubectl delete pod <POD_NAME>
kubectl get pods
```

Resultado esperado:

Un nuevo Pod reemplaza automaticamente al Pod eliminado.

Concepto clave:

El ReplicaSet, administrado por el Deployment, detecta la disminucion de replicas y recrea el Pod faltante.

---

## Paso 9 - Escalamiento

Modificar en `deployment.yaml`:

```yaml
replicas: 2
```

por:

```yaml
replicas: 5
```

Aplicar:

```bash
kubectl apply -f deployment.yaml
```

Validar:

```bash
kubectl get pods
```

Resultado esperado:

5 Pods en ejecucion.

---

## Paso 10 - Rolling Update

### 10.1 Preparar imagen v2

Cambiar el valor visible de `version` de `"1.0"` a `"2.0"` en la aplicacion.

Build:

```bash
docker build -t invoice-processor:v2 .
```

Tag:

```bash
docker tag invoice-processor:v2 \
  <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v2
```

Push:

```bash
docker push \
  <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v2
```

### 10.2 Actualizar el Deployment

Cambiar la imagen en `deployment.yaml` de `v1` a `v2`.

Aplicar:

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment invoice-processor
```

### 10.3 Verificar

```bash
curl http://<EXTERNAL-IP>
```

Respuesta esperada:

```json
{
  "service": "invoice-processor",
  "version": "2.0",
  "status": "healthy"
}
```

---

## Paso 11 - Cleanup

### 11.1 Eliminar recursos Kubernetes

```bash
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
```

Esto evita dejar un Load Balancer huerfano en AWS.

### 11.2 Destruir infraestructura Terraform

```bash
terraform destroy
```

Resultado esperado:

```text
Destroy complete! Resources: XX destroyed.
```

---

## Criterio de Exito

El alumno habra completado exitosamente el laboratorio si logra:

1. publicar la imagen en ECR
2. desplegar la aplicacion en EKS
3. consumir la API externamente
4. observar self-healing
5. escalar a 5 Pods
6. ejecutar un rolling update visible de `v1` a `v2`
7. destruir ordenadamente la infraestructura
