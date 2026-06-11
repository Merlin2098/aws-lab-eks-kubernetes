# SPEC_LAB_004E_CLAUDE_CODE_PROMPTS
# Versión 2.0

> **Changelog v2.0**
> - HC-01: Se agrega instrucción en Prompts 1 y 3 para que el YAML incluya la URL completa de ECR en el campo `image`, no solo el nombre local.
> - HC-01: Se agrega `imagePullPolicy: IfNotPresent` en Prompt 1 (best practice para imágenes tagueadas con versión).
> - HI-05: Se actualiza el Prompt 8 para incluir el concepto de ReplicaSet en la explicación del Self-Healing.
> - HI-06: Se reemplaza Prompt 5 (diagrama ASCII de bajo valor) por un Prompt 5 de diagnóstico real con `kubectl describe pod`.
> - IC-03: Se clarifica en la introducción qué prompts generan artefactos vs. cuáles son de comprensión.
> - IC-06: Se reposiciona Prompt 11 (ECS vs EKS) como prompt de cierre/reflexión post-laboratorio.
> - Nuevo Prompt 12b: Se agrega prompt sobre `kubectl logs` para introducir troubleshooting básico.
> - Se agrega Checklist de Revisión de YAML antes del `kubectl apply`.

---

## Objetivo

Definir los prompts que utilizará el alumno durante el laboratorio para generar y analizar recursos Kubernetes utilizando Claude Code.

Este documento busca demostrar cómo la IA puede acelerar la adopción de Kubernetes sin reemplazar la comprensión de los conceptos fundamentales.

---

# Filosofía del Laboratorio

Claude Code NO debe ser utilizado como una caja negra.

El alumno debe:

1. Entender qué recurso necesita.

2. Solicitar ayuda a Claude Code.

3. Revisar el resultado generado.

4. Aplicar el Checklist de Revisión (ver abajo).

5. Comprender la estructura del recurso.

6. Desplegar el recurso.

7. Validar el comportamiento obtenido.

---

# Checklist de Revisión de YAML

Antes de ejecutar `kubectl apply` sobre cualquier YAML generado por Claude Code, verificar:

- [ ] El campo `image` apunta al URI completo de ECR (no a `invoice-processor:v1` local).
- [ ] El puerto del contenedor es `8000`.
- [ ] Los `labels` del Deployment coinciden con el `selector` del Service.
- [ ] El número de `replicas` es el correcto para el paso actual (2 inicialmente).
- [ ] El `type` del Service es `LoadBalancer`.
- [ ] El `targetPort` del Service es `8000` y el `port` externo es `80`.
- [ ] `imagePullPolicy: IfNotPresent` está especificado en el Deployment.

---

# Mapa de Prompts

| Prompt | Tipo | Artefacto generado |
|---|---|---|
| Prompt 1 | Generación | `deployment.yaml` |
| Prompt 2 | Comprensión | — |
| Prompt 3 | Generación | `service.yaml` |
| Prompt 4 | Comprensión | — |
| Prompt 5 | Diagnóstico | — |
| Prompt 6 | Comprensión | — |
| Prompt 7 | Comprensión | — |
| Prompt 8 | Conceptual | — |
| Prompt 9 | Conceptual | — |
| Prompt 10 | Conceptual | — |
| Prompt 11 | Troubleshooting | — |
| Prompt 12 | Comparación (cierre) | — |
| Prompt 13 | Reflexión final | — |

---

# Escenario Base

Aplicación:

invoice-processor

Imagen Docker (URI ECR completo — reemplazar con el URI real):

```text
<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
```

Puerto:

8000

Réplicas Iniciales:

2

Tipo de Exposición:

LoadBalancer

---

# Prompt 1

## Generación del Deployment

### Objetivo

Generar el recurso Deployment.

### Prompt

```text
Actúa como un Kubernetes Engineer Senior.

Genera un deployment.yaml para Kubernetes.

Requisitos:

- Nombre de aplicación: invoice-processor
- Imagen: <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
  (reemplazar con el URI real de Amazon ECR)
- Réplicas: 2
- Puerto del contenedor: 8000
- imagePullPolicy: IfNotPresent
- Labels consistentes para facilitar el uso de Services
- Utilizar buenas prácticas de nomenclatura
- Incluir comentarios explicativos en el YAML

Además, explica brevemente:

- Qué es un Deployment
- Qué es un ReplicaSet y cómo el Deployment lo administra internamente
- Qué función cumple cada sección principal
- Cómo Kubernetes utiliza este recurso
```

---

# Resultado Esperado

Claude debe generar:

```text
deployment.yaml
```

Y una explicación asociada que incluya la mención del ReplicaSet como objeto interno gestionado por el Deployment.

---

# Concepto Enseñado

El Deployment define el estado deseado de la aplicación. Internamente, crea y gestiona un ReplicaSet que es responsable de mantener el número correcto de Pods en ejecución.

---

# Prompt 2

## Análisis del Deployment

### Objetivo

Comprender el YAML generado.

### Prompt

```text
Explícame este deployment.yaml línea por línea.

Describe:

- metadata
- labels
- selector
- replicas
- template
- containers
- image
- imagePullPolicy
- ports

Utiliza explicaciones simples orientadas a una persona que está aprendiendo Kubernetes.
```

---

# Concepto Enseñado

Interpretación de manifiestos Kubernetes.

---

# Prompt 3

## Generación del Service

### Objetivo

Crear el Service que expondrá la aplicación.

### Prompt

```text
Actúa como un Kubernetes Engineer Senior.

Genera un service.yaml para Kubernetes.

Requisitos:

- Nombre: invoice-processor-service
- Tipo: LoadBalancer
- Puerto externo: 80
- Puerto interno del contenedor (targetPort): 8000
- Debe apuntar al Deployment invoice-processor usando los mismos labels
- Incluir comentarios explicativos

Además explica:

- Qué es un Service
- Cómo encuentra los Pods usando labels y selectors
- Qué tipo de Load Balancer crea AWS automáticamente al aplicar este Service en EKS
- Cómo funciona el balanceo de carga entre múltiples Pods
```

---

# Resultado Esperado

Claude debe generar:

```text
service.yaml
```

---

# Concepto Enseñado

Exposición de aplicaciones dentro de Kubernetes. La relación entre el `selector` del Service y los `labels` del Deployment.

---

# Prompt 4

## Análisis del Service

### Objetivo

Comprender la relación entre Service y Pods.

### Prompt

```text
Explícame este service.yaml línea por línea.

Describe:

- metadata
- selector y cómo se relaciona con los labels del Deployment
- ports
- port (puerto externo)
- targetPort (puerto del contenedor)
- type LoadBalancer y qué recurso AWS crea en EKS

Utiliza ejemplos prácticos y analogías sencillas.
```

---

# Concepto Enseñado

Service Discovery. La relación entre `port` y `targetPort`.

---

# Prompt 5

## Diagnóstico de Pod — kubectl describe

### Objetivo

Introducir el troubleshooting básico de Pods en Kubernetes usando Claude Code como herramienta de interpretación.

### Prompt

```text
Te comparto la salida del siguiente comando ejecutado sobre mi cluster EKS:

kubectl describe pod <nombre-del-pod>

[pegar aquí la salida completa del comando]

Por favor:

- Explícame qué significa cada sección principal (Name, Namespace, Node, Status, Containers, Events)
- Identifica si hay algún error o advertencia en la sección Events
- Explica el significado de los estados posibles de un Pod (Pending, Running, CrashLoopBackOff, ImagePullBackOff, OOMKilled)
- Si encuentras algún problema, propone los pasos concretos para resolverlo
```

> **Nota para el instructor:** Este prompt se ejecuta después del Paso 5 (Despliegue) de la guía. El alumno pega la salida real de su `kubectl describe pod` y Claude Code la analiza. Esto demuestra el valor de la IA como herramienta de diagnóstico, no solo de generación de código.

---

# Concepto Enseñado

Troubleshooting básico de Pods en Kubernetes. Interpretación de la sección `Events` como fuente principal de diagnóstico.

---

# Prompt 6

## Diagnóstico de Pods — kubectl get pods

### Objetivo

Interpretar el estado de ejecución.

### Prompt

```text
Te compartiré la salida de:

kubectl get pods

Explícame:

- Qué significa cada columna
- Qué estados pueden aparecer
- Cómo identificar problemas básicos
- Cuándo un Pod está funcionando correctamente
```

---

# Concepto Enseñado

Monitoreo básico de Pods.

---

# Prompt 7

## Diagnóstico de Services

### Objetivo

Interpretar la salida de Services.

### Prompt

```text
Te compartiré la salida de:

kubectl get services

Explícame:

- Qué significa cada columna
- Qué es ClusterIP
- Qué es LoadBalancer
- Qué es EXTERNAL-IP
- Por qué EXTERNAL-IP puede aparecer como <pending> y cuánto tiempo normal debe esperar
- Cómo se consume una aplicación desde Internet a través del Service
```

---

# Concepto Enseñado

Exposición de servicios. Tiempo de aprovisionamiento del Load Balancer.

---

# Prompt 8

## Simulación de Self-Healing

### Objetivo

Comprender la recuperación automática y el papel del ReplicaSet.

### Prompt

```text
Eliminé manualmente uno de los Pods del Deployment invoice-processor con el comando:

kubectl delete pod <pod-name>

Explícame paso a paso qué ocurre internamente dentro de Kubernetes:

1. Qué detecta primero y qué objeto de Kubernetes es responsable de la detección
2. Qué es un ReplicaSet y cuál es su función específica en este escenario
3. Cómo el ReplicaSet y el Deployment trabajan juntos para recuperar el estado deseado
4. Cuánto tiempo tarda aproximadamente en crearse el Pod de reemplazo
5. Cómo verificar que el nuevo Pod está corriendo correctamente
```

---

# Concepto Enseñado

Desired State, Self-Healing, y el papel del ReplicaSet como controlador responsable de mantener el número de Pods.

---

# Prompt 9

## Escalamiento Horizontal

### Objetivo

Comprender el aumento de capacidad.

### Prompt

```text
Actualmente tengo:

replicas: 2

Voy a cambiarlo por:

replicas: 5

Explícame:

- Qué sucede dentro de Kubernetes al ejecutar kubectl apply con el cambio
- Qué objetos de Kubernetes están involucrados (Deployment, ReplicaSet, Pods)
- Cómo el Service distribuye tráfico entre los 5 Pods
- Qué beneficios aporta este cambio en términos de disponibilidad y rendimiento
```

---

# Concepto Enseñado

Escalamiento horizontal y distribución de tráfico.

---

# Prompt 10

## Rolling Update

### Objetivo

Comprender actualizaciones sin interrupción.

### Prompt

```text
Mi Deployment actualmente utiliza:

<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1

Voy a actualizarlo a:

<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v2

Explícame paso a paso:

- Cómo Kubernetes detecta el cambio de imagen
- Qué estrategia de actualización usa por defecto (RollingUpdate)
- Cuántos Pods reemplaza a la vez y por qué
- Cómo garantiza que no haya downtime durante la actualización
- Qué ocurre con los Pods de v1 mientras se crean los de v2
- Cómo verificar el estado del rollout con kubectl rollout status
```

---

# Concepto Enseñado

Rolling Updates y estrategia de actualización sin interrupción de servicio.

---

# Prompt 11

## Diagnóstico con kubectl logs

### Objetivo

Introducir el troubleshooting mediante logs de Pods.

### Prompt

```text
Actúa como un Kubernetes Engineer Senior.

Explícame cómo usar el comando kubectl logs para diagnosticar problemas en mis Pods.

Incluye:

- Sintaxis básica: kubectl logs <pod-name>
- Cómo ver los logs de un Pod que ya terminó (--previous)
- Cómo hacer seguimiento en tiempo real (-f)
- Qué tipo de información esperar en los logs de un Pod con FastAPI/Uvicorn
- Cómo diferenciar un error de aplicación de un problema de infraestructura en los logs
- Un ejemplo de log de arranque exitoso de Uvicorn
```

---

# Concepto Enseñado

Troubleshooting básico mediante logs de Pods. Diferencia entre problemas de aplicación y problemas de infraestructura.

---

# Prompt 12

## Comparación ECS vs EKS (Cierre del Laboratorio)

### Objetivo

Conectar el laboratorio con conocimientos previos del curso. Este prompt se ejecuta al finalizar todas las actividades del laboratorio, como actividad de cierre.

### Prompt

```text
Compara el laboratorio que acabo de realizar en Amazon EKS con el laboratorio anterior realizado en Amazon ECS.

Explica:

- Qué similitudes existen en el flujo de trabajo (build → registry → deploy → escalar)
- Qué diferencias hay en la complejidad de configuración
- Qué conceptos de Kubernetes no existen en ECS (Pod, Deployment, ReplicaSet, Service)
- Cuándo utilizar ECS (equipos pequeños, aplicaciones simples, menor curva de aprendizaje)
- Cuándo utilizar EKS (equipos DevOps, aplicaciones complejas, portabilidad multi-cloud)

Utiliza ejemplos prácticos orientados a arquitecturas AWS.
```

---

# Concepto Enseñado

Posicionamiento de Kubernetes dentro del ecosistema AWS y criterios de decisión ECS vs EKS.

---

# Prompt 13

## Reflexión Final

### Objetivo

Consolidar el aprendizaje.

### Prompt

```text
Actúa como instructor de Kubernetes para principiantes.

Resume los conceptos aprendidos en este laboratorio:

- Pod: qué es y cómo se relaciona con el contenedor
- ReplicaSet: qué es y por qué es el responsable del Self-Healing
- Deployment: qué es y cómo administra ReplicaSets
- Service: qué es y cómo expone la aplicación
- LoadBalancer: qué recurso AWS se crea y cómo llega el tráfico
- Self-Healing: qué lo ejecuta y cómo funciona
- Escalamiento: cómo Kubernetes distribuye el tráfico adicional
- Rolling Updates: cómo garantiza cero downtime
- Amazon ECR: por qué los nodos EKS necesitan un registry centralizado
- EKS: cómo AWS administra el plano de control de Kubernetes

Genera una explicación breve orientada a una persona que acaba de completar su primer laboratorio de Kubernetes.
```

---

# Resultado Esperado del Uso de Claude Code

Al finalizar el laboratorio, el alumno deberá comprender que:

- La IA acelera la generación de recursos Kubernetes.

- La IA facilita la comprensión de conceptos complejos.

- La IA es una herramienta de diagnóstico que puede interpretar errores reales.

- La validación humana sigue siendo necesaria antes de ejecutar cualquier manifiesto.

- Terraform, Kubernetes, ECR e IA son herramientas complementarias en un flujo moderno.

- El objetivo no es memorizar YAML, sino comprender cómo funciona el sistema.

---

# Criterio de Éxito

El alumno deberá ser capaz de:

1. Solicitar a Claude Code la generación de recursos Kubernetes.

2. Aplicar el Checklist de Revisión antes del despliegue.

3. Comprender los manifiestos generados.

4. Desplegar dichos recursos sobre EKS.

5. Analizar el comportamiento observado.

6. Utilizar Claude Code para interpretar estados y errores reales del cluster.

7. Utilizar IA como acelerador de aprendizaje y productividad, no como sustituto de la comprensión.
