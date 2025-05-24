# Keycloak

Keycloak is an open-source identity and access management solution. It provides features such as single sign-on (SSO), identity brokering, user federation, and social login.

# Installation of Keycloak operator with OLM


I am going to use the OLM (Operator Lifecycle Manager) to install Keycloak.

see installation instructions [here](../olm/README.md).

### namespace
Create the Keycloak namespace
```shell
kubectl apply -f kc-namespace.yaml
```


### OLM Operator Group

```shell
# ensure olm operator group (for the keycloak namespace) is created
kubectl apply -f olm-op-grp.yaml
```

### Subscription
```yaml
kubectl apply -f kc-olm-sub.yaml
```

### Install Plan

You should now see install plans
```shell
kubectl get installplans -n keycloak
NAMESPACE   NAME            CSV                         APPROVAL   APPROVED
keycloak    <installplan-name>   keycloak-operator.v26.2.4   Manual     false
```
Approve the install plan
```shell
kubectl patch installplan <installplan-name> -n keycloak --type merge -p '{"spec":{"approved":true}}'
```

Check the status of the Keycloak operator
```shell
kubectl get installplans -A
NAMESPACE   NAME            CSV                         APPROVAL   APPROVED
keycloak    <installplan-name>   keycloak-operator.v26.2.4   Manual     true
```

# Installation of keycloak with Keycloak operator

## Postgres

Create some secrets for the Postgres database
```yaml
# kc-pg-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: kc-pg-secret
  namespace: keycloak
type: Opaque
data:
  postgres-password: <insert-password>
  postgres-username: <insert-username>
```
Values must be base64 encoded (using data instead of stringdata), you can use the following command to encode them:
```bash
echo -n '<insert-username>' | base64
echo -n '<insert-password>' | base64
```

Create the secret in the keycloak namespace
```bash
kubectl apply -f kc-pg-secret.yaml
```

Now you can create the Postgres database using the Keycloak operator.

```shell
kubectl apply -f kc-pg.yaml
```

## Keycloak

Create the Keycloak custom resource
```shell
kubectl apply -f kc.yaml
```

```yaml
# kc.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: kc-mydomain-cert
  namespace: keycloak
spec:
  secretName: kc-mydomain-cert
  issuerRef:
    name: cf-issuer-cm
    kind: ClusterIssuer
  dnsNames:
  - "*.mydomain.com"
  - "mydomain.com"
---
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak
  namespace: keycloak
spec:
  instances: 1
  db:
    vendor: postgres
    host: kc-pg-svc
    database: keycloak
    usernameSecret:
      name: kc-pg-secret
      key: postgres-username
    passwordSecret:
      name: kc-pg-secret
      key: postgres-password
  hostname:
    hostname: keycloak.mydomain.com
    strict: false
  http:
    httpEnabled: true  # Enable HTTP since TLS is terminated at the gateway
  proxy:
    headers: xforwarded
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: keycloak-httproute  # Replace with your desired name
  namespace: keycloak
spec:
  parentRefs:
    - name: mydomain-istio-gw  # Replace with your gateway name
      namespace: default  # dont forget this
      sectionName: web
  hostnames:
    - "keycloak.mydomain.com" # Replace with your domain
  rules:
    - filters:
        - type: RequestRedirect
          requestRedirect:
            scheme: https
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: keycloak-httpsroute
  namespace: keycloak
spec:
  parentRefs:
    - name: mydomain-istio-gw  # Replace with your gateway name
      namespace: default  # dont forget this
      sectionName: websecure
  hostnames:
    - "keycloak.mydomain.com" # Replace with your domain
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: keycloak-service  # Replace with your service name - `kubectl get svc -n keycloak`
          namespace: keycloak
          port: 8080  # Changed from 8443 to 8080 (HTTP port)
```


## Check Keycloak

Try to access Keycloak at `https://keycloak.mydomain.com`. You should see the Keycloak login page.

The username and password for the temporary admin user can be obtained from the commands below. This user is created automatically by the Keycloak operator during the initial setup.
```bash
kubectl get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.username}' | base64 -d
kubectl get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.password}' | base64 -d
```

Note keycloak-initial-admin comes from the keycloak cr name with the suffix `-initial-admin`. If you change the name of the Keycloak custom resource, you will need to adjust the secret name accordingly.

```yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak  # here
```

# Potential issues

If you end up deleting and recreating the Keycloak custom resource, you may encounter issues with the password that was set for the initial admin user. This is because the Keycloak operator does not automatically recreate the initial admin user if it already exists. 

I found it easier to delete the postgres database (and the persistent volume claim) and recreate the Keycloak custom resource. This will ensure that the initial admin user is recreated with a new password.

```bash
kubectl delete -f kc-pg.yaml
kubectl delete -f kc.yaml
# get the name of the persistent volume claim
kubectl get pvc -n keycloak
# patch the persistent volume claim to remove the finalizer -allowing it to be deleted
kubectl patch pvc {PVC_NAME} -n keycloak -p '{"metadata":{"finalizers":null}}'
kubectl delete pvc {PVC_NAME} -n keycloak
```

Then recreate the Postgres database and Keycloak custom resource as described above.