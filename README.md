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
cd eks-terraform-istio

terraform init

terraform apply
```

## Configure kubectl
```
mkdir -p $HOME/.kube

terraform output kubeconfig > ~/.kube/config

echo "export KUBECONFIG=$KUBECONFIG:$HOME/.kube/config" | tee -a ~/.bashrc

source ~/.bashrc
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

## Deploy the Kubernetes dashboard to your cluster:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

```

## Deploy heapster to enable container cluster monitoring and performance analysis on your cluster:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml

```

## Deploy the influxdb backend for heapster to your cluster

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml

```
## Create the heapster cluster role binding for the dashboard:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml
```

## Create an eks-admin Service Account
```
kubectl apply -f eks-admin-service-account.yaml
```

## Apply the cluster role binding to your cluster
```
kubectl apply -f eks-admin-cluster-role-binding.yaml

```

## Retrieve an authentication token for the eks-admin service account. Copy the <authentication_token> value from the output. You use this token to connect to the dashboard.

```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')

```
* Start the kubectl proxy.

```
kubectl proxy --address='0.0.0.0' --accept-hosts '.*' --port=8082

```

## get cluster ( wait till STATUS will change from pending to running)

```
kubectl get all --namespace=kube-system

```
## install helm
```
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash

```
## install istio 

```
cd $HOME

curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.0.0 sh 

cd istio-1.0.0

echo "export PATH="$PATH:$PWD/bin"" | tee -a ~/.bashrc

source ~/.bashrc

```

## Install with Helm and Tiller via helm install
* If a service account has not already been installed for Tiller, install one:

```
kubectl create -f install/kubernetes/helm/helm-service-account.yaml

```
* Install Tiller on your cluster with the service account:

```
helm init --service-account tiller

```

* Istio has extended Kubernetes via Custom Resource Definitions (CRD). Deploy the extensions by applying crds.yaml.

```

kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml -n istio-system

```

* Install Istio:

```
helm install install/kubernetes/helm/istio --name istio --namespace istio-system --set global.configValidation=false

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

kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml)

kubectl get pods

```

* wait untill STATUS become running

```
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

```

* get ingress load balencer ip 

```
kubectl describe svc istio-ingressgateway -n istio-system

```

* loadbalencer ip  http://sfdbjbjbfjgkjsdhfsdhfdf.us-east-1.elb.amazonaws.com , change it as per ip address

```
http://sfdbjbjbfjgkjsdhfsdhfdf.us-east-1.elb.amazonaws.com/productpage

```

## Visualise Cluster using Weave Scope

* visit aws load balencer security group and open port 4040 , open to world


```
kubectl create -f 'https://cloud.weave.works/launch/k8s/weavescope.yaml'

kubectl get pods -n weave

pod=$(kubectl get pod -n weave --selector=name=weave-scope-app -o jsonpath={.items..metadata.name})

kubectl expose pod $pod -n weave --type=LoadBalancer --port=4040 --target-port=4040

```

* loadbalencer ip  http://hfkdsfhdkjhfsdfhskdgkdf.us-east-1.elb.amazonaws.com , change it as per ip address

* View Scope on port 4040 at http://hfkdsfhdkjhfsdfhskdgkdf.us-east-1.elb.amazonaws.com:4000

## update stack if somthing problem

```
helm upgrade --wait \
             --set global.configValidation=false \
             istio \
             install/kubernetes/helm/istio
```
## Destroy
Make sure all the resources created by Kubernetes are removed (LoadBalancers, Security groups), and issue

```
terraform destroy
```