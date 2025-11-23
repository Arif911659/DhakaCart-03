# 📊 DhakaCart Monitoring Stack

Complete monitoring solution using Prometheus, Grafana, and AlertManager.

## 🎯 What This Provides

### Prometheus
- Metrics collection from all services
- Time-series database
- Alert rule evaluation
- Query interface at http://localhost:9090

### Grafana
- Beautiful dashboards
- Data visualization
- Custom metrics display
- Access at http://localhost:3001
- **Default credentials:** admin / dhakacart123

### AlertManager
- Alert routing and grouping
- Email notifications
- Configurable alert channels
- Access at http://localhost:9093

### Exporters
- **Node Exporter** - System metrics (CPU, memory, disk)
- **cAdvisor** - Container metrics
- **Postgres Exporter** - Database metrics
- **Redis Exporter** - Cache metrics

---

## 🚀 Quick Start

### 1. Start Monitoring Stack

```bash
cd monitoring/
docker-compose up -d
```

### 2. Verify Services

```bash
# Check all services are running
docker-compose ps

# View logs
docker-compose logs -f
```

### 3. Access Interfaces

- **Grafana**: http://localhost:3001 (admin / dhakacart123)
- **Prometheus**: http://localhost:9090
- **AlertManager**: http://localhost:9093
- **Node Exporter**: http://localhost:9100/metrics
- **cAdvisor**: http://localhost:8080

---

## 📊 Available Dashboards

### System Metrics Dashboard
- CPU usage by core
- Memory usage and available
- Disk I/O and space
- Network traffic

### Application Metrics Dashboard
- Request rate and latency
- Error rates by endpoint
- Active connections
- Response time percentiles

### Business Metrics Dashboard
- Orders per minute
- Revenue tracking
- Conversion rates
- User activity

### Database Metrics Dashboard
- Connection pool usage
- Query performance
- Cache hit ratios
- Slow query tracking

---

## 🔔 Alert Configuration

### Alert Levels

**Critical Alerts** (Immediate attention):
- Service down
- CPU > 95%
- Memory > 95%
- Disk space < 10%
- Error rate > 10%

**Warning Alerts** (Action needed soon):
- CPU > 80%
- Memory > 80%
- Disk space < 20%
- Error rate > 5%
- High response times

### Notification Channels

Edit `alertmanager/config.yml` to configure:
- Email addresses
- Slack webhooks
- PagerDuty integration
- SMS gateways

---

## 📧 Configure Email Alerts

### 1. Gmail Setup (for testing)

```yaml
# In alertmanager/config.yml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'your-email@gmail.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'  # Generate from Google Account settings
  smtp_require_tls: true
```

### 2. Get Gmail App Password

1. Go to https://myaccount.google.com/security
2. Enable 2-Step Verification
3. Generate App Password
4. Use the 16-character password in config

### 3. Restart AlertManager

```bash
docker-compose restart alertmanager
```

---

## 🔧 Custom Metrics

### Add Metrics to Backend

```javascript
// backend/server.js
const promClient = require('prom-client');

// Create a Registry
const register = new promClient.Registry();

// Add default metrics (CPU, memory, etc.)
promClient.collectDefaultMetrics({ register });

// Custom metric - Order counter
const orderCounter = new promClient.Counter({
  name: 'orders_total',
  help: 'Total number of orders',
  registers: [register]
});

// Increment counter when order is placed
app.post('/api/orders', async (req, res) => {
  // ... order processing ...
  orderCounter.inc();
  // ...
});

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

---

## 📈 Viewing Metrics

### Prometheus Queries

Access http://localhost:9090 and try these queries:

```promql
# CPU usage percentage
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Request rate (requests per second)
rate(http_requests_total[5m])

# Error rate percentage
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100

# P95 response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

---

## 🎨 Creating Grafana Dashboards

### 1. Login to Grafana
http://localhost:3001 (admin / dhakacart123)

### 2. Create New Dashboard
- Click "+" → "Dashboard"
- Click "Add new panel"

### 3. Configure Panel
- **Title**: CPU Usage
- **Query**: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- **Visualization**: Graph
- **Unit**: Percent (0-100)

### 4. Add Alert
- Go to Alert tab
- Set condition: WHEN avg() OF query(A, 5m, now) IS ABOVE 80
- Configure notifications

---

## 🔍 Troubleshooting

### Prometheus Not Scraping Metrics

```bash
# Check Prometheus targets
http://localhost:9090/targets

# View Prometheus logs
docker-compose logs prometheus

# Test metric endpoint directly
curl http://localhost:5000/metrics
```

### AlertManager Not Sending Emails

```bash
# Check AlertManager logs
docker-compose logs alertmanager

# Verify config
docker-compose exec alertmanager amtool check-config /etc/alertmanager/config.yml

# Test alert
docker-compose exec alertmanager amtool alert add test severity=critical
```

### Grafana Dashboard Not Loading

```bash
# Check Grafana logs
docker-compose logs grafana

# Verify datasource connection
# Grafana → Configuration → Data Sources → Prometheus → Test

# Reset admin password
docker-compose exec grafana grafana-cli admin reset-admin-password newpassword
```

### High Resource Usage

```bash
# Reduce Prometheus retention
# In prometheus.yml, change:
--storage.tsdb.retention.time=15d  # Instead of 30d

# Reduce scrape frequency
scrape_interval: 30s  # Instead of 15s

# Restart Prometheus
docker-compose restart prometheus
```

---

## 📦 Integration with Main Application

### Connect to Application Network

```bash
# Create network if not exists
docker network create app-network

# Connect monitoring to app network
docker-compose up -d
```

### Add to Main docker-compose.yml

```yaml
networks:
  monitoring:
    external: true
    name: monitoring_monitoring

services:
  backend:
    networks:
      - default
      - monitoring
```

---

## 🎯 Production Deployment

### 1. Secure Grafana

```yaml
# In docker-compose.yml
environment:
  - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
  - GF_SECURITY_SECRET_KEY=${GRAFANA_SECRET_KEY}
  - GF_SERVER_ROOT_URL=https://monitoring.dhakacart.com
```

### 2. Configure Real Email

Update `alertmanager/config.yml` with production SMTP settings

### 3. Enable HTTPS

```yaml
# Add nginx reverse proxy
nginx:
  image: nginx:alpine
  ports:
    - "443:443"
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
    - ./ssl:/etc/nginx/ssl
```

### 4. Backup Grafana Data

```bash
# Backup Grafana dashboards
docker-compose exec grafana grafana-cli admin export-dashboard > backup.json

# Backup Grafana database
docker-compose exec grafana cp /var/lib/grafana/grafana.db /tmp/
docker cp dhakacart-grafana:/tmp/grafana.db ./grafana-backup.db
```

---

## 📊 Metrics Retention

- **Prometheus**: 30 days (configurable)
- **Grafana**: Unlimited (depends on datasource)
- **AlertManager**: 120 hours

To change Prometheus retention:
```yaml
# In docker-compose.yml
command:
  - '--storage.tsdb.retention.time=90d'  # 3 months
```

---

## 🔗 Useful Links

- **Prometheus**: https://prometheus.io/docs/
- **Grafana**: https://grafana.com/docs/
- **AlertManager**: https://prometheus.io/docs/alerting/latest/alertmanager/
- **PromQL**: https://prometheus.io/docs/prometheus/latest/querying/basics/
- **Dashboard Gallery**: https://grafana.com/grafana/dashboards/

---

## 🎓 Learning Resources

### Prometheus Queries
```promql
# Top 5 endpoints by request count
topk(5, rate(http_requests_total[5m]))

# Memory usage by container
container_memory_usage_bytes{name=~"dhakacart.*"}

# Disk usage prediction (will fill in 4 hours)
predict_linear(node_filesystem_avail_bytes[1h], 4*3600) < 0
```

### Common Dashboard Patterns
- Time series graphs for trends
- Gauge panels for current values
- Stat panels for counters
- Table panels for multi-dimensional data
- Heatmaps for latency distribution

---

**📊 Your monitoring stack is now ready! Start tracking your application's health and performance in real-time.**

