# SPEC_LAB_004A_KUBERNETES_USE_CASE
# Versión 2.0

> **Changelog v2.0**
> - HC-01: Se agrega nota de alcance indicando que la imagen requiere publicarse en Amazon ECR.
> - HC-02 / IC-01: Se corrige el diagrama de arquitectura para reflejar que el Load Balancer es creado dinámicamente por Kubernetes, y se aclara el tipo de LB resultante (CLB).
> - HI-05: Se agrega ReplicaSet como objetivo de aprendizaje secundario y concepto del glosario.
> - hm-07: Se explicita el uso del namespace `default`.

---

## Objetivo

Introducir al alumno en Kubernetes mediante el despliegue de una API sencilla sobre Amazon EKS.

El laboratorio busca demostrar cómo Kubernetes administra aplicaciones contenerizadas utilizando Pods, Deployments, ReplicaSets y Services.

---

# Caso de Negocio

Una empresa de procesamiento de facturas desea exponer una API interna que permita validar el estado de salud de su plataforma.

La aplicación debe:

- Ejecutarse dentro de Kubernetes.

- Estar disponible externamente.

- Poder escalar horizontalmente.

- Recuperarse automáticamente ante fallos.

---

# Solución Propuesta

Se desplegará una API FastAPI denominada:

invoice-processor

La API responderá información básica de estado.

La imagen del contenedor será publicada en Amazon ECR y consumida directamente por los nodos del cluster EKS.

---

# Endpoint

GET /

Respuesta esperada:

```json
{
  "service": "invoice-processor",
  "version": "1.0",
  "status": "healthy"
}
```

---

# Objetivos de Aprendizaje

El alumno deberá comprender:

- Qué es un Pod.

- Qué es un ReplicaSet y por qué es responsable del Self-Healing.

- Qué es un Deployment y cómo administra ReplicaSets.

- Qué es un Service.

- Cómo Kubernetes mantiene el estado deseado.

- Cómo Kubernetes expone aplicaciones.

- Cómo Kubernetes escala aplicaciones.

- Cómo Amazon ECR almacena y distribuye imágenes de contenedor.

---

# Arquitectura

```text
Usuario
  ↓
AWS Classic Load Balancer
(creado automáticamente por Kubernetes al aplicar el Service)
  ↓
Kubernetes Service (tipo LoadBalancer)
  ↓
Deployment
  ↓
ReplicaSet
(administrado internamente por el Deployment)
  ↓
Pods
  ↓
FastAPI Container
(imagen almacenada en Amazon ECR)
```

> **Nota técnica:** En EKS, cuando se aplica un Service de tipo `LoadBalancer` sin el AWS Load Balancer Controller instalado, se crea automáticamente un **Classic Load Balancer (CLB)**. Esto es funcional para este laboratorio introductorio. En entornos productivos se recomienda el **AWS Load Balancer Controller** para obtener un Network Load Balancer (NLB) con características modernas.

---

# Namespace

Todos los recursos de Kubernetes de este laboratorio se crean en el namespace **default**.

El namespace `default` es el espacio de nombres estándar para cargas de trabajo en clusters nuevos. Los recursos del sistema de Kubernetes residen en el namespace `kube-system`.

---

# Alcance

Incluido:

- Publicación de imagen en Amazon ECR.

- Deploy inicial.

- Consumo de API.

- Self-Healing (ejecutado internamente por el ReplicaSet).

- Escalamiento.

- Rolling Update con imagen v2.

No incluido:

- Base de datos.

- Persistencia.

- Ingress.

- CI/CD.

- Observabilidad.

- Seguridad avanzada.

- AWS Load Balancer Controller.
