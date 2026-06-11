# SPEC_LAB_004D_LAB_EXECUTION_GUIDE
# Versión 2.0

> **Changelog v2.0**
> - HC-01: Se agrega Paso 3 "Publicación de imagen en Amazon ECR" (bloqueante en v1, ahora resuelto).
> - HC-02 / HC-04: Se agrega advertencia de costo y tiempo estimado por paso.
> - HC-02: Se documenta que el Service `LoadBalancer` crea un Classic Load Balancer (CLB) en EKS sin AWS LBC.
> - HC-04: Se ajusta el tiempo total estimado a ~3 horas. Se recomienda al instructor pre-crear el cluster.
> - HI-04: Se completa el Paso 9 (Rolling Update) con build y push de imagen v2.
> - hm-03: Se agrega nota sobre estado `NotReady` al ejecutar `kubectl get nodes` inmediatamente después del apply.
> - hm-07: Se explicita el namespace `default` en los primeros pasos.
> - IC-03: Se aclara qué prompts de 004E generan artefactos vs cuáles son de comprensión.
> - IC-07: Se agrega paso de verificación de variables antes del `terraform apply`.
> - Se agrega Paso 10: Cleanup obligatorio (`terraform destroy`).

---

## Objetivo

Guiar al alumno paso a paso a través del despliegue de una aplicación en Kubernetes utilizando Amazon EKS.

---

# Estimación de Tiempo Total

| Paso | Actividad | Tiempo estimado |
|---|---|---|
| 0 | Advertencia de costo y prerequisitos | 2 min |
| 1 | Aprovisionamiento de infraestructura | 15-20 min |
| 2 | Configuración de kubectl | 5 min |
| 3 | Publicación de imagen en ECR | 10 min |
| 4 | Generación de YAML con Claude Code | 15 min |
| 5 | Despliegue de recursos | 5 min |
| 6 | Verificación | 5 min |
| 7 | Consumo de la API | 5 min |
| 8 | Self-Healing | 5 min |
| 9 | Escalamiento | 5 min |
| 10 | Rolling Update | 10 min |
| 11 | Cleanup obligatorio | 10 min |
| **Total** | | **~3 horas** |

> **Recomendación para instructores:** Para respetar el tiempo de sesión de 2 horas, se recomienda pre-crear el cluster EKS ejecutando el Paso 1 antes de la clase. Esto reduce el tiempo de laboratorio activo a aproximadamente 90 minutos.

---

# Paso 0

## Advertencia de Costo y Prerequisitos

**Costo estimado del laboratorio:**

| Recurso | Costo/hora |
|---|---|
| EKS Cluster | $0.10/hora |
| 2x EC2 t3.medium | ~$0.08/hora |
| NAT Gateway | ~$0.045/hora |
| **Total aproximado** | **~$0.23/hora** |

> ⚠️ **Ejecutar `terraform destroy` al finalizar el laboratorio es OBLIGATORIO.** Un cluster EKS olvidado puede generar costos significativos.

**Prerequisitos verificados:**

- AWS CLI configurado con credenciales válidas
- Terraform instalado (>= 1.5.0)
- kubectl instalado
- Docker instalado
- Acceso a la cuenta AWS del curso

**Variables a configurar antes del Paso 1:**

```bash
export TF_VAR_aws_region="us-east-1"
export TF_VAR_project_name="invoice-lab"
export TF_VAR_environment="dev"
export TF_VAR_cluster_name="invoice-eks-dev"
```

---

# Paso 1

## Aprovisionamiento de Infraestructura

Objetivo:

Crear el cluster Kubernetes sobre AWS.

> ⏱️ **Tiempo estimado: 15-20 minutos.** El cluster EKS puede tardar hasta 20 minutos en quedar completamente operativo. Este es el comportamiento normal.

Comandos:

```bash
terraform init
terraform plan
terraform apply
```

Resultado esperado:

- Cluster EKS creado.
- Node Group creado.
- Outputs disponibles.

Verificar outputs tras el apply:

```bash
terraform output cluster_name
terraform output cluster_endpoint
```

Concepto aprendido:

Terraform permite automatizar infraestructura Kubernetes, incluyendo la red, los roles IAM y el cluster, mediante código declarativo.

---

# Paso 2

## Configuración de kubectl

Objetivo:

Conectar el equipo local al cluster.

Comando:

```bash
aws eks update-kubeconfig \
  --region $TF_VAR_aws_region \
  --name $TF_VAR_cluster_name
```

Validación:

```bash
kubectl get nodes
```

Resultado esperado:

Visualización de nodos con estado `Ready`.

> **Nota:** Si los nodos aparecen en estado `NotReady`, esperar 2-3 minutos adicionales y volver a ejecutar `kubectl get nodes`. Los nodos del Node Group pueden tardar unos minutos en completar el proceso de unión al cluster después de que Terraform finaliza.

> **Namespace:** Todos los recursos de este laboratorio se crean en el namespace `default`. Los recursos del sistema de Kubernetes (como CoreDNS, kube-proxy) se encuentran en el namespace `kube-system` y no deben modificarse.

Concepto aprendido:

kubectl es la herramienta principal de administración de Kubernetes. Se conecta al cluster a través del archivo `~/.kube/config` que el comando anterior configura automáticamente.

---

# Paso 3

## Publicación de Imagen en Amazon ECR

Objetivo:

Publicar la imagen Docker de la aplicación en Amazon ECR para que los nodos del cluster EKS puedan descargarla.

> **Por qué es necesario este paso:** Los nodos del cluster EKS son instancias EC2 en la nube de AWS. No tienen acceso al entorno local del alumno. La imagen `invoice-processor:v1` que existe en tu máquina es invisible para el cluster. Si se omite este paso y se aplica el Deployment directamente, los Pods quedarán en estado `ImagePullBackOff`.

Paso 3.1 — Crear el repositorio ECR:

```bash
aws ecr create-repository \
  --repository-name invoice-processor \
  --region $TF_VAR_aws_region
```

Anotar el `repositoryUri` del output. Tiene el formato:

```text
<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor
```

Paso 3.2 — Autenticar Docker contra ECR:

```bash
aws ecr get-login-password --region $TF_VAR_aws_region | \
  docker login --username AWS --password-stdin \
  <account_id>.dkr.ecr.<region>.amazonaws.com
```

Paso 3.3 — Build de la imagen:

```bash
docker build -t invoice-processor:v1 .
```

Paso 3.4 — Tag de la imagen:

```bash
docker tag invoice-processor:v1 \
  <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
```

Paso 3.5 — Push a ECR:

```bash
docker push \
  <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
```

Resultado esperado:

Imagen `invoice-processor:v1` visible en la consola de Amazon ECR.

Concepto aprendido:

Amazon ECR es el registry privado de AWS. Los nodos EKS tienen acceso automático a ECR gracias a la política `AmazonEC2ContainerRegistryPullOnly` configurada en el Node Group IAM Role. Este es el flujo estándar en pipelines CI/CD reales.

---

# Paso 4

## Generación de YAML mediante Claude Code

Objetivo:

Utilizar IA para acelerar la creación de recursos Kubernetes.

Archivos esperados:

- `deployment.yaml`
- `service.yaml`

Prompts a utilizar de SPEC_LAB_004E:

- **Prompt 1:** Genera el `deployment.yaml` ← artefacto desplegable
- **Prompt 2:** Analiza el `deployment.yaml` generado ← comprensión
- **Prompt 3:** Genera el `service.yaml` ← artefacto desplegable
- **Prompt 4:** Analiza el `service.yaml` generado ← comprensión

> **Importante:** Antes de ejecutar `kubectl apply` sobre cualquier YAML generado por Claude Code, el alumno debe verificar:
> - Que el nombre de la aplicación sea `invoice-processor`
> - Que la imagen apunte al URI correcto de ECR (no a `invoice-processor:v1` local)
> - Que el puerto del contenedor sea `8000`
> - Que los labels del Deployment coincidan con el selector del Service

Concepto aprendido:

La IA puede generar infraestructura declarativa, pero la revisión humana del manifiesto sigue siendo necesaria antes del despliegue.

---

# Paso 5

## Despliegue de Recursos

Objetivo:

Crear los recursos Kubernetes.

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

Concepto aprendido:

Kubernetes opera mediante declaraciones de estado deseado. `kubectl apply` entrega el manifiesto al API Server, que lo persiste en etcd. Los controladores internos (Deployment Controller, ReplicaSet Controller) se encargan de materializar ese estado creando los Pods reales.

---

# Paso 6

## Verificación

Objetivo:

Validar recursos creados.

Comandos:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

Resultado esperado — Deployments:

```text
NAME                READY   UP-TO-DATE   AVAILABLE
invoice-processor   2/2     2            2
```

Resultado esperado — Pods:

```text
NAME                                 READY   STATUS    RESTARTS
invoice-processor-xxxx-yyyy          1/1     Running   0
invoice-processor-xxxx-zzzz          1/1     Running   0
```

Resultado esperado — Services:

```text
NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP
invoice-processor-service   LoadBalancer   10.100.xxx.xxx  <pending o URL>
```

> **Sobre el tipo de Load Balancer:** En EKS, al aplicar un Service de tipo `LoadBalancer` sin el AWS Load Balancer Controller instalado, se crea automáticamente un **Classic Load Balancer (CLB)** de AWS. El CLB es funcional para este laboratorio. En arquitecturas productivas se recomienda el AWS Load Balancer Controller para obtener un Network Load Balancer (NLB) con características más modernas.

> **Sobre `EXTERNAL-IP <pending>`:** El EXTERNAL-IP puede tardar entre 2 y 5 minutos en asignarse mientras AWS aprovisiona el Classic Load Balancer. Volver a ejecutar `kubectl get services` hasta que aparezca la URL.

Concepto aprendido:

Inspección básica de recursos Kubernetes. La columna `READY` del Deployment muestra cuántos Pods están listos vs. el total deseado.

---

# Paso 7

## Consumo de la API

Objetivo:

Validar acceso a la aplicación.

Obtener el EXTERNAL-IP:

```bash
kubectl get services
```

Consumir la API:

```bash
curl http://<EXTERNAL-IP>
```

Resultado esperado:

```json
{
  "service": "invoice-processor",
  "version": "1.0",
  "status": "healthy"
}
```

Concepto aprendido:

Los usuarios consumen el Service (que tiene un IP/hostname estable), no los Pods directamente. Los Pods pueden cambiar de IP o ser reemplazados, pero el Service siempre mantiene el mismo punto de acceso.

---

# Paso 8

## Self-Healing

Objetivo:

Demostrar recuperación automática.

Obtener el nombre de uno de los Pods:

```bash
kubectl get pods
```

Eliminar el Pod:

```bash
kubectl delete pod <POD_NAME>
```

Validar recuperación:

```bash
kubectl get pods
```

Resultado esperado:

Un nuevo Pod creado automáticamente. El Pod eliminado desaparece y es reemplazado por uno nuevo con un nombre diferente.

Concepto aprendido:

El **ReplicaSet** (creado internamente por el Deployment) monitorea continuamente que la cantidad de Pods en ejecución coincida con el número de réplicas deseado. Al detectar que un Pod fue eliminado, el ReplicaSet Controller crea inmediatamente un Pod de reemplazo para restaurar el estado deseado. Este mecanismo se denomina **Self-Healing**.

---

# Paso 9

## Escalamiento

Objetivo:

Incrementar capacidad.

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

5 Pods ejecutándose.

Concepto aprendido:

El escalamiento horizontal en Kubernetes consiste en aumentar el número de réplicas en el Deployment. Kubernetes crea los Pods adicionales y el Service distribuye el tráfico entre todos los Pods disponibles automáticamente.

---

# Paso 10

## Rolling Update

Objetivo:

Actualizar la aplicación de v1 a v2 sin downtime.

### Paso 10.1 — Preparar la imagen v2

Modificar el código fuente de la aplicación: cambiar el valor de `version` de `"1.0"` a `"2.0"` en el endpoint `GET /`.

Build de la imagen v2:

```bash
docker build -t invoice-processor:v2 .
```

Tag con ECR:

```bash
docker tag invoice-processor:v2 \
  <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v2
```

Push a ECR:

```bash
docker push \
  <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v2
```

### Paso 10.2 — Actualizar el Deployment

Modificar en `deployment.yaml`:

```yaml
image: <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
```

por:

```yaml
image: <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v2
```

Aplicar:

```bash
kubectl apply -f deployment.yaml
```

Monitorear el rollout:

```bash
kubectl rollout status deployment invoice-processor
```

### Paso 10.3 — Verificar el resultado

```bash
curl http://<EXTERNAL-IP>
```

Resultado esperado:

```json
{
  "service": "invoice-processor",
  "version": "2.0",
  "status": "healthy"
}
```

Concepto aprendido:

Kubernetes reemplaza los Pods con la nueva imagen de forma progresiva (por defecto: 1 Pod a la vez), garantizando que siempre haya Pods disponibles para servir tráfico durante la actualización. Este mecanismo se denomina **Rolling Update**.

---

# Paso 11

## Cleanup — Destruir la Infraestructura

Objetivo:

Eliminar todos los recursos AWS creados durante el laboratorio para evitar costos innecesarios.

> ⚠️ **Este paso es OBLIGATORIO.** El cluster EKS, los nodos EC2 y el NAT Gateway generan costos por hora. No ejecutar este paso puede resultar en cargos significativos en la cuenta AWS.

Paso 11.1 — Eliminar los recursos Kubernetes (para que AWS limpie el Load Balancer):

```bash
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
```

> **Por qué eliminar primero los recursos Kubernetes:** El Service de tipo `LoadBalancer` crea un Classic Load Balancer en AWS. Si se destruye la infraestructura Terraform sin eliminar primero el Service, el CLB puede quedar como recurso huérfano en la cuenta AWS y seguir generando costo.

Paso 11.2 — Destruir la infraestructura Terraform:

```bash
terraform destroy
```

Confirmar con `yes`.

Resultado esperado:

```text
Destroy complete! Resources: XX destroyed.
```

---

# Resultado Final

Al finalizar el laboratorio, el alumno habrá:

1. Publicado una imagen de contenedor en Amazon ECR.
2. Desplegado una aplicación en Amazon EKS usando manifiestos YAML generados con Claude Code.
3. Consumido la API a través de un Load Balancer aprovisionado automáticamente por Kubernetes.
4. Observado el Self-Healing ejecutado por el ReplicaSet.
5. Escalado la aplicación horizontalmente.
6. Ejecutado un Rolling Update sin downtime de v1 a v2.
7. Destruido la infraestructura de forma ordenada.

Comprendiendo los componentes fundamentales de Kubernetes desde una perspectiva práctica en el ecosistema AWS.
