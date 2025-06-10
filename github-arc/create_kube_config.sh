#!/bin/bash
# filepath: create-runner-kubeconfig.sh

NAMESPACE="arc-runners"
SERVICE_ACCOUNT="github-runner"
SECRET_NAME="github-runner-token"
CLUSTER_NAME="kubernetes"
SERVER_URL="https://192.168.5.201:6443"  # Update with your cluster URL
CONFIG_FILE="github-runner-kubeconfig.yaml"

# Get token and CA cert from secret
TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 -d)
CA_CERT=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')

# Create kubeconfig
cat > $CONFIG_FILE << EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CA_CERT
    server: $SERVER_URL
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    namespace: $NAMESPACE
    user: $SERVICE_ACCOUNT
  name: ${SERVICE_ACCOUNT}-context
current-context: ${SERVICE_ACCOUNT}-context
users:
- name: $SERVICE_ACCOUNT
  user:
    token: $TOKEN
EOF

echo "Kubeconfig created: $CONFIG_FILE"