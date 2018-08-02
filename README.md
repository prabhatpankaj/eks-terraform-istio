## create ubuntu instence with default vpc , security group and .pem key

## ogin to instance and run these commands 

```
curl -sL https://raw.githubusercontent.com/prabhatpankaj/ubuntustarter/master/initial.sh | sh

sudo apt-get install unzip python-pip -y

sudo pip install awscli boto boto3

```
## configure aws cli

```
aws configure
```
## install Terraform
```
wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip

unzip terraform_0.11.7_linux_amd64.zip

chmod +x ./terraform

sudo mv ./terraform /usr/local/bin/

```

## Setting up AWS EKS (Hosted Kubernetes)

See https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html for full guide


## Download and install kubectl
```
curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/linux/amd64/kubectl

chmod +x ./kubectl

sudo mv ./kubectl /usr/local/bin/kubectl

```

## Download the aws-iam-authenticator
```
curl -o heptio-authenticator-aws https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/linux/amd64/heptio-authenticator-aws

chmod +x ./heptio-authenticator-aws

sudo mv ./heptio-authenticator-aws /usr/local/bin/heptio-authenticator-aws

```

## Modify providers.tf

Choose your region. EKS is not available in every region, use the Region Table to check whether your region is supported: https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/

Make changes in providers.tf accordingly (region, optionally profile)

## Terraform apply
```
cd eks-project

terraform init

terraform apply
```

## Configure kubectl
```
mkdir -p $HOME/.kube

terraform output kubeconfig > ~/.kube/config

echo "export KUBECONFIG=$KUBECONFIG:$HOME/.kube/config" | tee -a ~/.bashrc


```

## Test your configuration.
```
kubectl get svc

```

## Configure config-map-auth-aws
```
terraform output config-map-aws-auth > config-map-aws-auth.yaml

kubectl apply -f config-map-aws-auth.yaml
```

## See nodes coming up ( wait untill STATUS become Ready)
```
kubectl get nodes
```
## create hello-world application
```
kubectl run helloworld --image=k8s.gcr.io/echoserver:1.4 --port=8080

kubectl get deployments

kubectl get pods

kubectl expose deployment helloworld --type=LoadBalancer

kubectl describe services helloworld

```

## Install networking using WeaveWorks

```
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

```
## get cluster ( wait till STATUS will change from pending to running)

```
kubectl get all --namespace=kube-system

```
## install helm
```
curl -Lo /tmp/helm-linux-amd64.tar.gz https://kubernetes-helm.storage.googleapis.com/helm-v2.9.0-linux-amd64.tar.gz
tar -xvf /tmp/helm-linux-amd64.tar.gz -C /tmp/
chmod +x  /tmp/linux-amd64/helm && sudo mv /tmp/linux-amd64/helm /usr/local/bin/

```
## install istio 

```
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.0.0 sh 

cd istio-1.0.0

echo "export PATH="$PATH:$PWD/bin"" | tee -a ~/.bashrc

source ~/.bashrc

```
## Configure Istio CRD
* Istio has extended Kubernetes via Custom Resource Definitions (CRD). Deploy the extensions by applying crds.yaml.

```

kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system

```
## Install Istio with default mutual TLS authentication
* To Install Istio and enforce mutual TLS authentication by default, use the yaml istio-demo-auth.yaml

```
kubectl apply -f install/kubernetes/istio-demo-auth.yaml

```
## Verify istio (wait untill STATUS become Running/Completed )
```
kubectl get pods -n istio-system
kubectl get svc -n istio-system

```

* Istio Architecture
The previous step deployed the Istio Pilot, Mixer, Ingress-Controller, and Egress-Controller, and the Istio CA (Certificate Authority).

* Pilot - 
Responsible for configuring the Envoy and Mixer at runtime.

* Envoy - 
Sidecar proxies per microservice to handle ingress/egress traffic between services in the cluster and from a service to external services. The proxies form a secure microservice mesh providing a rich set of functions like discovery, rich layer-7 routing, circuit breakers, policy enforcement and telemetry recording/reporting functions.

* Mixer - 
Create a portability layer on top of infrastructure backends. Enforce policies such as ACLs, rate limits, quotas, authentication, request tracing and telemetry collection at an infrastructure level.

* Ingress/Egress - 
Configure path based routing.

* Istio CA - 
Secures service to service communication over TLS. Providing a key management system to automate key and certificate generation, distribution, rotation, and revocation

* The overall architecture is shown below.

![](/images/istio-arch.png)

## install sample project (https://github.com/istio/istio/tree/master/samples/bookinfo)

* When deploying an application that will be extended via Istio, the Kubernetes YAML definitions are extended via kube-inject. This will configure the services proxy sidecar (Envoy), Mixers, Certificates and Init Containers.
```
cd istio-1.0.0

kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml)

kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

kubectl get pods
```

## Destroy
Make sure all the resources created by Kubernetes are removed (LoadBalancers, Security groups), and issue

```
terraform destroy
```
