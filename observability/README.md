# Observability

- loki for logs
- grafana for graphs
- mimir for metrics
- tempo for traces
- pyroscope for profiling
- alloy for collection

## setup

Grafana provides and lgtm distributed helm chart that can be used to deploy all observability components in a single command.

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm search repo grafana
```

## Create the observability namespace

```bash
kubectl create namespace observability
```

## Install Grafana

See [Grafana](./grafana/README.md) for details on how to install Grafana with OIDC authentication and sidecar configmap configuration.

