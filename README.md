# Strapi Local Setup - DevOps Intern Task

## � CreateSd By

**Name**: Arman Bisht  
**Role**: DevOps Intern  
**Date**: December 3, 2025

---

## ✅ Tasks Completed

### Task 1: Strapi Local Setup
- ✓ Cloned official Strapi repository
- ✓ Installed dependencies and built project
- ✓ Started development server
- ✓ Created sample content and uploaded media

### Task 2: Docker Setup
- ✓ Created Dockerfile for Strapi application
- ✓ Built and tested Docker image locally
- ✓ Documented Docker setup process
- ✓ See: `TASK2_DOCKER_SUMMARY.md`

### Task 3: Docker Compose Multi-Container Setup
- ✓ Created docker-compose.yml with PostgreSQL
- ✓ Configured Nginx reverse proxy
- ✓ Set up networking between containers
- ✓ Documented in `strapi/examples/getstarted/`

### Task 4: Docker Deep Dive Documentation
- ✓ Explained Docker vs VMs
- ✓ Documented Docker architecture
- ✓ Covered Dockerfile, networking, volumes
- ✓ See: `strapi/examples/getstarted/Task_4_docker.md`

### Task 5: AWS EC2 Deployment with Terraform
- ✓ Automated infrastructure with Terraform
- ✓ Deployed Strapi on EC2 using Docker
- ✓ Configured VPC, Security Groups, and networking
- ✓ See: `strapi/examples/getstarted/TASK5_README.md`

### Task 6: GitHub Actions CI/CD Pipeline
- ✓ Created CI workflow for Docker image builds
- ✓ Automated Docker image push to AWS ECR
- ✓ Created CD workflow for Terraform deployments
- ✓ Deployed EC2 instance with IAM role for ECR access
- ✓ Configured manual workflow triggers for infrastructure management
- ✓ See: `.github/workflows/` and `strapi/examples/getstarted/TASK6_README.md`

#### CI/CD Pipeline Proof

**CI Workflow - Automated Docker Build & Push:**
![CI Build Success](CI_Build.png)

**CD Workflow - Terraform Deployment:**
![CD Deployment Success](CD_deployment.png)

---

## 🚀 Setup Steps

### 1. Clone Repository

```bash
git clone https://github.com/strapi/strapi.git
cd strapi
```

### 2. Install Dependencies

```bash
yarn install
```

### 3. Build Project

```bash
yarn setup
```

### 4. Run Development Server

```bash
npm run develop
```

Access admin panel at: `http://localhost:1337/admin`

---

## 📝 Sample Content Created

### Content Entry Details

**Title**: Strapi Local Setup and PR Preparation

**Content**: Cloned the official Strapi repository, installed Node dependencies using yarn, created my new feature branch (e.g., feature/ArmanBisht), successfully started the development server, and created this sample content entry to verify functionality.

**Team Member Component**:

- **Name**: Arman
- **Role**: DevOps Intern
- **Bio**: Completed the initial task of setting up the local Strapi development environment and verifying the Content Manager functionality by creating a sample content entry.

**Cover Image**: Uploaded to Media Library (Strapi Local Setup image)

---

## 📁 Project Structure

```
Script-Smiths/
├── README.md                           # This file
├── TASK2_DOCKER_SUMMARY.md            # Task 2 documentation
├── .github/
│   └── workflows/
│       ├── ci.yml                      # CI workflow for Docker builds
│       └── terraform.yml               # CD workflow for deployments
└── strapi/
    └── examples/
        └── getstarted/
            ├── Dockerfile.ci               # CI/CD Docker image
            ├── docker-compose.yml          # Multi-container setup
            ├── nginx.conf                  # Nginx configuration
            ├── Task_4_docker.md           # Docker deep dive
            ├── TASK5_README.md            # EC2 deployment guide
            ├── TASK6_README.md            # CI/CD pipeline guide
            └── terraform/                  # Infrastructure as code
                ├── main.tf
                ├── variables.tf
                ├── outputs.tf
                └── user_data.sh
```

---

## 🔧 Technologies Used

- **Strapi**: Headless CMS
- **Docker**: Containerization
- **Docker Compose**: Multi-container orchestration
- **PostgreSQL**: Database
- **Nginx**: Reverse proxy
- **Terraform**: Infrastructure as Code
- **AWS EC2**: Cloud deployment
- **AWS ECR**: Container registry
- **GitHub Actions**: CI/CD automation
- **Amazon Linux 2023**: Operating system

---

## 📚 Resources

- [Strapi Documentation](https://docs.strapi.io)
- [GitHub Repository](https://github.com/strapi/strapi)

---

**Strapi Version**: v5.x  
**Node Version**: v20.14.0
