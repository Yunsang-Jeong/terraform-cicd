# Overview

Terraform CICD에 사용할 수있는 예제 코드입니다.

# How to manual provisioning

## Terraform init

```
terraform init -input=false -backend-config=backend.tfvars
```

## Terraform workspace

```
WORKSPACE="dev"
terraform workspace new $WORKSPACE && terraform workspace select $WORKSPACE || terraform workspace select $WORKSPACE
```