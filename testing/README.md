# 🧪 DhakaCart Testing

Load testing and performance benchmarking for DhakaCart.

## 📁 Directory Structure

```
testing/
├── load-tests/
│   ├── k6-load-test.js       # K6 load test script
│   └── run-load-test.sh       # Test runner
├── performance/
│   └── benchmark.sh           # Performance benchmarks
└── README.md
```

---

## 🚀 Load Testing with K6

### Install K6

```bash
# Ubuntu/Debian
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# macOS
brew install k6

# Verify installation
k6 version
```

### Run Load Tests

```bash
cd /home/arif/DhakaCart-03/testing/load-tests/

# Interactive test selection
./run-load-test.sh

# Specific test type
BASE_URL=http://your-server.com ./run-load-test.sh
```

### Test Types

**1. Smoke Test (Quick Check)**
- 2 virtual users
- 30 seconds duration
- Verifies basic functionality

**2. Load Test (Normal Traffic)**
- 100 virtual users
- 10 minutes duration
- Simulates normal usage

**3. Stress Test (High Load)**
- 500 virtual users
- 15 minutes duration
- Tests system limits

**4. Spike Test (Traffic Surge)**
- 1000 virtual users
- 5 minutes duration
- Tests sudden traffic increases

**5. Endurance Test (Stability)**
- 50 virtual users
- 1 hour duration
- Tests long-term stability

**6. Custom Test**
- Configure your own parameters

### Test Scenarios

The K6 script simulates real user behavior:

1. **Browse Products** (40% of traffic)
   - Load product list
   - View categories
   - Search products

2. **Create Orders** (30% of traffic)
   - Add items to cart
   - Complete checkout
   - Submit order

3. **Health Checks** (30% of traffic)
   - Monitor system health

### Reading K6 Results

```
checks.........................: 98.50% ✓ 2955   ✗ 45  
data_received..................: 12 MB  200 kB/s
data_sent......................: 4.5 MB 75 kB/s
http_req_duration..............: avg=145ms min=12ms med=98ms max=2.1s p(90)=280ms p(95)=450ms
http_req_failed................: 1.50%  ✓ 45    ✗ 2955
http_reqs......................: 3000   50/s
```

**Key Metrics:**
- **checks**: Pass/fail rate of assertions
- **http_req_duration**: Response times (p95 should be < 2s)
- **http_req_failed**: Error rate (should be < 1%)
- **http_reqs**: Total requests and requests per second

### Setting Thresholds

Edit `k6-load-test.js`:

```javascript
thresholds: {
  // 95% of requests < 2 seconds
  http_req_duration: ['p(95)<2000'],
  // Error rate < 1%
  errors: ['rate<0.01'],
  // 99% success rate
  http_req_failed: ['rate<0.01'],
}
```

---

## 📊 Performance Benchmarking

### Apache Bench Tests

```bash
cd /home/arif/DhakaCart-03/testing/performance/

# Run benchmarks
./benchmark.sh

# Custom benchmark
ab -n 1000 -c 10 http://localhost:5000/api/products
```

### Benchmark Metrics

```
Time taken for tests:   10.123 seconds
Requests per second:    98.78 [#/sec]
Time per request:       101.23 [ms] (mean)
Transfer rate:          45.67 [Kbytes/sec]
```

**Good Benchmarks:**
- Requests/sec: > 50
- Time/request: < 200ms
- Failed requests: 0

---

## 🎯 Performance Goals

| Metric | Target | Acceptable | Poor |
|--------|--------|------------|------|
| Response Time (p95) | < 500ms | < 1s | > 1s |
| Response Time (p99) | < 1s | < 2s | > 2s |
| Requests/sec | > 100 | > 50 | < 50 |
| Error Rate | < 0.1% | < 1% | > 1% |
| Concurrent Users | 1000+ | 500+ | < 500 |

---

## 🔍 Analyzing Results

### Identify Bottlenecks

**Symptoms:**
- High response times
- Low throughput
- Errors under load

**Common Causes:**
1. **Database** - Slow queries, missing indexes
2. **Network** - Bandwidth limits, latency
3. **CPU** - Insufficient processing power
4. **Memory** - Out of memory, swapping
5. **Connection Pool** - Too few connections

### Monitor During Tests

```bash
# CPU and memory
htop

# Network
iftop

# Disk I/O
iotop

# Docker stats
docker stats

# Kubernetes pods
kubectl top pods -n dhakacart
```

---

## 🚀 Performance Optimization

### Backend Optimization

```javascript
// Add response caching
app.use(cache('5 minutes'));

// Enable compression
app.use(compression());

// Connection pooling
const pool = new Pool({
  max: 20,  // Increase pool size
  idleTimeoutMillis: 30000
});
```

### Database Optimization

```sql
-- Add indexes
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_orders_created_at ON orders(created_at);

-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM products WHERE category = 'electronics';
```

### Redis Caching

```javascript
// Cache product list
const products = await redis.get('products:all');
if (!products) {
  products = await db.query('SELECT * FROM products');
  await redis.setex('products:all', 300, JSON.stringify(products));
}
```

### Nginx Configuration

```nginx
# Increase worker processes
worker_processes auto;

# Enable caching
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;

# Gzip compression
gzip on;
gzip_types text/plain text/css application/json;
```

---

## 📈 Continuous Performance Testing

### Integrate with CI/CD

```yaml
# .github/workflows/performance-test.yml
name: Performance Test

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  performance-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install K6
        run: |
          sudo gpg -k
          curl -s https://dl.k6.io/key.gpg | sudo apt-key add -
          echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update
          sudo apt-get install k6
      
      - name: Run Load Test
        run: |
          cd testing/load-tests
          k6 run k6-load-test.js
      
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: k6-results
          path: testing/load-tests/reports/
```

---

## 🎓 Best Practices

1. **Test Early** - Run performance tests before issues arise
2. **Test Often** - Regular testing catches regressions
3. **Test Production-Like** - Use similar data and configuration
4. **Monitor Resources** - Watch CPU, memory, disk during tests
5. **Analyze Trends** - Track performance over time
6. **Fix Bottlenecks** - Address slowest components first
7. **Retest** - Verify optimizations work

---

## 📚 Resources

- **K6 Documentation**: https://k6.io/docs/
- **Apache Bench Guide**: https://httpd.apache.org/docs/2.4/programs/ab.html
- **Performance Testing**: https://martinfowler.com/articles/practical-test-pyramid.html

---

**⚡ Fast applications = Happy users! Test and optimize regularly.**

