# Cats 🐱

A minimal Sinatra-based web app that returns a URL for a random cat picture on its `/` endpoint.

## Overview

This project includes the infrastructure-as-code setup using **Terraform** to deploy the application on **Azure Kubernetes Service (AKS)** with a **containerized Ruby app**, leveraging **Azure Container Registry (ACR)** for image storage and **GitHub Actions** for CI/CD.

The deployment is designed for **zero downtime** using Kubernetes' **rolling update strategy**, autoscaling, health probes, and load balancing.

---

## 🚀 Application Enhancements (Without Changing Core Functionality)

### ✅ Added `/health` Endpoint (in `lib/cats.rb`)

```ruby
get '/health' do
  content_type :json
  {
    status: 'healthy',
    version: ENV['APP_VERSION'] || '1.0.0'
  }.to_json
end

📌 Purpose
The /health endpoint was introduced to support Kubernetes probes in the deployment manifest:

Readiness Probe:
Checks the /health endpoint every 5 seconds to determine if the pod is ready to receive traffic.

Liveness Probe:
Monitors the application to ensure it's still running and responsive.

These probes help ensure high availability and resiliency of the application in production environments.

## 🚀 Azure Infrastructure Setup with Terraform

Infrastructure is defined in the `/Infrastructure` folder using **Terraform**.

---

### ✅ What the Setup Includes

- **Resource Group**:  
  - `cats-app-rg`
  
- **Azure Container Registry (ACR)**:  
  - `catsacr<hash>` to store Docker images

- **Azure Kubernetes Service (AKS) Cluster**:  
  - Cluster name: `cats-aks`  
  - System-assigned managed identity  
  - Auto-scaling node pool  
  - Standard Load Balancer for public access

- **Role Assignment**:  
  - Grants the AKS cluster permission to pull images from ACR

---

### 💻 Continuous Deployment via GitHub Actions

#### 🔐 Prerequisites

1. **Create a Service Principal** (for use in the GitHub Actions pipeline):

   ```bash
   az ad sp create-for-rbac \
     --name "CatsAppDeploy" \
     --role contributor \
     --scopes /subscriptions/<subscription-id> \
     --sdk-auth
2. Assign roles to the service principle
az role assignment create \
  --assignee <client-id> \
  --role "Contributor" \
  --scope /subscriptions/<subscription-id>

az role assignment create \
  --assignee <client-id> \
  --role "User Access Administrator" \
  --scope /subscriptions/<subscription-id>

🔐 Secrets Management in GitHub
The service principal credentials is stored as a GitHub Secret (AZURE_CREDENTIALS):

Go to your repository on GitHub.

Navigate to Settings → Secrets and variables → Actions.

Click the Secrets tab.

Click New repository secret.

Provide:

Name: AZURE_CREDENTIALS

Secret: (Paste the output from the az ad sp create-for-rbac command)

Click Add secret.


Deploy the updated image to AKS using kubectl apply

⚙️ CI/CD Workflow
The file .github/workflows/infra-deploy.yml automates the following steps:

Terraform initialization

Plan preview of infrastructure changes

Apply changes with minimal manual intervention

⏱️ A successful deployment typically completes in under 5 minutes.

📸 Example Screenshot
A snapshot of the deployment workflow in action:
![alt text](image-1.png)



🐳 Docker Setup
The app is packaged using a Dockerfile based on the lightweight ruby:2.7-alpine image.

Build and test locally:

docker build -t cats-app .
docker run -p 8000:8000 cats-app
Access via: http://localhost:8000

☸️ Kubernetes Manifests
Located in /manifests, these define how the app runs inside AKS.

Below are the key files:

namespace.yaml: Creates the cats-prod namespace

deployment.yaml: Deploys 3 replicas using a rolling update strategy:

maxSurge: 1: Allows 1 extra pod during updates

maxUnavailable: 0: No pod downtime during updates

service.yaml: Exposes the app via a public LoadBalancer with Azure DNS label

hpa.yaml: Horizontal Pod Autoscaler to scale based on CPU utilization

Health Check
Uses a readinessProbe on /health to ensure pods only receive traffic when ready

deploy the version 1.0.0 on the AKS cluster.

The deployment of version 1.0.0 will be done manually with the steps below:

# 1. Build and push
export ACR_NAME=$(terraform output -raw acr_name)
docker build -t $ACR_NAME.azurecr.io/cats-app:1.0.0 .
az acr login --name $ACR_NAME
docker push $ACR_NAME.azurecr.io/cats-app:1.0.0
The screenshot below shows the image on Azure Container registry
![alt text](image-2.png)

# 4. Deploy
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_name)
kubectl apply -f manifests/namespace.yaml
sed -i "s/\$ACR_NAME/$ACR_NAME/g" manifests/deployment.yaml
sed -i "s/\$TAG/1.0.0/g" manifests/deployment.yaml
kubectl apply -f manifests/

Following the successful deployment of the manifests above, the cats app can be accessed via the Loadbalancer frontend ip
http://128.203.84.44/
![alt text](image-3.png)



Automate For Version 2.0.1 Upgrade:

# 1. Commit and tag
git commit -am "Prepare v2.0.1 release"
git tag v2.0.1
git push origin v2.0.1

# Pipeline automatically:
# - Builds new image
# - Pushes to ACR
# - Updates deployment with zero downtime

The image shows the complete pipeline in github actions



🔁 Zero Downtime Deployment Strategy
Achieved using:

Rolling Updates in the deployment config (no downtime when releasing new versions)

Readiness Probes to delay traffic routing until pods are healthy

Horizontal Pod Autoscaling to automatically adjust based on load

Load Balancer Service to distribute traffic evenly

🔄 Continuous Deployment (GitHub Actions)
The .github/workflows/app-deploy.yml workflow automates:

Build & Push the Docker image to ACR

Deploy the updated image to AKS using kubectl apply

Triggered by:
Manual trigger (workflow_dispatch)

Push to a versioned tag (e.g., v1.0.0)

🔧 Configuration
These ENV variables control the app behavior:

Variable	Default	Description
RACK_ENV	production	Sinatra environment
PORT	8000	App port
WEB_CONCURRENCY	1	Puma worker processes
MAX_THREADS	1	Max threads per Puma process

## ✅ Pros and Cons of Stack Decisions

| Tool/Choice     | Pros                                                                 | Cons                                                  |
|------------------|----------------------------------------------------------------------|--------------------------------------------------------|
| Terraform        | Declarative, modular, widely supported, stateful management         | State file complexity, slower with large infra        |
| AKS              | Fully managed K8s, integrates well with Azure, supports autoscaling | Can be overkill for simple apps, steep learning curve |
| ACR              | Secure image storage, seamless with AKS                             | Extra cost compared to DockerHub                      |
| GitHub Actions   | Native CI/CD, secure secret handling, highly customizable           | Complex matrix workflows can be hard to debug         |
| Docker           | Portable, lightweight, standard container format                    | Layer caching issues on large builds                  |


📂 Directory Structure
.
├── Infrastructure/       # Terraform scripts for Azure infra
├── manifests/            # Kubernetes deployment files
├── .github/workflows/    # GitHub Actions deployment workflow
├── lib/cats.rb           # Sinatra app logic
├── Dockerfile            # Docker image definition
├── config.ru             # Rack config for Puma
├── config/puma.rb        # Puma settings
└── README.md             # This file
📌 Prerequisites
Terraform

Azure CLI

kubectl

Docker

Azure Subscription

🧪 Local Testing

bundle install
bundle exec puma -C config/puma.rb
Then open: http://localhost:8000

📦 Deployment Checklist
 Infrastructure provisioned via Terraform

 App containerized and pushed to ACR

 Kubernetes manifests applied to AKS

 Rolling updates enabled

 Autoscaling and health checks configured

 GitHub Actions automated deploy pipeline

🐾 Made with love for cats.

Let me know if you want a separate `CONTRIBUTING.md` or an architecture diagram