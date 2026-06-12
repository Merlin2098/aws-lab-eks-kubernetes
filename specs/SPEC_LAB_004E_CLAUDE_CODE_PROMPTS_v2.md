# SPEC_LAB_004E_CLAUDE_CODE_PROMPTS
# Version 2.1

> **Changelog v2.1**
> - Se alinean los prompts con los specs 004A-004D.
> - Se vuelven mas estrictos los prompts de generacion para evitar YAML generico o inconsistente.
> - Se consolida el checklist de revision antes de `kubectl apply`.
> - Se diferencian con claridad prompts de generacion, comprension, diagnostico y cierre conceptual.

---

## Objetivo

Definir los prompts que el alumno utilizara con Claude Code para generar y analizar los recursos Kubernetes del laboratorio.

La IA se usa como acelerador de aprendizaje y productividad, no como sustituto de la revision humana.

---

## Principios de Uso

El alumno debe:

1. entender que recurso necesita
2. pedir ayuda a Claude Code
3. revisar el YAML generado
4. validar el YAML con el checklist
5. desplegar
6. observar el comportamiento real del cluster

---

## Escenario Base

Constantes del laboratorio:

- aplicacion: `invoice-processor`
- namespace: `default`
- imagen: `<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1`
- puerto del contenedor: `8000`
- replicas iniciales: `2`
- tipo de exposicion: `LoadBalancer`
- Service externo: `80`
- Service interno `targetPort`: `8000`

---

## Checklist de Revision de YAML

Antes de ejecutar `kubectl apply`, verificar:

- [ ] `metadata.name` del Deployment es `invoice-processor`
- [ ] `metadata.name` del Service es `invoice-processor-service`
- [ ] el namespace es `default`
- [ ] el campo `image` usa el URI completo de Amazon ECR
- [ ] la imagen apunta a `v1` o `v2` segun el paso del laboratorio
- [ ] el puerto del contenedor es `8000`
- [ ] `imagePullPolicy: IfNotPresent` esta definido
- [ ] el numero de replicas es `2` al inicio
- [ ] los labels del Deployment coinciden con el selector del Service
- [ ] el Service es de tipo `LoadBalancer`
- [ ] `port` es `80`
- [ ] `targetPort` es `8000`

---

## Mapa de Prompts

| Prompt | Tipo | Resultado esperado |
|---|---|---|
| 1 | Generacion | `deployment.yaml` |
| 2 | Comprension | Explicacion del Deployment |
| 3 | Generacion | `service.yaml` |
| 4 | Comprension | Explicacion del Service |
| 5 | Diagnostico | Analisis de `kubectl describe pod` |
| 6 | Diagnostico | Analisis de `kubectl get pods` |
| 7 | Diagnostico | Analisis de `kubectl get services` |
| 8 | Conceptual | Explicacion de self-healing |
| 9 | Conceptual | Explicacion de escalamiento |
| 10 | Conceptual | Explicacion de rolling update |
| 11 | Troubleshooting | Uso de `kubectl logs` |
| 12 | Comparacion | EKS vs ECS |
| 13 | Cierre | Resumen final del laboratorio |

---

## Prompt 1 - Generacion del Deployment

```text
Actua como un Kubernetes Engineer Senior.

Genera un deployment.yaml para Kubernetes.

Requisitos obligatorios:

- Nombre de la aplicacion: invoice-processor
- Namespace: default
- Imagen: <account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1
- Replicas iniciales: 2
- Puerto del contenedor: 8000
- imagePullPolicy: IfNotPresent
- Labels consistentes para que el Service pueda seleccionar los Pods
- Incluir comentarios explicativos en el YAML

Ademas, explica brevemente:

- que es un Deployment
- que es un ReplicaSet
- como el Deployment administra internamente al ReplicaSet
- que funcion cumple cada seccion principal del YAML
```

Resultado esperado:

- artefacto desplegable `deployment.yaml`
- explicacion breve y consistente con el laboratorio

---

## Prompt 2 - Comprension del Deployment

```text
Explicame este deployment.yaml linea por linea.

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

Usa explicaciones simples orientadas a una persona que esta aprendiendo Kubernetes.
```

---

## Prompt 3 - Generacion del Service

```text
Actua como un Kubernetes Engineer Senior.

Genera un service.yaml para Kubernetes.

Requisitos obligatorios:

- Nombre: invoice-processor-service
- Namespace: default
- Tipo: LoadBalancer
- Puerto externo: 80
- targetPort: 8000
- Debe apuntar al Deployment invoice-processor usando los mismos labels
- Incluir comentarios explicativos

Ademas explica:

- que es un Service
- como encuentra Pods usando labels y selectors
- que recurso AWS crea EKS en este escenario
- como balancea trafico entre multiples Pods
```

Resultado esperado:

- artefacto desplegable `service.yaml`

---

## Prompt 4 - Comprension del Service

```text
Explicame este service.yaml linea por linea.

Describe:

- metadata
- selector y su relacion con los labels del Deployment
- ports
- port
- targetPort
- type LoadBalancer
- que recurso AWS se crea en EKS en este escenario

Usa ejemplos practicos y analogias sencillas.
```

---

## Prompt 5 - Diagnostico con kubectl describe pod

```text
Te comparto la salida del siguiente comando:

kubectl describe pod <nombre-del-pod>

[pegar aqui la salida completa]

Por favor:

- explicame que significa cada seccion principal
- identifica errores o advertencias en Events
- explica estados como Pending, Running, CrashLoopBackOff, ImagePullBackOff y OOMKilled
- si encuentras un problema, propone pasos concretos para resolverlo
```

---

## Prompt 6 - Diagnostico con kubectl get pods

```text
Te compartire la salida de:

kubectl get pods

Explicame:

- que significa cada columna
- que estados pueden aparecer
- como identificar problemas basicos
- cuando un Pod esta funcionando correctamente
```

---

## Prompt 7 - Diagnostico con kubectl get services

```text
Te compartire la salida de:

kubectl get services

Explicame:

- que significa cada columna
- que es ClusterIP
- que es LoadBalancer
- que es EXTERNAL-IP
- por que EXTERNAL-IP puede aparecer como <pending>
- cuanto tiempo es razonable esperar
- como se consume la aplicacion desde Internet
```

---

## Prompt 8 - Self-Healing

```text
Elimine manualmente uno de los Pods del Deployment invoice-processor con:

kubectl delete pod <pod-name>

Explicame paso a paso:

1. que objeto detecta primero la diferencia entre el estado actual y el deseado
2. que es un ReplicaSet y cual es su funcion aqui
3. como trabajan juntos el ReplicaSet y el Deployment
4. cuanto tiempo suele tardar en aparecer el nuevo Pod
5. como verificar que el reemplazo esta funcionando correctamente
```

---

## Prompt 9 - Escalamiento Horizontal

```text
Actualmente tengo:

replicas: 2

Voy a cambiarlo por:

replicas: 5

Explicame:

- que sucede en Kubernetes al aplicar el cambio
- que objetos participan
- como el Service distribuye trafico entre 5 Pods
- que beneficios aporta el escalamiento horizontal
```

---

## Prompt 10 - Rolling Update

```text
Mi Deployment usa actualmente:

<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v1

Voy a actualizarlo a:

<account_id>.dkr.ecr.<region>.amazonaws.com/invoice-processor:v2

Explicame:

- como Kubernetes detecta el cambio
- que estrategia usa por defecto
- cuantos Pods reemplaza a la vez y por que
- como evita downtime visible
- que ocurre con los Pods v1 mientras aparecen los Pods v2
- como verificar el rollout con kubectl rollout status
```

---

## Prompt 11 - Troubleshooting con kubectl logs

```text
Actua como un Kubernetes Engineer Senior.

Explicame como usar kubectl logs para diagnosticar problemas en mis Pods.

Incluye:

- sintaxis basica
- uso de --previous
- uso de -f
- que esperar en logs de FastAPI/Uvicorn
- como diferenciar un error de aplicacion de un problema de infraestructura
- un ejemplo de arranque exitoso de Uvicorn
```

---

## Prompt 12 - Comparacion EKS vs ECS

```text
Compara este laboratorio de Amazon EKS con un laboratorio previo realizado en Amazon ECS.

Explica:

- similitudes del flujo build -> registry -> deploy -> escalar
- diferencias de complejidad
- conceptos de Kubernetes que no existen en ECS
- cuando conviene ECS
- cuando conviene EKS

Usa ejemplos practicos orientados a AWS.
```

---

## Prompt 13 - Cierre Conceptual

```text
Actua como instructor de Kubernetes para principiantes.

Resume lo aprendido en este laboratorio:

- Pod
- ReplicaSet
- Deployment
- Service
- LoadBalancer
- Self-Healing
- Escalamiento
- Rolling Updates
- Amazon ECR
- Amazon EKS

Genera una explicacion breve orientada a una persona que acaba de completar su primer laboratorio de Kubernetes.
```

---

## Criterio de Exito

El uso de Claude Code es exitoso si el alumno logra:

1. generar manifiestos consistentes con el laboratorio
2. revisar el YAML antes del despliegue
3. comprender la estructura de Deployment y Service
4. interpretar salidas reales de `kubectl`
5. usar la IA para diagnostico y comprension, no solo para generacion
