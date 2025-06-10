# GitHub Actions Runners in Kubernetes


# Pre-installation

## runner namespace

Create a namespace for the GitHub Actions runners.
```bash
kubectl create namespace arc-runners
```

## RBAC
Create a role with permissions we want our runners to have in the cluster. This role will be used by the runners to interact with Kubernetes resources i.e. to create pods, services, etc.
```bash
kubectl apply -f rbac/runner-role.yaml
```

The github runner service account is later used in the chart values file to give the runners permissions to interact with the cluster.

## Secret for GitHub APP

2 options are available to authenticate the runners with GitHub:
1. **GitHub App**: This is the recommended way to authenticate runners with GitHub. You need to create a GitHub App and generate a private key.
2. **Personal Access Token**: This is a less secure option but can be used if you don't want to create a GitHub App.

See the [GitHub documentation](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/authenticating-to-the-github-api#authenticating-arc-with-a-github-app) for instructions on how to create a secret for the GitHub App or Personal Access Token.

Create a secret in the `arc-runners` namespace with the GitHub App credentials. Replace the values with your actual GitHub App credentials.

```bash
kubectl apply -f secrets/github-actions-secret.yaml
```


```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-actions-secret
  namespace: arc-runners  # in the same namespace as the runners
type: Opaque
stringData:
  github_app_id: "123456"
  github_app_installation_id: "654321"
  github_app_private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    [Your actual private key content]
    -----END RSA PRIVATE KEY-----
```

## local path provisioner

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml
```

# Installation
First, add the ARC Helm repository:

```bash
helm repo add arc https://actions-runner-controller.github.io/actions-runner-controller
```

## ARC

Then, install the ARC chart:

```bash
helm upgrade --install arc --namespace "arc-systems" --create-namespace oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller --values controller/values.yaml
```

## ARC set

```bash
helm upgrade --install "arc-runner-set" --namespace "arc-runners" --create-namespace oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set --values scale-set/values.yaml
```

# Checking the installation

Go to https://github.com/organizations/<org>/settings/actions/runners

You should see the runners registered in the GitHub Actions settings for your organization.