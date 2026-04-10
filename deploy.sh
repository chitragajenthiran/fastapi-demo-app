#!/bin/bash
# =============================================================================
# FastAPI Demo App - EC2 Deployment Script
# This script helps beginners deploy with Docker and Kubernetes on AWS EC2
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}=========================================="
    echo -e "$1"
    echo -e "==========================================${NC}\n"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    fi
    echo "Detected OS: $OS"
}

# =============================================================================
# DOCKER INSTALLATION
# =============================================================================
install_docker() {
    print_header "Installing Docker"
    
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed"
        docker --version
        return 0
    fi

    if [ "$OS" = "amzn" ] || [ "$OS" = "amazon" ]; then
        echo "Installing Docker on Amazon Linux..."
        sudo dnf update -y
        sudo dnf install docker git -y
    elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        echo "Installing Docker on Ubuntu/Debian..."
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        print_error "Unsupported OS. Please install Docker manually."
        exit 1
    fi

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    
    print_success "Docker installed successfully!"
}

# =============================================================================
# DOCKER COMPOSE INSTALLATION
# =============================================================================
install_docker_compose() {
    print_header "Installing Docker Compose"
    
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
        print_success "Docker Compose is already installed"
        return 0
    fi

    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker Compose installed successfully!"
}

# =============================================================================
# KUBECTL INSTALLATION
# =============================================================================
install_kubectl() {
    print_header "Installing kubectl (Kubernetes CLI)"
    
    if command -v kubectl &> /dev/null; then
        print_success "kubectl is already installed"
        kubectl version --client --short 2>/dev/null || true
        return 0
    fi

    echo "Downloading kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    print_success "kubectl installed successfully!"
}

# =============================================================================
# MINIKUBE INSTALLATION (Single-node Kubernetes for learning)
# =============================================================================
install_minikube() {
    print_header "Installing Minikube (Local Kubernetes)"
    
    if command -v minikube &> /dev/null; then
        print_success "Minikube is already installed"
        return 0
    fi

    echo "Downloading Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    
    print_success "Minikube installed successfully!"
}

# =============================================================================
# BUILD AND RUN WITH DOCKER
# =============================================================================
deploy_docker() {
    print_header "Building and Running with Docker"
    
    echo "Building Docker image..."
    docker build -t fastapi-demo-app:latest .
    
    echo "Running with Docker Compose..."
    docker-compose up -d
    
    print_success "Application deployed with Docker!"
    echo ""
    echo "Access your app at: http://localhost:8000"
    echo "Health check: curl http://localhost:8000/health"
}

# =============================================================================
# BUILD AND RUN WITH KUBERNETES (Minikube)
# =============================================================================
deploy_kubernetes() {
    print_header "Deploying to Kubernetes (Minikube)"
    
    # Check if minikube is running
    if ! minikube status &> /dev/null; then
        echo "Starting Minikube..."
        minikube start --driver=docker
    fi
    
    # Point Docker to Minikube's Docker daemon
    echo "Configuring Docker for Minikube..."
    eval $(minikube docker-env)
    
    # Build the image inside Minikube
    echo "Building Docker image inside Minikube..."
    docker build -t fastapi-demo-app:latest .
    
    # Apply Kubernetes manifests
    echo "Applying Kubernetes manifests..."
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    
    # Wait for deployment
    echo "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=60s deployment/fastapi-demo-app
    
    print_success "Application deployed to Kubernetes!"
    echo ""
    echo "Getting service URL..."
    minikube service fastapi-demo-service --url
}

# =============================================================================
# USEFUL COMMANDS
# =============================================================================
show_commands() {
    print_header "Useful Commands Reference"
    
    echo -e "${YELLOW}Docker Commands:${NC}"
    echo "  docker build -t fastapi-demo-app .      # Build image"
    echo "  docker-compose up -d                     # Start containers"
    echo "  docker-compose down                      # Stop containers"
    echo "  docker-compose logs -f                   # View logs"
    echo "  docker ps                                # List running containers"
    echo ""
    echo -e "${YELLOW}Kubernetes Commands:${NC}"
    echo "  kubectl get pods                         # List pods"
    echo "  kubectl get services                     # List services"
    echo "  kubectl get deployments                  # List deployments"
    echo "  kubectl logs <pod-name>                  # View pod logs"
    echo "  kubectl describe pod <pod-name>          # Pod details"
    echo "  kubectl delete -f k8s/                   # Delete all resources"
    echo ""
    echo -e "${YELLOW}Minikube Commands:${NC}"
    echo "  minikube start                           # Start cluster"
    echo "  minikube stop                            # Stop cluster"
    echo "  minikube dashboard                       # Open web dashboard"
    echo "  minikube service <name> --url            # Get service URL"
}

# =============================================================================
# MAIN MENU
# =============================================================================
main_menu() {
    print_header "FastAPI Login App - Deployment Options"
    
    echo "Choose deployment option:"
    echo "  1) Install Docker only"
    echo "  2) Install Docker + Kubernetes (Minikube)"
    echo "  3) Deploy with Docker Compose"
    echo "  4) Deploy to Kubernetes (Minikube)"
    echo "  5) Full setup (Install everything + Deploy)"
    echo "  6) Show useful commands"
    echo "  0) Exit"
    echo ""
    read -p "Enter your choice [0-6]: " choice
    
    case $choice in
        1)
            detect_os
            install_docker
            install_docker_compose
            print_warning "Log out and log back in for docker group to take effect"
            ;;
        2)
            detect_os
            install_docker
            install_docker_compose
            install_kubectl
            install_minikube
            print_warning "Log out and log back in, then run: minikube start"
            ;;
        3)
            deploy_docker
            ;;
        4)
            deploy_kubernetes
            ;;
        5)
            detect_os
            install_docker
            install_docker_compose
            install_kubectl
            install_minikube
            print_header "Setup Complete!"
            print_warning "Log out and log back in, then run this script again and choose option 3 or 4"
            ;;
        6)
            show_commands
            ;;
        0)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option"
            exit 1
            ;;
    esac
}

# Run main menu
main_menu
