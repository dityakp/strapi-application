# Dockerized Strapi + PostgreSQL + Nginx Setup

A fully containerized environment for Strapi using PostgreSQL as the database and Nginx as a reverse proxy. All services communicate over a user-defined Docker network.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Service Management](#service-management)
- [Environment Variables](#environment-variables)
- [File Structure](#file-structure)

---

## 🏗️ Architecture Overview

This setup consists of three containerized services:

```
┌─────────────────────────────────────────────────────┐
│              Docker Network: strapi-net             │
├────────────────┬──────────────────┬────────────────┤
│                │                  │                │
│   PostgreSQL   │   Strapi App     │    Nginx       │
│   :5432        │   :1337          │    :80         │
│                │                  │    (reverse    │
│                │                  │     proxy)     │
└────────────────┴──────────────────┴────────────────┘
                          ↓
                   http://localhost
                   http://localhost/admin
```

---

## ✅ Prerequisites

- **Docker** (v20.10+)
- **Docker Compose** (optional but recommended)
- **Git** (for version control)
- **Node.js** (v18+ if building locally)
- **~2GB RAM** available for containers
- **Windows users**: Use `winpty` for interactive terminal commands

---

## 🚀 Quick Start

### 1. Clone or Create Project Structure

```bash
mkdir -p The-Monitor-Hub/nginx
cd The-Monitor-Hub
```

### 2. Create Docker Network

```bash
docker network create strapi-net
```

### 3. Start PostgreSQL

```bash
docker run -d \
  --name strapi-postgres \
  --network strapi-net \
  -e POSTGRES_USER=strapi \
  -e POSTGRES_PASSWORD=strapi123 \
  -e POSTGRES_DB=strapi \
  -p 5432:5432 \
  postgres:15
```

### 4. Create `.env` File

Create a `.env` file in your project root with the contents provided in the [Environment Variables](#environment-variables) section.

### 5. Build and Run Strapi

```bash
docker build --no-cache -t strapi-app .

docker run -d \
  --name strapi-container \
  --network strapi-net \
  --env-file .env \
  -p 1337:1337 \
  strapi-app
```

### 6. Configure and Start Nginx

Create `nginx/nginx.conf` with the configuration provided below, then:

**On Linux/macOS:**
```bash
docker run -d \
  --name strapi-nginx \
  --network strapi-net \
  -p 80:80 \
  -v "$(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf:ro" \
  nginx:latest
```

**On Windows (PowerShell):**
```bash
$nginxPath = "$(Get-Location)\nginx\nginx.conf"
docker run -d `
  --name strapi-nginx `
  --network strapi-net `
  -p 80:80 `
  -v "$nginxPath`:/etc/nginx/nginx.conf:ro" `
  nginx:latest
```

**On Windows (CMD/Git Bash):**
```bash
winpty docker run -d \
  --name strapi-nginx \
  --network strapi-net \
  -p 80:80 \
  -v "C:/Users/YOUR_USERNAME/Desktop/Task-3/The-Monitor-Hub/nginx/nginx.conf:/etc/nginx/nginx.conf:ro" \
  nginx:latest
```

### 7. Access Strapi Admin

Open your browser and navigate to:
```
http://localhost/admin
```

You should see the Strapi Admin Panel setup screen.

---

## 📝 Detailed Setup

### Step 1: Create User-Defined Docker Network

```bash
docker network create strapi-net
```

**Why?** Containers on a user-defined network can communicate using container names as hostnames.

### Step 2: Run PostgreSQL Container

```bash
docker run -d \
  --name strapi-postgres \
  --network strapi-net \
  -e POSTGRES_USER=strapi \
  -e POSTGRES_PASSWORD=strapi123 \
  -e POSTGRES_DB=strapi \
  -p 5432:5432 \
  postgres:15
```

**Flags Explained:**
- `-d`: Run in detached mode
- `--name`: Container identifier
- `--network`: Connect to strapi-net
- `-e`: Environment variables for PostgreSQL
- `-p`: Port mapping (host:container)

### Step 3: Prepare Strapi Project

Ensure your Strapi project has:
- `package.json`
- `package-lock.json` (recommended)
- `.env` file (see template below)
- `Dockerfile` (provided below)

### Step 4: Create .env File

Create `.env` in your project root:

```plaintext
# Server Configuration
HOST=0.0.0.0
PORT=1337

# Keys and Secrets (Generate production-grade secrets)
APP_KEYS=appkey1,appkey2
API_TOKEN_SALT=apitokensalt123
ADMIN_JWT_SECRET=adminjwt123
JWT_SECRET=jwtsecret123
ADMIN_AUTH_SECRET=adminauthsecret123
TRANSFER_TOKEN_SALT=transfersalt123
ENCRYPTION_KEY=encryptionkey123

# Database Configuration
DATABASE_CLIENT=postgres
DATABASE_HOST=strapi-postgres
DATABASE_PORT=5432
DATABASE_NAME=strapi
DATABASE_USERNAME=strapi
DATABASE_PASSWORD=strapi123
```

> ⚠️ **Security Warning**: Change these secrets in production. Use random, complex values.

### Step 5: Create Dockerfile

Create `Dockerfile` in your project root:

```dockerfile
FROM node:20-bullseye

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .
COPY .env .env

EXPOSE 1337

CMD ["npm", "run", "develop"]
```

### Step 6: Build Strapi Docker Image

```bash
docker build --no-cache -t strapi-app .
```

**Output:**
```
Successfully built abc123def456
Successfully tagged strapi-app:latest
```

### Step 7: Run Strapi Container

```bash
docker run -d \
  --name strapi-container \
  --network strapi-net \
  --env-file .env \
  -p 1337:1337 \
  strapi-app
```

**Verify logs:**
```bash
docker logs -f strapi-container
```

**Expected output:**
```
[2025-12-05 07:20:00] info: Server started in 5s
[2025-12-05 07:20:05] info: Admin panel available at http://localhost:1337/admin
```

### Step 8: Create Nginx Configuration

Create `nginx/nginx.conf`:

```nginx
events {}

http {
    server {
        listen 80;

        location / {
            proxy_pass http://strapi-container:1337;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /admin/ {
            proxy_pass http://strapi-container:1337/admin/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
```

### Step 9: Run Nginx Container

**Linux/macOS:**
```bash
docker run -d \
  --name strapi-nginx \
  --network strapi-net \
  -p 80:80 \
  -v "$(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf:ro" \
  nginx:latest
```

**Windows (PowerShell):**
```powershell
$nginxPath = "$(Get-Location)\nginx\nginx.conf"
docker run -d `
  --name strapi-nginx `
  --network strapi-net `
  -p 80:80 `
  -v "$nginxPath`:/etc/nginx/nginx.conf:ro" `
  nginx:latest
```

**Windows (Git Bash/CMD):**
```bash
winpty docker run -d \
  --name strapi-nginx \
  --network strapi-net \
  -p 80:80 \
  -v "C:/Users/YOUR_USERNAME/Desktop/Task-3/The-Monitor-Hub/nginx/nginx.conf:/etc/nginx/nginx.conf:ro" \
  nginx:latest
```

**Verify logs:**
```bash
docker logs strapi-nginx
```

**Expected output:**
```
Configuration complete; ready for start up
2025/12/05 07:20:00 [notice] 1#1: signal process started
```

---

## ✔️ Verification

### Check All Services

```bash
docker ps
```

**Expected output:**
```
CONTAINER ID   IMAGE      COMMAND                  STATUS
abc123def456   postgres   "docker-entrypoint.s…"   Up 3 minutes   5432/tcp → 5432:5432
def456ghi789   strapi-app "npm run develop"        Up 2 minutes   1337/tcp → 1337:1337
ghi789jkl012   nginx      "/docker-entrypoint.…"   Up 1 minute    0.0.0.0:80→80/tcp
```

### Test Database Connection

```bash
docker exec strapi-postgres psql -U strapi -d strapi -c "SELECT version();"
```

### Access Services

- **Strapi Admin**: http://localhost/admin
- **Strapi API**: http://localhost/api
- **Direct Strapi**: http://localhost:1337/admin
- **PostgreSQL**: localhost:5432

### Network Verification

```bash
docker network inspect strapi-net
```

---

## 🔧 Service Management

### View Logs

```bash
# All containers
docker logs strapi-container
docker logs strapi-postgres
docker logs strapi-nginx

# Real-time logs
docker logs -f strapi-container
```

### Stop Services

```bash
# Individual containers
docker stop strapi-container
docker stop strapi-postgres
docker stop strapi-nginx

# All at once
docker stop strapi-container strapi-postgres strapi-nginx
```

### Start Services

```bash
docker start strapi-postgres
docker start strapi-container
docker start strapi-nginx
```

### Remove Containers (Complete Cleanup)

```bash
docker stop strapi-container strapi-postgres strapi-nginx
docker rm strapi-container strapi-postgres strapi-nginx
docker network rm strapi-net
```

### Rebuild After Changes

```bash
# Rebuild image
docker build --no-cache -t strapi-app .

# Remove old container
docker stop strapi-container
docker rm strapi-container

# Run new container
docker run -d \
  --name strapi-container \
  --network strapi-net \
  --env-file .env \
  -p 1337:1337 \
  strapi-app
```

---

## 🔐 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | 0.0.0.0 | Bind to all interfaces |
| `PORT` | 1337 | Strapi port |
| `APP_KEYS` | - | Comma-separated app keys |
| `API_TOKEN_SALT` | - | Salt for API tokens |
| `ADMIN_JWT_SECRET` | - | Secret for JWT tokens |
| `JWT_SECRET` | - | Secret for JWT signing |
| `ADMIN_AUTH_SECRET` | - | Secret for admin authentication |
| `TRANSFER_TOKEN_SALT` | - | Salt for transfer tokens |
| `ENCRYPTION_KEY` | - | Encryption key for sensitive data |
| `DATABASE_CLIENT` | postgres | Database type |
| `DATABASE_HOST` | strapi-postgres | Database host |
| `DATABASE_PORT` | 5432 | Database port |
| `DATABASE_NAME` | strapi | Database name |
| `DATABASE_USERNAME` | strapi | Database user |
| `DATABASE_PASSWORD` | strapi123 | Database password |

> **Production Tip**: Generate strong, random values for all secrets using tools like:
> ```bash
> openssl rand -base64 32
> ```

---

## 📁 File Structure

```
The-Monitor-Hub/
├── package.json
├── package-lock.json
├── .env
├── Dockerfile
├── nginx/
│   └── nginx.conf
├── src/
│   ├── api/
│   ├── components/
│   └── ...
└── README.md
```

---

## 🐛 Troubleshooting

### Nginx Returns 502 Bad Gateway

**Problem:** Nginx cannot reach Strapi container

**Solution:**
```bash
# Verify containers are running
docker ps

# Check network connectivity
docker exec strapi-nginx ping strapi-container

# Verify Nginx config
docker exec strapi-nginx nginx -t
```

### Database Connection Error

**Problem:** Strapi cannot connect to PostgreSQL

**Solution:**
```bash
# Verify PostgreSQL is running
docker ps | grep postgres

# Check PostgreSQL logs
docker logs strapi-postgres

# Test connection
docker exec strapi-postgres psql -U strapi -d strapi -c "\dt"
```

### Port Already in Use

**Problem:** Port 80 or 5432 is already in use

**Solution:**
```bash
# Change Nginx port
docker run -d --name strapi-nginx -p 8080:80 ...

# Change PostgreSQL port
docker run -d --name strapi-postgres -p 5433:5432 ...
```

### Strapi Container Exits Immediately

**Problem:** Container crashes on startup

**Solution:**
```bash
# Check logs
docker logs strapi-container

# Rebuild without cache
docker build --no-cache -t strapi-app .

# Run with interactive terminal for debugging
docker run -it --rm \
  --network strapi-net \
  --env-file .env \
  strapi-app \
  /bin/bash
```

### Permission Denied on Windows

**Solution:** Use `winpty` prefix:
```bash
winpty docker run -it --rm strapi-app /bin/bash
```

---

## 🚀 Performance Tips

1. **Use `.dockerignore`** to exclude unnecessary files:
   ```
   node_modules
   .git
   .env.local
   .DS_Store
   ```

2. **Enable BuildKit** for faster builds:
   ```bash
   export DOCKER_BUILDKIT=1
   docker build -t strapi-app .
   ```

3. **Optimize Dockerfile** with multi-stage builds for production

4. **Monitor containers**:
   ```bash
   docker stats
   ```

---

## 📚 Additional Resources

- [Strapi Documentation](https://docs.strapi.io)
- [PostgreSQL Docker Official Image](https://hub.docker.com/_/postgres)
- [Nginx Docker Official Image](https://hub.docker.com/_/nginx)
- [Docker Networking Guide](https://docs.docker.com/network/)
- [Docker Compose Alternative](https://docs.docker.com/compose/)

---

## 🎯 Next Steps

1. Complete Strapi Admin setup at http://localhost/admin
2. Create your first API collection
3. Configure Strapi roles and permissions
4. Set up webhooks if needed
5. Deploy to production (AWS, DigitalOcean, etc.)

---

## 📞 Support

For issues with:
- **Strapi**: Visit [Strapi Community](https://strapi.io/community)
- **Docker**: Visit [Docker Docs](https://docs.docker.com)
- **PostgreSQL**: Visit [PostgreSQL Docs](https://www.postgresql.org/docs/)

---

## 📄 License

This setup guide is provided as-is for educational and development purposes.

---

**Last Updated:** December 5, 2025
**Docker Version:** 20.10+
**Strapi Version:** Latest (v5)
**PostgreSQL Version:** 15
