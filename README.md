# About

This repo is a collection of Kubernetes resources and configurations for my homelab. It includes various Kubernetes manifests, Helm charts, and instructions for deploying and managing applications in a Kubernetes cluster.

# Important reources

1. [nfs](./nfs/README.md) - NFS server setup for persistent volume claims. Other storage classes can be used, but I have a simple NFS server running in my homelab.
2. [metallb](./metallb/README.md) - MetalLB setup for load balancing in self-hosted Kubernetes clusters. This is also needed for north-south traffic routing. We need to be able to advertise IP addresses to the network. It also plays nicely with the gateway API by assigning and IP address the the gateway.One can then set up a DNS record for the IP address and use it to access services in the cluster. 
3. [istio](./istio/README.md) - I am using this as my GatewayClass.
    - Routing summary:
      - My gateway is configured with a wildcard hostname (and a wildcard tls cert via cert-manager). 
      - Metallb assigns the gateway an IP address from the pool. 
      - I have set up a wildcard DNS record on my DNS server for the assigned IP. 
      - I've set up HTTPRoute resources (which use my wildcard gateway) to link hostnames to services in the cluster.
4. [cert-manager](./cert_manager/README.md) - Cert-manager setup for managing TLS certificates on the cluster. This includes a Cloudflare issuer for obtaining wildcard certificates. The gateway api references the cloudflare issue in its configuration which allows it to automatically obtain and renew certificates for the services that use the gateway.
5. [olm](./olm/README.md) - Operator Lifecycle Manager (OLM) setup for managing operators in the cluster. This is useful for installing and managing operators like Keycloak.
6. [keycloak](./keycloak/README.md) - Keycloak for iam. I am using this as my cluster OIDC provider.
7. [kubernetes Dashboard](./kubernetes_dashboard/README.md) - Kubernetes dashboard setup for managing the cluster. This is useful for monitoring and managing the cluster resources.
8. [Velero](./velero/README.md) - Velero setup for backing up and restoring Kubernetes resources. This is useful for disaster recovery and backup of the cluster resources.
