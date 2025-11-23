# 📝 DhakaCart Centralized Logging

Complete logging solution using Grafana Loki and Promtail.

## 🎯 What This Provides

### Grafana Loki
- Log aggregation and storage
- Efficient log indexing
- Label-based queries (like Prometheus)
- 31-day retention
- Access at http://localhost:3100

### Promtail
- Log collection agent
- Parses and labels logs
- Ships logs to Loki
- Supports multiple sources (Docker, files, systemd)

### Integration with Grafana
- View logs in existing Grafana instance
- Correlate logs with metrics
- Unified monitoring + logging interface

---

## 🚀 Quick Start

### 1. Start Logging Stack

```bash
cd logging/
docker-compose up -d
```

### 2. Verify Services

```bash
# Check services
docker-compose ps

# View Loki logs
docker-compose logs loki

# View Promtail logs
docker-compose logs promtail
```

### 3. Add Loki to Grafana

1. Open Grafana: http://localhost:3001
2. Go to Configuration → Data Sources
3. Click "Add data source"
4. Select "Loki"
5. Set URL: `http://loki:3100`
6. Click "Save & Test"

---

## 🔍 Querying Logs

### In Grafana Explore

1. Go to Explore (compass icon)
2. Select "Loki" data source
3. Use LogQL queries

### Example Queries

```logql
# All logs from backend service
{service="backend"}

# Error logs only
{service="backend"} |= "error"

# Logs from last hour with status 500
{service="backend"} |= "500" [1h]

# Logs NOT containing "health"
{service="backend"} != "health"

# JSON field extraction
{service="backend"} | json | level="error"

# Count errors per minute
sum(count_over_time({service="backend"} |= "error" [1m]))

# Top 10 error messages
topk(10, sum by (error_message) (count_over_time({service="backend"} |= "error" [1h])))
```

---

## 📊 Log Labels

Logs are automatically labeled with:

- **service** - Docker Compose service name (backend, frontend, database, redis)
- **container** - Container name
- **stream** - stdout or stderr
- **level** - log level (info, warn, error, debug)
- **job** - Promtail job name
- **component** - Application component

---

## 🎨 Creating Log Dashboards

### 1. Create Dashboard

In Grafana:
- Click "+" → "Dashboard"
- Add new panel
- Select "Loki" as data source

### 2. Log Panel - Error Rate

```logql
sum(rate({service="backend"} |= "error" [5m]))
```
- Visualization: Graph
- Title: Error Rate

### 3. Log Panel - Recent Errors

```logql
{service=~"backend|frontend"} |= "error"
```
- Visualization: Logs
- Title: Recent Errors
- Show time, labels, and log line

### 4. Log Panel - Status Code Distribution

```logql
sum by (status) (count_over_time({service="backend"} | json | __error__="" [1h]))
```
- Visualization: Pie chart
- Title: HTTP Status Codes

---

## 🔔 Log-Based Alerts

### Create Alert in Loki

Create `/home/arif/DhakaCart-03/logging/loki/rules/alerts.yml`:

```yaml
groups:
  - name: application_errors
    interval: 1m
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({service="backend"} |= "error" [5m])) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate in backend"
          description: "Backend is producing {{ $value }} errors per second"

      - alert: DatabaseConnectionError
        expr: |
          count_over_time({service="backend"} |= "database connection" |= "error" [5m]) > 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Database connection errors detected"
          description: "Backend cannot connect to database"
```

### Enable Rules in Loki

Restart Loki to load rules:
```bash
docker-compose restart loki
```

---

## 📝 Application Log Format

### Structured JSON Logs (Recommended)

**Backend (Node.js)**:
```javascript
// Use Winston or Pino for structured logging
const winston = require('winston');

const logger = winston.createLogger({
  format: winston.format.json(),
  transports: [
    new winston.transports.Console()
  ]
});

// Log with metadata
logger.info('Order created', {
  orderId: 12345,
  userId: 67890,
  amount: 1500.00
});

// Output: {"level":"info","message":"Order created","orderId":12345,"userId":67890,"amount":1500}
```

### Plain Text Logs (Also supported)

```javascript
console.log('[INFO] Order created - ID: 12345');
console.error('[ERROR] Payment failed - Reason: Insufficient funds');
```

---

## 🔧 Configuration

### Change Log Retention

Edit `loki/loki-config.yml`:

```yaml
limits_config:
  retention_period: 744h  # 31 days (change to 168h for 7 days, 2160h for 90 days)
```

Restart Loki:
```bash
docker-compose restart loki
```

### Add Custom Log Source

Edit `promtail/promtail-config.yml`:

```yaml
scrape_configs:
  - job_name: my_custom_app
    static_configs:
      - targets:
          - localhost
        labels:
          job: custom
          app: my_app
          __path__: /var/log/my_app/*.log
```

Restart Promtail:
```bash
docker-compose restart promtail
```

---

## 📦 Integration with Main Application

### Label Docker Containers

In your main `docker-compose.yml`, add labels:

```yaml
services:
  backend:
    labels:
      logging: "promtail"
      service: "backend"
    # ... rest of config

  frontend:
    labels:
      logging: "promtail"
      service: "frontend"
    # ... rest of config
```

### Connect Networks

```bash
# Ensure networks exist
docker network create app-network
docker network create monitoring_monitoring

# Restart logging stack
cd logging/
docker-compose up -d
```

---

## 🔍 Troubleshooting

### Loki Not Receiving Logs

```bash
# Check Loki status
curl http://localhost:3100/ready

# Check Promtail is running
docker-compose ps promtail

# View Promtail logs
docker-compose logs promtail

# Test sending log to Loki
curl -H "Content-Type: application/json" \
  -XPOST -s "http://localhost:3100/loki/api/v1/push" \
  --data-raw '{"streams": [{"stream": {"job": "test"}, "values": [["'$(date +%s)'000000000", "test log message"]]}]}'
```

### Promtail Not Collecting Docker Logs

```bash
# Check Docker socket permissions
ls -la /var/run/docker.sock

# Verify Docker labels
docker inspect <container-name> | grep -A 5 Labels

# Test Promtail config
docker-compose exec promtail promtail -config.file=/etc/promtail/promtail-config.yml -dry-run
```

### Logs Not Appearing in Grafana

```bash
# Verify Loki datasource in Grafana
# Grafana → Configuration → Data Sources → Loki → Test

# Check if logs exist in Loki
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={job=~".+"}' | jq

# Check Loki labels
curl -s "http://localhost:3100/loki/api/v1/labels" | jq
```

### High Disk Usage

```bash
# Check Loki storage
docker-compose exec loki du -sh /loki/*

# Reduce retention period
# Edit loki-config.yml → retention_period: 168h  # 7 days

# Manually clean old data
docker-compose exec loki rm -rf /loki/chunks/fake/*
docker-compose restart loki
```

---

## 📈 Performance Optimization

### Reduce Log Volume

```yaml
# In promtail-config.yml, add pipeline stage to filter
pipeline_stages:
  # Drop health check logs
  - drop:
      expression: ".*health.*"
  # Drop static file requests
  - drop:
      expression: ".*\\.(css|js|png|jpg).*"
```

### Increase Loki Performance

```yaml
# In loki-config.yml
ingester:
  chunk_idle_period: 15m  # Increase from 1h
  max_chunk_age: 1h
  chunk_target_size: 1572864  # 1.5MB instead of 1MB

limits_config:
  ingestion_rate_mb: 20  # Increase if needed
  ingestion_burst_size_mb: 40
```

---

## 🎯 Common Use Cases

### Debug Production Issues

```logql
# Find all errors in last hour
{service=~"backend|frontend"} |= "error" [1h]

# Trace specific request ID
{service="backend"} |= "request_id=abc123"

# Find slow database queries
{service="postgres"} |= "duration" | json | duration > 1000
```

### Monitor Application Health

```logql
# Count logs by level
sum by (level) (count_over_time({service="backend"} [5m]))

# Error rate over time
rate({service="backend"} |= "error" [5m])

# Failed orders
count_over_time({service="backend"} |= "order" |= "failed" [1h])
```

### Security Monitoring

```logql
# Failed login attempts
{service="backend"} |= "login" |= "failed"

# Suspicious activity
{service="backend"} |= "unauthorized" or "forbidden"

# Database access from unexpected sources
{service="postgres"} != "backend"
```

---

## 📚 LogQL Syntax Reference

### Label Matching
```logql
{service="backend"}              # Exact match
{service=~"backend|frontend"}    # Regex match
{service!="redis"}               # Not equal
{service!~"test.*"}              # Regex not match
```

### Log Filtering
```logql
|= "error"      # Contains
!= "health"     # Does not contain
|~ "error|warn" # Regex match
!~ "debug|trace"# Regex not match
```

### JSON Parsing
```logql
{service="backend"} | json | level="error"
{service="backend"} | json | status_code >= 500
```

### Metrics from Logs
```logql
rate({service="backend"} [5m])
count_over_time({service="backend"} [1h])
sum by (status) (count_over_time({service="backend"} | json [5m]))
```

---

## 🔗 Useful Links

- **Loki Documentation**: https://grafana.com/docs/loki/
- **LogQL Syntax**: https://grafana.com/docs/loki/latest/logql/
- **Promtail Configuration**: https://grafana.com/docs/loki/latest/clients/promtail/
- **Grafana Explore**: https://grafana.com/docs/grafana/latest/explore/

---

**📝 Your logging stack is now ready! All logs are centralized and searchable in Grafana.**

