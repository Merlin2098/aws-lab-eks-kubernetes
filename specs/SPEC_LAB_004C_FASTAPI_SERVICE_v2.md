# SPEC_LAB_004C_FASTAPI_SERVICE
# Version 2.1

> **Changelog v2.1**
> - Se simplifica la especificacion del servicio FastAPI.
> - Se fijan sin ambiguedad endpoints, payloads y diferencia entre `v1` y `v2`.
> - Se compactan los requisitos de Dockerizacion.
> - Se refuerza que el servicio es stateless y pedagogicamente minimo.

---

## Objetivo

Definir una API minima que permita observar de forma clara el comportamiento de Kubernetes sin introducir complejidad innecesaria de backend.

La aplicacion debe ser:

- pequena
- stateless
- facil de contenerizar
- observable mediante respuestas JSON simples

---

## Tecnologia

- Python 3.x
- FastAPI
- Uvicorn

---

## Nombre de la Aplicacion

`invoice-processor`

---

## Endpoints Obligatorios

### GET /

Respuesta esperada en v1:

```json
{
  "service": "invoice-processor",
  "version": "1.0",
  "status": "healthy"
}
```

Respuesta esperada en v2:

```json
{
  "service": "invoice-processor",
  "version": "2.0",
  "status": "healthy"
}
```

### GET /version

Respuesta esperada en v1:

```json
{
  "version": "1.0"
}
```

Respuesta esperada en v2:

```json
{
  "version": "2.0"
}
```

### GET /health

Respuesta esperada:

```json
{
  "status": "healthy"
}
```

Este endpoint existe para ilustrar el patron correcto de health check separado del endpoint principal.

---

## Versiones del Laboratorio

### Version 1

- imagen: `invoice-processor:v1`
- valor visible del campo `version`: `"1.0"`
- uso: deploy inicial, self-healing y escalamiento

### Version 2

- imagen: `invoice-processor:v2`
- valor visible del campo `version`: `"2.0"`
- uso: rolling update

La diferencia entre v1 y v2 debe limitarse al valor del campo `version`.

---

## Requisitos Minimos de Dockerizacion

Se requieren estos artefactos:

- `Dockerfile`
- archivo de dependencias Python

El `Dockerfile` debe:

- usar una imagen base oficial `python:slim`
- instalar dependencias con `--no-cache-dir`
- exponer el puerto `8000`
- ejecutar Uvicorn escuchando en `0.0.0.0`

Puerto interno obligatorio del contenedor:

`8000`

---

## Imagen en Amazon ECR

La imagen debe estar publicada en Amazon ECR antes de aplicar el Deployment.

Formato esperado:

```text
<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v2
```

Si se usa una imagen que solo existe localmente, los Pods no podran arrancar y Kubernetes mostrara errores como `ImagePullBackOff`.

---

## Relacion de Puertos

| Nivel | Puerto | Descripcion |
|---|---|---|
| Contenedor | 8000 | Puerto donde escucha Uvicorn dentro del Pod |
| Service targetPort | 8000 | Puerto interno al que el Service envia trafico |
| Service port | 80 | Puerto expuesto por el Service |
| Load Balancer | 80 | Puerto publico accesible por el alumno |

---

## Restricciones del Servicio

No utilizar:

- base de datos
- persistencia
- autenticacion
- variables sensibles
- integraciones externas

El servicio debe permanecer completamente stateless y orientado solo a fines didacticos.
