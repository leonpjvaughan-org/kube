# 0. 

## Ensure metallb setup

[README.md](../metallb/README.md)

You should set up your pool and advertisements so that the istio gateway we create later 

## Ensure cert-manager is setup if you are using it (I am and have refrenced it in my gateway annotation)
[README.md](../cert-manager/README.md)

Set up your issuer and secret. You'll need em for the istio gateway to automatically get a cert for the istio gateway.

# 1. Download istioctl

Download istio and copy it somewhere in your system. I use /opt/istio

```shell
curl -L https://istio.io/downloadIstio | sh -
sudo mkdir /opt/istio
cp -r  istio-1.26.0 /opt/istio/
sudo chown -R $USER /opt/istio
```

Add istioctl to your PATH - I use the bashrc file. Also enable bash completion for istioctl. you might neeed to also run `sudo apt install bash-completion` if you don't have it installed.

```shell
echo 'export PATH=/opt/istio/istio-1.26.0/bin:$PATH' >> ~/.bashrc
echo 'source /opt/istio/istio-1.26.0/tools/istioctl.bash' >> ~/.bashrc
source ~/.bashrc
```

# 2. Add Gateway API CRDs

The Gateway APIs do not come installed by default on most Kubernetes clusters. Install the Gateway API CRDs if they are not present:

```shell
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.3.0" | kubectl apply -f -; }
```

# 3. Install Istio

```bash
istioctl install --set profile=default 
```

# 4. Add a gateway

```bash
kubectl apply -f gateway_config_secret.yaml
# check - wait a minute or so. should say programmed and have an ip from the metallb pool you created
kubectl get -f gateway_config_secret.yaml
#debugging
kubectl describe -f gateway_config_secret.yaml
```

```bash
$ kubectl get -f gateway_config_secret.yaml 
NAME                     CLASS   ADDRESS        PROGRAMMED   AGE
mydomain-istio-gw       istio   192.168.5.11   True         32s
```

Also, not a bad time to update your DNS records (I'm just adding it to my local DNS for internal use). I created a wildcard record to point the address assigned to the gateway. Note - metallb has laready been configured to advertise this address.


# 5. test a service with a httproute

In the test dir:

```bash
kubectl apply -f test_app.yaml
# check
kubectl get -f test_app.yaml
#debugging
kubectl describe -f test_app.yaml
```