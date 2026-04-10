# FastAPI Demo App - Azure CI/CD to AWS EC2

A beginner-friendly FastAPI application demonstrating deployment to AWS EC2 using **Azure DevOps CI/CD pipelines** with **Docker** and **Kubernetes** concepts.

## 📁 Project Structure

```
fastapi-demo-app/
├── app/
│   └── main.py                 # FastAPI application
├── k8s/                        # Kubernetes manifests
│   ├── deployment.yaml         # Pod deployment config
│   ├── service.yaml            # Service exposure config
│   ├── namespace.yaml          # Namespace definition
│   └── configmap.yaml          # Configuration data
├── Dockerfile                  # Docker build config
├── docker-compose.yml          # Local Docker Compose
├── azure-pipelines.yml         # Azure CI/CD - Docker deployment
├── azure-pipelines-k8s.yml     # Azure CI/CD - Kubernetes deployment
├── deploy.sh                   # EC2 setup script
├── nginx.conf                  # Nginx reverse proxy
├── requirements.txt            # Python dependencies
└── README.md                   # This file
```

## 🚀 Quick Start (Local Development)

### Run with Docker
```bash
# Build and run
docker-compose up --build

# Access: http://localhost:8000
```

### Run without Docker
```bash
pip install -r requirements.txt
cd app
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Available Endpoints
| Endpoint | Description |
|----------|-------------|
| `/` | Home page with app info |
| `/health` | Health check (JSON) |
| `/api/info` | Application info (JSON) |
| `/docs` | Swagger UI documentation |
| `/redoc` | ReDoc documentation |

---

## ☁️ AWS EC2 Setup

### Step 1: Launch EC2 Instance

1. **Go to AWS Console** → EC2 → Launch Instance
2. **Configure:**
   - **Name:** `fastapi-demo-app`
   - **AMI:** Amazon Linux 2023 or Ubuntu 22.04 LTS
   - **Instance Type:** `t2.micro` (Free Tier) or `t3.small`
   - **Key Pair:** Create new or select existing (.pem file)
   
3. **Security Group Rules:**
   | Type | Port | Source |
   |------|------|--------|
   | SSH | 22 | My IP |
   | HTTP | 80 | Anywhere |
   | Custom TCP | 8000 | Anywhere |
   | Custom TCP | 30080 | Anywhere (for K8s NodePort) |

4. **Launch** and note the **Public IP Address**

### Step 2: Connect to EC2

```bash
# Make key file secure
chmod 400 your-key.pem

# Connect (Amazon Linux)
ssh -i "your-key.pem" ec2-user@<EC2-PUBLIC-IP>

# Connect (Ubuntu)
ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>
```

### Step 3: Install Docker & Kubernetes Tools

Once connected to EC2, copy the project files and run:

```bash
# Clone your repo (after pushing to Git)
git clone <your-repo-url>
cd fastapi-demo-app

# Run the setup script
chmod +x deploy.sh
./deploy.sh

# Choose option 2 for Docker + Kubernetes or option 1 for Docker only
```

---

## 🔵 Azure DevOps CI/CD Setup

### Prerequisites
1. Azure DevOps account (free at [dev.azure.com](https://dev.azure.com))
2. AWS EC2 instance running with Docker installed
3. Your code in Azure Repos or GitHub

### Step 1: Create Azure DevOps Project

1. Go to [dev.azure.com](https://dev.azure.com)
2. Create a new project: `FastAPI-Demo-App`
3. Go to **Repos** → Import or push your code

### Step 2: Create SSH Service Connection

This allows Azure DevOps to connect to your EC2:

1. Go to **Project Settings** → **Service connections**
2. Click **New service connection** → **SSH**
3. Configure:
   ```
   Host: <EC2-PUBLIC-IP>
   Port: 22
   Username: ec2-user (or ubuntu)
   Private Key: <paste contents of your .pem file>
   Service connection name: EC2-SSH-Connection
   ```
4. Save

### Step 3: Configure Pipeline Variables

1. Go to **Pipelines** → **Library** → **+ Variable group**
2. Name: `EC2-Deployment-Variables`
3. Add variables:
   | Variable | Value | Secret |
   |----------|-------|--------|
   | `EC2_HOST` | Your EC2 Public IP | No |
   | `EC2_USER` | ec2-user or ubuntu | No |
   | `SSH_SERVICE_CONNECTION` | EC2-SSH-Connection | No |

### Step 4: Create Pipeline

1. Go to **Pipelines** → **Create Pipeline**
2. Select your repo location (Azure Repos/GitHub)
3. Choose **Existing Azure Pipelines YAML file**
4. Select:
   - `/azure-pipelines.yml` for Docker deployment
   - `/azure-pipelines-k8s.yml` for Kubernetes deployment
5. Click **Run**

### Step 5: Create Environment (for approvals)

1. Go to **Pipelines** → **Environments**
2. Create new environment: `production`
3. (Optional) Add approval gates for manual approval before deployment

---

## 🐳 Docker Deployment Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Azure DevOps Pipeline                         │
├─────────────────────────────────────────────────────────────────────┤
│  BUILD STAGE                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │ Checkout    │ →  │ Build Docker│ →  │ Save Image  │             │
│  │ Code        │    │ Image       │    │ as Artifact │             │
│  └─────────────┘    └─────────────┘    └─────────────┘             │
├─────────────────────────────────────────────────────────────────────┤
│  DEPLOY STAGE                                                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐             │
│  │ Download    │ →  │ SSH to EC2  │ →  │ Load & Run  │             │
│  │ Artifact    │    │ Copy Image  │    │ Container   │             │
│  └─────────────┘    └─────────────┘    └─────────────┘             │
├─────────────────────────────────────────────────────────────────────┤
│  VERIFY STAGE                                                        │
│  ┌─────────────┐                                                    │
│  │ Health      │ →  ✓ Deployment Complete!                          │
│  │ Check       │                                                    │
│  └─────────────┘                                                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ☸️ Kubernetes Deployment Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Kubernetes on EC2 (Minikube)                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                     MINIKUBE CLUSTER                          │  │
│  │  ┌─────────────┐  ┌─────────────┐                           │  │
│  │  │  POD 1      │  │  POD 2      │   (replicas: 2)          │  │
│  │  │  ┌───────┐  │  │  ┌───────┐  │                           │  │
│  │  │  │FastAPI│  │  │  │FastAPI│  │                           │  │
│  │  │  │:8000  │  │  │  │:8000  │  │                           │  │
│  │  │  └───────┘  │  │  └───────┘  │                           │  │
│  │  └─────────────┘  └─────────────┘                           │  │
│  │         │                │                                    │  │
│  │         └────────┬───────┘                                   │  │
│  │                  ▼                                            │  │
│  │  ┌─────────────────────────────┐                            │  │
│  │  │     SERVICE (NodePort)       │                            │  │
│  │  │        Port: 30080          │                            │  │
│  │  └─────────────────────────────┘                            │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                              │                                      │
│                              ▼                                      │
│                    http://<EC2-IP>:30080                           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📚 Key Concepts for Beginners

### Docker Concepts
| Concept | Description |
|---------|-------------|
| **Dockerfile** | Recipe to build your app into a container image |
| **Image** | Packaged app with all dependencies (like a snapshot) |
| **Container** | Running instance of an image |
| **docker-compose** | Tool to run multi-container apps |

### Kubernetes Concepts
| Concept | Description |
|---------|-------------|
| **Pod** | Smallest deployable unit (contains containers) |
| **Deployment** | Manages pod replicas and updates |
| **Service** | Exposes pods to network traffic |
| **Namespace** | Virtual cluster for organizing resources |
| **ConfigMap** | Stores configuration data |

### CI/CD Concepts
| Concept | Description |
|---------|-------------|
| **CI (Continuous Integration)** | Automatically build & test on code push |
| **CD (Continuous Deployment)** | Automatically deploy after successful build |
| **Pipeline** | Automated workflow (Build → Test → Deploy) |
| **Artifact** | Build output (Docker image, files) |

---

## 🔧 Useful Commands

### Docker Commands
```bash
docker build -t fastapi-demo-app .    # Build image
docker-compose up -d                   # Start containers (detached)
docker-compose down                    # Stop containers
docker-compose logs -f                 # View logs
docker ps                              # List running containers
docker exec -it <container> /bin/bash  # Shell into container
```

### Kubernetes Commands
```bash
kubectl get pods                       # List pods
kubectl get services                   # List services
kubectl get deployments                # List deployments
kubectl logs <pod-name>                # View pod logs
kubectl describe pod <pod-name>        # Pod details
kubectl apply -f k8s/                  # Apply all manifests
kubectl delete -f k8s/                 # Delete all resources
kubectl rollout restart deployment/<name>  # Restart deployment
```

### Minikube Commands
```bash
minikube start                         # Start cluster
minikube stop                          # Stop cluster
minikube dashboard                     # Open web dashboard
minikube service <name> --url          # Get service URL
eval $(minikube docker-env)            # Use Minikube's Docker
```

---

## ❓ Troubleshooting

### Pipeline Fails at SSH Step
- Verify EC2 security group allows port 22 from Azure DevOps IPs
- Check SSH service connection credentials
- Ensure EC2 instance is running

### Container Won't Start
```bash
# Check container logs
docker logs fastapi-demo-app

# Check if port is in use
sudo lsof -i :8000
```

### Kubernetes Pod Stuck in Pending
```bash
kubectl describe pod <pod-name>
# Check Events section for errors
```

### Health Check Fails
```bash
# Test locally on EC2
curl http://localhost:8000/health
```

---

## 📝 License

This project is for learning purposes. Feel free to use and modify!
sudo apt install docker.io docker-compose -y

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Log out and log back in
exit
```

### Step 4: Deploy the Application

**Option A: Clone from Git (Recommended)**
```bash
# Install git
sudo dnf install git -y   # Amazon Linux
sudo apt install git -y   # Ubuntu

# Clone your repository
git clone <your-repo-url> fastapi-login-app
cd fastapi-login-app

# Build and run
docker-compose up -d --build
```

**Option B: Transfer files using SCP**
```bash
# From your local machine
scp -i "your-key.pem" -r ./fastapi-login-app ec2-user@<EC2-PUBLIC-IP>:~/

# On EC2
cd fastapi-login-app
docker-compose up -d --build
```

### Step 5: Verify Deployment

```bash
# Check container status
docker ps

# Check logs
docker logs fastapi-login-app

# Test health endpoint
curl http://localhost:8000/health
```

### Step 6: Access Your Application

Open in browser: `http://<EC2-PUBLIC-IP>:8000`

---

## Production Setup (Optional)

### Run with Nginx Reverse Proxy
```bash
docker-compose --profile production up -d --build
```
Access at: `http://<EC2-PUBLIC-IP>` (port 80)

### Configure Security Group for Production
- Remove port 8000 access
- Keep only ports 80 (HTTP) and 443 (HTTPS)

### Set up HTTPS with Let's Encrypt
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx -y

# Get certificate (requires domain name)
sudo certbot --nginx -d yourdomain.com
```

---

## Useful Commands

```bash
# View running containers
docker ps

# View logs
docker-compose logs -f

# Stop containers
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# Remove all containers and images
docker-compose down --rmi all
```

## Troubleshooting

### Container won't start
```bash
docker-compose logs web
```

### Port already in use
```bash
sudo lsof -i :8000
sudo kill -9 <PID>
```

### Permission denied on Docker
```bash
sudo usermod -aG docker $USER
# Log out and log back in
```

---

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Redirects to login |
| `/login` | GET | Login page |
| `/login` | POST | Process login |
| `/welcome` | GET | Welcome page |
| `/api/login` | POST | API login endpoint |
| `/health` | GET | Health check |

### API Usage Example
```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username": "demo", "password": "demo"}'
```

Response:
```json
{"status": "success", "message": "Welcome demo!"}
```
