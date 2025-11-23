#!/bin/bash
# User data script - Runs when EC2 instance starts
# Installs Docker and runs your containers (including PostgreSQL and Redis)

set -e  # Exit on error

# Update system
apt-get update
apt-get install -y docker.io docker-compose curl

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Create application directory
mkdir -p /opt/dhakacart
cd /opt/dhakacart

# Create nginx config for frontend (proxies API to backend)
cat > nginx-frontend.conf <<NGINX_EOF
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Proxy API requests to backend container (Docker network)
    location /api/ {
        proxy_pass http://backend:5000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Serve static files (we'll mount the frontend build later)
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
NGINX_EOF

# For now, use a simple approach: run frontend dev server but fix API URL
# Better solution: Rebuild frontend image with production target
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  # PostgreSQL Database (Docker container)
  database:
    image: postgres:15-alpine
    container_name: dhakacart-db
    environment:
      POSTGRES_USER: ${db_user}
      POSTGRES_PASSWORD: ${db_password}
      POSTGRES_DB: ${db_name}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${db_user}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - dhakacart-network

  # Redis Cache (Docker container)
  redis:
    image: redis:7-alpine
    container_name: dhakacart-redis
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped
    networks:
      - dhakacart-network

  # Backend API
  backend:
    image: ${backend_image}
    container_name: dhakacart-backend
    environment:
      NODE_ENV: production
      PORT: 5000
      DB_HOST: ${db_host}
      DB_PORT: 5432
      DB_USER: ${db_user}
      DB_PASSWORD: ${db_password}
      DB_NAME: ${db_name}
      REDIS_HOST: ${redis_host}
      REDIS_PORT: 6379
    ports:
      - "5000:5000"
    depends_on:
      database:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - dhakacart-network

  # Frontend - Use relative URL, Nginx will proxy to backend
  frontend:
    image: ${frontend_image}
    container_name: dhakacart-frontend
    environment:
      # Use relative URL - Nginx (in frontend container) will proxy /api/ to backend
      # No public IP needed - all communication via Docker network
      REACT_APP_API_URL: /api
    ports:
      - "3000:80"  # Nginx listens on port 80 (if production build)
      # If image is development build, change to "3000:3000"
    depends_on:
      - backend
    restart: unless-stopped
    networks:
      - dhakacart-network

volumes:
  postgres_data:
  redis_data:

networks:
  dhakacart-network:
    driver: bridge
EOF

# Start all containers
docker-compose up -d

# Wait for services to be ready
sleep 30

# Log to CloudWatch (optional)
echo "DhakaCart application started successfully at $(date)" >> /var/log/user-data.log
echo "Services: PostgreSQL, Redis, Backend, Frontend" >> /var/log/user-data.log

