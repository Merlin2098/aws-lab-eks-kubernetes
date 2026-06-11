# SPEC_LAB_004C_FASTAPI_SERVICE
# Versión 2.0

> **Changelog v2.0**
> - HC-01 / IC-02: Se agrega sección de publicación en Amazon ECR. La imagen debe estar en un registry accesible antes de ser usada por EKS.
> - HI-04: Se define explícitamente la diferencia entre v1 y v2 para el Rolling Update.
> - hm-02: Se especifica `--no-cache-dir` en el Dockerfile para imágenes más limpias.
> - R-06 (parcial): Se agrega endpoint `GET /health` dedicado para uso como probe de Kubernetes.
> - hm-01: Se agrega nota explicativa sobre la relación entre `port` y `targetPort`.

---

## Objetivo

Crear una API mínima que permita visualizar el comportamiento de Kubernetes.

La API debe ser simple para evitar distraer al alumno con conceptos de desarrollo backend.

---

# Tecnología

- Python 3.x

- FastAPI

- Uvicorn

---

# Nombre de la Aplicación

invoice-processor

---

# Endpoint Principal

GET /

---

# Respuesta Esperada — Versión 1

```json
{
  "service": "invoice-processor",
  "version": "1.0",
  "status": "healthy"
}
```

---

# Endpoint de Versión

GET /version

Respuesta:

```json
{
  "version": "1.0"
}
```

---

# Endpoint de Health

GET /health

Respuesta:

```json
{
  "status": "healthy"
}
```

> **Por qué agregar este endpoint:** En Kubernetes es una buena práctica exponer un endpoint dedicado para health checks, separado del endpoint de negocio. Este endpoint puede utilizarse como `livenessProbe` y `readinessProbe` en el manifiesto del Deployment. Para este laboratorio introductorio no se configuran probes, pero el endpoint se incluye para demostrar el patrón correcto.

---

# Definición de Versiones

## Versión 1 (invoice-processor:v1)

Campo `version` en la respuesta del endpoint GET /:

```json
"version": "1.0"
```

Utilizada en:
- Deploy inicial
- Demostraciones de Self-Healing
- Escalamiento

## Versión 2 (invoice-processor:v2)

Campo `version` en la respuesta del endpoint GET /:

```json
"version": "2.0"
```

Cambio realizado:
- Modificar la constante `VERSION` en el código fuente de `"1.0"` a `"2.0"`.

Utilizada en:
- Demostración de Rolling Update

> **Propósito pedagógico:** El cambio de versión entre v1 y v2 es observable directamente en el campo `version` de la respuesta JSON. Esto permite al alumno verificar de forma concreta que Kubernetes actualizó los Pods con la nueva imagen.

---

# Dockerización

La aplicación deberá ejecutarse mediante Docker.

Se requiere:

- Dockerfile
- requirements.txt

## Requisitos del Dockerfile

- Utilizar imagen base oficial Python slim para minimizar tamaño.
- Instalar dependencias con `--no-cache-dir` para reducir el tamaño de la imagen.
- Exponer el puerto 8000.
- Configurar Uvicorn para escuchar en `0.0.0.0` (todas las interfaces de red del contenedor).

---

# Imagen Docker

Convención de nombres:

```text
invoice-processor:v1   ← versión inicial
invoice-processor:v2   ← versión del Rolling Update
```

Nombre en Amazon ECR:

```text
<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v2
```

---

# Publicación en Amazon ECR

La imagen debe estar disponible en Amazon ECR antes de ejecutar `kubectl apply`.

Los nodos del cluster EKS son instancias EC2 en AWS y no tienen acceso al entorno local del alumno. Una imagen que solo existe en la máquina local causará un error `ImagePullBackOff` al intentar ejecutar el Pod.

Proceso requerido:

1. Crear repositorio ECR: `invoice-processor`
2. Autenticar Docker contra ECR
3. Build de la imagen local
4. Tag de la imagen con la URL de ECR
5. Push a ECR

> **Prerequisito:** El Node Group IAM Role debe tener la política `AmazonEC2ContainerRegistryPullOnly` para que los nodos puedan hacer pull de imágenes desde ECR. Esta política está incluida en la especificación SPEC_LAB_004B v2.

---

# Relación de Puertos

| Nivel | Puerto | Descripción |
|---|---|---|
| Contenedor | 8000 | Puerto donde Uvicorn escucha dentro del Pod |
| Kubernetes Service (targetPort) | 8000 | Puerto al que el Service envía el tráfico |
| Kubernetes Service (port) | 80 | Puerto externo expuesto por el Service |
| Load Balancer | 80 | Puerto público accesible desde internet |

> **Nota pedagógica:** El alumno accede a la API por el puerto 80 (sin necesidad de especificar el puerto en la URL), mientras que internamente la aplicación sigue usando el puerto 8000. Esta separación es una de las funciones clave de un Kubernetes Service.

---

# Objetivo Pedagógico

Permitir demostrar:

- Deploy inicial.

- Service Discovery.

- Escalamiento.

- Rolling Update con cambio observable (v1 → v2).

---

# Consideraciones

No utilizar:

- Base de datos.

- Variables sensibles.

- Autenticación.

- Integraciones externas.

La aplicación debe ser completamente stateless.
