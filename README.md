# Cats 🐱

A minimal Sinatra-based web app that returns a URL for a random cat picture on its `/` endpoint.

## Overview

This project includes the infrastructure-as-code setup using **Terraform** to deploy the application on **Azure Kubernetes Service (AKS)** with a **containerized Ruby app**, leveraging **Azure Container Registry (ACR)** for image storage and **GitHub Actions** for CI/CD.

The deployment is designed for **zero downtime** using Kubernetes' **rolling update strategy**, autoscaling, health probes, and load balancing.

---

## Application Enhancements (Without Changing Core Functionality)

/health Endpoint (Added to lib/cats.rb):
get '/health' do
  content_type :json
  { status: 'healthy', version: ENV['APP_VERSION'] || '1.0.0' }.to_json
end

This allows the addition of probes in the deployment manifest files where a readiness probe helps to check /health endpoint every 5 seconds to determine when the pod can receive traffic.Also, a liveness probe that checks if application is still running.

## 🚀 Azure Infrastructure Setup (Terraform)

Infrastructure is defined in the `/Infrastructure` folder using **Terraform**.

### ✅ What it sets up

- A **Resource Group** in Azure (`cats-app-rg`)
- An **Azure Container Registry** (`catsacr<hash>`) to store Docker images
- An **AKS Cluster** (`cats-aks`) with:
  - System-assigned managed identity
  - Auto-scaling node pool
  - Standard load balancer for public access
- A **Role Assignment** that allows the AKS cluster to pull images from ACR

### 💻 How to deploy the infrastructure using continuous Deployment (GitHub Actions)

Prerequisities:
create a service principal that will be used for the login step in the pipeline:
az ad sp create-for-rbac --name "CatsAppDeploy" --role contributor   --scopes /subscriptions/<subscription-id>  --sdk-auth

assign the service principal a user access adminisrtator role and contributor role at the subscription level
az role assignment create --assignee <client-id> --role "Contributor" --scope /subscriptions/<subscription-id>  && \
az role assignment create --assignee <client-id> --role "User Access Administrator" --scope /subscriptions/<subscription-id> 

Secrets management: The login credentials for the service principal(AZURE_CREDENTIALS) will be stored in Github secrets. The following steps are used:
On GitHub, navigate to the main page of the repository.

Under your repository name, click  Settings. If you cannot see the "Settings" tab, select the  dropdown menu, then click Settings.

Screenshot of a repository header showing the tabs. The "Settings" tab is highlighted by a dark orange outline.
In the "Security" section of the sidebar, select  Secrets and variables, then click Actions.

Click the Secrets tab.

Screenshot of the "Actions secrets and variables" page. The "Secrets" tab is outlined in dark orange.
Click New repository secret.

In the Name field, type a name for your secret.

In the Secret field, enter the value for your secret.

Click Add secret.


The .github/workflows/infra-deploy.yml workflow automates:

Initialize and preview changes and apply using terraform

 A Successful deployment takes over 4 minutes with minimal manual intervention as shown in the screenshot below:
 ![alt text](image.png)


Deploy the updated image to AKS using kubectl apply

Triggered by:
Manual trigger (workflow_dispatch)
1. Navigate to the infrastructure folder:

   ```bash
   cd Infrastructure

2. Initialize Terraform:

    ```bash
    terraform init

3. Preview the changes:

    ```bash
    terraform plan

4. Apply the changes:

    ```bash
    terraform apply

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

# 4. Deploy
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_name)
kubectl apply -f manifests/namespace.yaml
sed -i "s/\$ACR_NAME/$ACR_NAME/g" manifests/deployment.yaml
sed -i "s/\$TAG/1.0.0/g" manifests/deployment.yaml
kubectl apply -f manifests/

Automate For Version 2.0.1 Upgrade:

# 1. Update version in .bumpversion.cfg
# 2. Commit and tag
git commit -am "Prepare v2.0.1 release"
git tag v2.0.1
git push origin v2.0.1

# Pipeline automatically:
# - Builds new image
# - Pushes to ACR
# - Updates deployment with zero downtime

# OR manually:
kubectl set image deployment/cats-app cats-app=$ACR_NAME.azurecr.io/cats-app:2.0.1 -n cats-prod
kubectl rollout status deployment/cats-app -n cats-prod

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
💬 Example Output

curl https://<external-ip>/
# => { "url": "http://25.media.tumblr.com/..." }


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