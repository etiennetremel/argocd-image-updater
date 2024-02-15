# Argo CD Image Updater

Just a merge of https://github.com/argoproj-labs/argocd-image-updater/pull/586
so we can have a working argocd-image-updater with azure workload identity!

> [!CAUTION]
> Due to the introduction of the Azure CLI, the image size is insanely big:
> 2.62Gb. Without the Azure CLI, the image size is 281Mb.
> There is probably a better way to do this using their rest API :)


## Getting started with Azure Workload Identity

```
docker pull ghcr.io/etiennetremel/argocd-image-updater
```

Include a auth configmap with the script below and patch the service account
and deployment to match the Workload Identity:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-image-updater-auth
data:
  auth.sh: |
    #!/bin/sh

    az login -o none \
      --service-principal \
      -u "$AZURE_CLIENT_ID" \
      -t "$AZURE_TENANT_ID" \
      --federated-token "$(cat $AZURE_FEDERATED_TOKEN_FILE)"

    TOKEN=$(az acr login \
      --name $ACR_NAME \
      --expose-token \
      --output tsv \
      --query accessToken \
      --only-show-errors)

    echo "00000000-0000-0000-0000-000000000000:$TOKEN"
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-image-updater
  labels:
    azure.workload.identity/use: "true"
  annotations:
    azure.workload.identity/client-id: placeholder
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-image-updater
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      containers:
        - name: argocd-image-updater
          image: ghcr.io/etiennetremel/argocd-image-updater:latest@sha256:8910dfd72a85183de43e48eac5e2c257e1b6ca44d609604cd3c88de91ea029bf
          env:
            - name: ACR_NAME
              value: placeholder
          volumeMounts:
            - mountPath: /app/auth
              name: auth
      volumes:
        - configMap:
            name: argocd-image-updater-auth
          name: auth
```
