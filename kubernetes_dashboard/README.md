# Info

## Setup instructions for Kubernetes Dashboard

Ensure Helm is installed:
```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

Add the kubernetes-dashboard helm repository:
```bash
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
```

Install the chart:
```bash
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
```


Create service account, a role with permissions, and a role binding to the service account:


In the rbac directory, create a user
```bash
kubectl apply -f dashboard_service_account.yaml 
```

An existing role (to view `kubectl get clusterrole`) is available with the required permissions.

Bind the ClusterRole cluster-admin to the service account:
```bash
kubectl apply -f dashboard_role_binding.yaml
```

Then get the token for the service account:
```bash
kubectl -n kubernetes-dashboard create token dashboard-user
```

Quickly look at the dashboard:
```bash
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
```

