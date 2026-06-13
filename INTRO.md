# LAB-004 — Introducción a Kubernetes

## Propósito del lab

Este laboratorio enseña los conceptos fundamentales de **Kubernetes** usando
un caso realista: desplegar una API (FastAPI, `invoice-processor`) en un
cluster administrado de AWS (EKS), y experimentar en vivo con el
comportamiento que hace a Kubernetes valioso, sin solo leerlo en teoría.

El flujo completo cubre:

1. Publicar una imagen Docker (la "unidad de despliegue")
2. Desplegarla en un cluster real
3. Exponerla al mundo vía Load Balancer
4. Ver **self-healing** (Kubernetes repara solo)
5. Ver **escalamiento** (más tráfico → más réplicas)
6. Ver **rolling update** (actualizar sin downtime)
7. Aprender a destruir todo de forma ordenada (gestión de costos)

Ver [README.md](README.md) para el flujo paso a paso.

## Cómo explicarlo a alguien que nunca vio Kubernetes

Analogía: una **fábrica**.

> Imagina que tienes una fábrica (el **cluster**) con varias máquinas (los
> **nodos**, servidores EC2). Tu producto es una receta empaquetada en una
> caja (la **imagen Docker**) — esa caja tiene todo lo necesario para
> fabricar tu producto sin importar en qué máquina se monte.
>
> Le dices a un **gerente** (Kubernetes / el Deployment): "Quiero que siempre
> haya 2 líneas de producción corriendo esta receta". El gerente:
>
> - Busca espacio libre en las máquinas y monta las líneas (**Pods**).
> - Si una línea se rompe (un Pod muere), el gerente *automáticamente* monta
>   otra para mantener las 2 — **eso es self-healing**, nadie tiene que
>   llamarlo de madrugada.
> - Si le dices "ahora quiero 5 líneas" porque hay más demanda, el gerente
>   las monta sin que tú toques ninguna máquina — **eso es escalamiento**.
> - Si sacas una nueva receta (v2), el gerente reemplaza las líneas *una por
>   una*, nunca todas a la vez, así el cliente nunca nota que la fábrica dejó
>   de producir — **eso es rolling update**.
>
> Y hay un **recepcionista** (el Service / Load Balancer) que recibe los
> pedidos de los clientes y los reparte entre las líneas que estén activas,
> sin que el cliente necesite saber cuántas hay ni dónde están.

## Por qué importa

Antes de Kubernetes, si un servidor se caía a las 3am, alguien tenía que
despertarse y arreglarlo manualmente. Si el tráfico subía, había que
aprovisionar servidores nuevos a mano. Si querías actualizar la app,
normalmente había downtime.

Kubernetes automatiza esas tres cosas — y este lab te las hace *ver con tus
propios ojos* (matando un pod y viéndolo resucitar, cambiando `replicas: 2`
a `5`, etc.) en lugar de solo leerlas.
