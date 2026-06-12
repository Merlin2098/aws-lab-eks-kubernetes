# SPEC_LAB_004A_KUBERNETES_USE_CASE
# Version 2.1

> **Changelog v2.1**
> - Se alinea el caso de uso con el resto de los specs 004B-004E.
> - Se separan con mayor claridad el objetivo tecnico, el objetivo pedagogico y el alcance.
> - Se refuerza la cadena `Service -> Deployment -> ReplicaSet -> Pods`.
> - Se mantienen constantes funcionales del laboratorio: `invoice-processor`, namespace `default`, puerto `8000`, Service en `80`, imagen en Amazon ECR.

---

## Objetivo Tecnico

Desplegar una API minima sobre Amazon EKS para demostrar como Kubernetes ejecuta, expone y administra aplicaciones contenerizadas.

La aplicacion del laboratorio se llama:

`invoice-processor`

La imagen del contenedor debe publicarse en Amazon ECR antes del despliegue en Kubernetes.

---

## Objetivo Pedagogico

Al finalizar el laboratorio, el alumno debe comprender:

- Que es un Pod
- Que es un ReplicaSet
- Que es un Deployment
- Que es un Service
- Como Kubernetes mantiene el estado deseado
- Como Kubernetes recupera Pods eliminados
- Como Kubernetes escala horizontalmente
- Como Kubernetes actualiza una aplicacion sin downtime visible
- Por que ECR es necesario como registry central para EKS

---

## Caso de Negocio

Una empresa de procesamiento de facturas desea exponer una API interna para validar rapidamente el estado de salud de su plataforma.

La aplicacion debe:

- Ejecutarse dentro de Kubernetes
- Estar disponible externamente
- Poder escalar horizontalmente
- Recuperarse automaticamente ante fallos

---

## Solucion Propuesta

Se desplegara una API FastAPI minima llamada `invoice-processor`.

La aplicacion:

- se ejecuta en Pods
- es administrada por un Deployment
- mantiene replicas mediante un ReplicaSet
- se expone mediante un Service de tipo `LoadBalancer`
- usa una imagen almacenada en Amazon ECR

---

## Flujo Arquitectonico

```text
Usuario
  ->
AWS Classic Load Balancer
(creado automaticamente por Kubernetes al aplicar el Service)
  ->
Kubernetes Service (LoadBalancer)
  ->
Deployment
  ->
ReplicaSet
  ->
Pods
  ->
Contenedor FastAPI
(imagen almacenada en Amazon ECR)
```

### Explicacion de la Cadena

- El `Service` es el punto de acceso estable para el trafico.
- El `Deployment` define el estado deseado de la aplicacion.
- El `Deployment` crea y administra internamente un `ReplicaSet`.
- El `ReplicaSet` garantiza que exista la cantidad deseada de Pods.
- Los `Pods` ejecutan el contenedor real de `invoice-processor`.

> **Nota tecnica:** En EKS, cuando se crea un Service de tipo `LoadBalancer` sin instalar el AWS Load Balancer Controller, AWS aprovisiona automaticamente un **Classic Load Balancer (CLB)**. Esto es suficiente para un laboratorio introductorio. En escenarios productivos se prefiere el AWS Load Balancer Controller.

---

## API del Laboratorio

Endpoint principal:

`GET /`

Respuesta esperada en v1:

```json
{
  "service": "invoice-processor",
  "version": "1.0",
  "status": "healthy"
}
```

---

## Namespace

Todos los recursos Kubernetes del laboratorio se crean en el namespace `default`.

No se deben modificar recursos del namespace `kube-system`.

---

## Alcance

Incluido:

- Publicacion de la imagen en Amazon ECR
- Aprovisionamiento de infraestructura minima para EKS
- Deploy inicial
- Consumo de API mediante `Service` tipo `LoadBalancer`
- Self-healing mediante ReplicaSet
- Escalamiento horizontal
- Rolling update de `v1` a `v2`

No incluido:

- Base de datos
- Persistencia
- Ingress
- CI/CD
- Observabilidad avanzada
- Seguridad avanzada
- AWS Load Balancer Controller

---

## Versiones del Laboratorio

### Version 1

- Tag de imagen: `invoice-processor:v1`
- Campo `version` en la respuesta: `"1.0"`

### Version 2

- Tag de imagen: `invoice-processor:v2`
- Campo `version` en la respuesta: `"2.0"`

El unico cambio funcional entre v1 y v2 es el valor visible del campo `version`, para que el rolling update sea comprobable de forma sencilla.
