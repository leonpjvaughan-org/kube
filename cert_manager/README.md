# info

## Setup instructions for Cert Manager

Add the helm repo
```bash
helm repo add jetstack https://charts.jetstack.io --force-update
```

Install cert-manager
```bash
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.2 \
  --values values.yaml
```

Deploy the Cloudflare issuer. Update the email and create the secret required for the issuer.

```bash
kubectl apply -f cloudflare_issuer.yaml
```

When I want to use this certificate, for example with Traefik gateway, I will do the following:
```yaml
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: domain-gateway #-----------
  annotations:
    # Traefik specific annotations
    cert-manager.io/issuer: "cloudflare-issuer-cert-manager" # should force the creation of the certificate
spec:
  gatewayClassName: traefik
  listeners:
    - name: websecure
      port: 8443
      protocol: HTTPS
      hostname: "*.domain.example.com"
      tls:
        certificateRefs:
          - name: wildcard-domain-tls-cert  
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: domain
spec:
  parentRefs:
    - name: domain-gateway  #-----------
  hostnames:
    - domain.example.com
  rules:
    - matches:
        - path:
            type: Exact
            value: /

      backendRefs:
        - name: domain-service  # The name of the service being routed to
          port: 80
          weight: 1
```