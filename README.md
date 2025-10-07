# INFRAC

Proyecto de Infraestructura como Código (IaC) para automatización y gestión de recursos en la nube.

## Autores

- **Liu Dai Yan**
- **De Lama Céspedes Sergio**

---
## Arquitectura General

El proyecto INFRAC implementa una arquitectura modular basada en **Infraestructura como Código (IaC)**, permitiendo la gestión eficiente de recursos en la nube mediante el uso principal de **Terraform**. La solución está orientada a facilitar la provisión, configuración y administración de servicios en la nube, manteniendo el código fuente centralizado y versionado.

## Estructura del Proyecto
La estructura del repositorio está organizada de la siguiente manera:

## DIAGRAMA
![alt text](image.png)

```
INFRAC/
├── frontend/
│   └── lambda/
├── inf/
│   ├── apigateway.tf
│   ├── cloudwatch.tf
│   ├── iam-lambda.tf
│   ├── lambda-api.tf
│   ├── lambda-worker.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── rds.tf
│   ├── s3-cloudfront.tf
│   ├── ses.tf
│   ├── sqs.tf
│   ├── variables.tf
│   ├── vcp.tf
```
