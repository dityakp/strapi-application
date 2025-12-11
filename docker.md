# Docker Deep Dive: Concise Edition

## What is Docker?

**Docker** is a containerization platform that packages your application with all its dependencies (libraries, runtime, configurations) into a single portable unit called a **container**. This ensures your app runs consistently everywhere—your laptop, servers, production, etc. Think of it like a shipping container that standardizes software delivery.

## The Core Problem Docker Solves

Before Docker: **"It works on my machine"** 😤
- Environment inconsistencies between machines
- Dependency version conflicts
- Hours of manual server configuration
- Slow deployments
- Hard to scale

Docker's solution: Bundle everything together once, run anywhere identically. No manual setup needed.

## Docker vs Virtual Machines

| Aspect | VM | Docker |
|--------|-----|--------|
| **Includes** | Full OS + app | Just app + dependencies |
| **Boot Time** | Minutes | Seconds |
| **Size** | 5-50GB | 10-500MB |
| **Use Case** | OS isolation | App isolation |
| **Performance** | Slower | Native speed |

## Key Components

When you install Docker, you get:

1. **Docker Client** - The CLI you use (`docker run`, `docker build`, etc.)
2. **Docker Daemon** - Runs in background, manages containers
3. **containerd** - Container management layer
4. **runc** - Low-level container runtime that interfaces with OS kernel

## Core Concepts

### Image
A blueprint for a container. Built from a `Dockerfile`.

### Container  
A running instance of an image. Like an object created from a class.

### Dockerfile
A text file with instructions to build an image:

```dockerfile
FROM node:18-alpine          # Start with base image
WORKDIR /app                 # Set working directory
COPY package*.json ./        # Copy files
RUN npm install              # Install dependencies
COPY . .                     # Copy app code
EXPOSE 3000                  # Document port
CMD ["node", "server.js"]   # Default command
```

Build it: `docker build -t myapp:1.0 .`
Run it: `docker run -p 3000:3000 myapp:1.0`

## Essential Docker Commands

### Container Management
```bash
docker run -d -p 8080:3000 --name web myapp     # Run container
docker ps                                        # List running
docker stop web                                  # Stop container
docker rm web                                    # Delete container
docker logs web                                  # View logs
docker exec -it web bash                        # Enter container
```

### Image Management
```bash
docker build -t myapp:1.0 .          # Build image
docker image ls                       # List images
docker pull ubuntu:22.04              # Download image
docker push myapp:1.0                 # Upload image
docker rmi myapp:1.0                  # Delete image
```

### Networks
```bash
docker network create mynet           # Create network
docker run --network mynet myapp      # Use network
```

### Volumes (Persistent Storage)
```bash
docker volume create mydata           # Create volume
docker run -v mydata:/data myapp      # Use volume
```

## Docker Compose (Multi-Container)

Define multiple containers in one YAML file:

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      DB_HOST: db
    depends_on:
      - db
    volumes:
      - ./src:/app/src

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

Run it:
```bash
docker-compose up -d          # Start all services
docker-compose logs -f web    # View logs
docker-compose down           # Stop all services
docker-compose exec web bash  # Run command
```

## Best Practices

1. **Use minimal base images** - `alpine` or `slim` variants
2. **Order Dockerfile instructions** - Put changing code at the end for caching
3. **Combine RUN commands** - Each RUN is a layer, use `&&` to combine
4. **Create .dockerignore** - Exclude `node_modules`, `.git`, etc.
5. **Run as non-root** - Create a user, don't run as root
6. **Use environment variables** - Make containers configurable
7. **Don't store secrets** - Pass at runtime, not in Dockerfile
8. **Health checks** - Tell Docker how to verify container health
9. **Tag images** - Use semantic versioning like `myapp:1.0.0`
10. **One service per container** - Don't put everything in one container

## Quick Start Example

**Dockerfile:**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

**Build and run:**
```bash
docker build -t myapp:1.0 .
docker run -d -p 8000:8000 myapp:1.0
```

**With database (docker-compose.yml):**
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - db
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
```

Run: `docker-compose up -d`

## Why Docker Matters

✅ **Consistency** - Same code, same environment everywhere
✅ **Speed** - Deploy in seconds, not hours
✅ **Scalability** - Spin up multiple containers instantly
✅ **Efficiency** - Lightweight, shared kernel
✅ **Portability** - Works on any system that has Docker
✅ **Isolation** - Apps don't interfere with each other

---

## Next Steps

1. Install Docker Desktop
2. Containerize a simple Python or Node.js app
3. Create a docker-compose setup with app + database
4. Push your image to Docker Hub
5. Explore Kubernetes for orchestration
