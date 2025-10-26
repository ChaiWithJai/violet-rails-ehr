# 🚢 SHIP IT - Deployment Checklist

## 🎯 Pre-Ship Checklist

### ✅ Code Complete
- [x] FHIR namespace definitions
- [x] Validation layer
- [x] Serialization layer
- [x] Patient controller (reference implementation)
- [x] Whoop integration
- [x] Documentation
- [ ] Remaining FHIR controllers (Observation, Practitioner, etc.)
- [ ] Tests (unit, integration, performance)
- [ ] Security hardening

### ✅ Documentation
- [x] START_HERE.md
- [x] QUICKSTART.md
- [x] IMPLEMENTATION_GUIDE.md
- [x] PROJECT_SUMMARY.md
- [x] NEXT_STEPS.md
- [x] README_EHR.md

### ⏳ Production Readiness
- [ ] Environment variables configured
- [ ] Database migrations tested
- [ ] Encryption keys generated
- [ ] Monitoring setup
- [ ] Backup strategy
- [ ] Security audit
- [ ] Load testing

## 🚀 Quick Ship (MVP Demo)

**For demo/pilot purposes only - NOT production-ready**

### 1. Local Demo (5 minutes)

```bash
cd /Users/shambhavi/CascadeProjects/violet-rails-ehr

# Install
bundle install

# Setup
rails db:create db:migrate
rails runner "load 'db/seeds/fhir_setup.rb'"

# Ship it!
rails server

# Test
curl http://localhost:3000/fhir/metadata | jq
curl http://localhost:3000/fhir/Patient | jq
```

**Demo URL**: http://localhost:3000/fhir/metadata

### 2. Docker Demo (10 minutes)

```bash
# Build
docker build -t violet-rails-ehr .

# Run
docker run -p 3000:3000 \
  -e DATABASE_URL=postgresql://postgres:postgres@host.docker.internal/violet_ehr \
  -e SECRET_KEY_BASE=$(rails secret) \
  violet-rails-ehr

# Test
curl http://localhost:3000/fhir/metadata | jq
```

### 3. Heroku Quick Deploy (15 minutes)

```bash
# Install Heroku CLI if needed
brew tap heroku/brew && brew install heroku

# Login
heroku login

# Create app
heroku create violet-rails-ehr-demo

# Add PostgreSQL
heroku addons:create heroku-postgresql:mini

# Deploy
git push heroku main

# Setup FHIR
heroku run rails runner "load 'db/seeds/fhir_setup.rb'"

# Open
heroku open /fhir/metadata
```

**Demo URL**: https://violet-rails-ehr-demo.herokuapp.com/fhir/metadata

## 🏭 Production Ship (Full Deployment)

### Prerequisites

- [ ] Domain name configured
- [ ] SSL certificate ready
- [ ] Database provisioned (PostgreSQL 14+)
- [ ] Redis provisioned (for Sidekiq)
- [ ] Monitoring setup (Sentry, Datadog, etc.)
- [ ] Backup strategy defined
- [ ] Security audit completed

### Step 1: Environment Setup (30 minutes)

```bash
# Generate secrets
SECRET_KEY_BASE=$(rails secret)
LOCKBOX_MASTER_KEY=$(rails lockbox:generate_key)
BLIND_INDEX_KEY=$(rails lockbox:generate_key)
PHI_ENCRYPTION_KEY=$(rails lockbox:generate_key)

# Create .env.production
cat > .env.production << EOF
# Database
DATABASE_URL=postgresql://user:pass@host:5432/violet_ehr_production

# Rails
SECRET_KEY_BASE=$SECRET_KEY_BASE
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_SERVE_STATIC_FILES=true

# Encryption
LOCKBOX_MASTER_KEY=$LOCKBOX_MASTER_KEY
BLIND_INDEX_KEY=$BLIND_INDEX_KEY
PHI_ENCRYPTION_KEY=$PHI_ENCRYPTION_KEY

# FHIR
FHIR_BASE_URL=https://your-domain.com

# Whoop (optional)
WHOOP_CLIENT_ID=your_production_client_id
WHOOP_CLIENT_SECRET=your_production_client_secret

# Monitoring
SENTRY_DSN=your_sentry_dsn

# Redis
REDIS_URL=redis://localhost:6379/1
EOF

# Secure it
chmod 600 .env.production
```

### Step 2: Database Setup (15 minutes)

```bash
# Load environment
export $(cat .env.production | xargs)

# Create and migrate
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate

# Setup FHIR namespaces
RAILS_ENV=production rails runner "FhirNamespaces.create_all!"

# Create admin user
RAILS_ENV=production rails runner "
  User.create!(
    email: 'admin@your-domain.com',
    password: SecureRandom.hex(16),
    confirmed_at: Time.current
  )
"
```

### Step 3: Build & Deploy (20 minutes)

#### Option A: Docker + Docker Compose

```bash
# Build production image
docker build -t violet-rails-ehr:production .

# Create docker-compose.production.yml
cat > docker-compose.production.yml << EOF
version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  redis:
    image: redis:7
    restart: always

  web:
    image: violet-rails-ehr:production
    command: bundle exec puma -C config/puma.rb
    ports:
      - "3000:3000"
    env_file:
      - .env.production
    depends_on:
      - db
      - redis
    restart: always

  worker:
    image: violet-rails-ehr:production
    command: bundle exec sidekiq
    env_file:
      - .env.production
    depends_on:
      - db
      - redis
    restart: always

volumes:
  postgres_data:
EOF

# Deploy
docker-compose -f docker-compose.production.yml up -d

# Health check
curl http://localhost:3000/health
curl http://localhost:3000/fhir/metadata
```

#### Option B: Kubernetes

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: violet-rails-ehr
spec:
  replicas: 3
  selector:
    matchLabels:
      app: violet-rails-ehr
  template:
    metadata:
      labels:
        app: violet-rails-ehr
    spec:
      containers:
      - name: web
        image: violet-rails-ehr:production
        ports:
        - containerPort: 3000
        envFrom:
        - secretRef:
            name: violet-rails-ehr-secrets
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: violet-rails-ehr
spec:
  selector:
    app: violet-rails-ehr
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
```

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployment.yaml

# Check status
kubectl get pods
kubectl get services

# Get external IP
kubectl get service violet-rails-ehr
```

### Step 4: Configure Reverse Proxy (15 minutes)

#### Nginx Configuration

```nginx
# /etc/nginx/sites-available/violet-rails-ehr
upstream violet_rails {
  server localhost:3000;
}

server {
  listen 80;
  server_name your-domain.com;
  return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl http2;
  server_name your-domain.com;

  ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

  # Security headers
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "1; mode=block" always;

  location / {
    proxy_pass http://violet_rails;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  # FHIR endpoints
  location /fhir/ {
    proxy_pass http://violet_rails;
    proxy_set_header Content-Type "application/fhir+json";
  }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/violet-rails-ehr /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Step 5: Monitoring Setup (20 minutes)

```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 0.1
  config.environment = Rails.env
end

# config/initializers/prometheus.rb
require 'prometheus/client'
require 'prometheus/client/push'

prometheus = Prometheus::Client.registry

# Metrics
http_requests = prometheus.counter(
  :http_requests_total,
  docstring: 'Total HTTP requests',
  labels: [:method, :path, :status]
)

fhir_resources = prometheus.gauge(
  :fhir_resources_total,
  docstring: 'Total FHIR resources by type',
  labels: [:resource_type]
)
```

### Step 6: Smoke Tests (10 minutes)

```bash
#!/bin/bash
# smoke_test.sh

BASE_URL="https://your-domain.com"

echo "🔍 Running smoke tests..."

# Test 1: Health check
echo "1. Health check..."
curl -f $BASE_URL/health || exit 1
echo "✅ Health check passed"

# Test 2: FHIR metadata
echo "2. FHIR metadata..."
curl -f $BASE_URL/fhir/metadata | jq -e '.resourceType == "CapabilityStatement"' || exit 1
echo "✅ FHIR metadata passed"

# Test 3: Patient list
echo "3. Patient list..."
curl -f $BASE_URL/fhir/Patient | jq -e '.resourceType == "Bundle"' || exit 1
echo "✅ Patient list passed"

# Test 4: Create patient
echo "4. Create patient..."
curl -f -X POST $BASE_URL/fhir/Patient \
  -H "Content-Type: application/json" \
  -d '{
    "resourceType": "Patient",
    "name": [{"family": "Test", "given": ["Smoke"]}],
    "birthDate": "2000-01-01"
  }' | jq -e '.resourceType == "Patient"' || exit 1
echo "✅ Create patient passed"

echo ""
echo "🎉 All smoke tests passed!"
```

```bash
chmod +x smoke_test.sh
./smoke_test.sh
```

## 📊 Post-Deployment Checklist

### Immediate (Day 1)
- [ ] Smoke tests passing
- [ ] Monitoring dashboards configured
- [ ] Alerts set up (error rate, latency, downtime)
- [ ] Backup verified
- [ ] SSL certificate valid
- [ ] DNS propagated

### Week 1
- [ ] Performance monitoring (p95 latency < 250ms)
- [ ] Error rate < 1%
- [ ] No security vulnerabilities
- [ ] Backup/restore tested
- [ ] Documentation updated with production URLs

### Month 1
- [ ] User feedback collected
- [ ] Performance optimizations applied
- [ ] Security audit completed
- [ ] Compliance review (HIPAA/SOC2)
- [ ] Disaster recovery plan tested

## 🔒 Security Checklist

- [ ] All secrets in environment variables (not in code)
- [ ] Database encrypted at rest
- [ ] TLS 1.3 enforced
- [ ] CORS configured properly
- [ ] Rate limiting enabled
- [ ] Authentication on all FHIR endpoints
- [ ] Audit logging enabled
- [ ] PHI encryption configured (Lockbox)
- [ ] Security headers set (CSP, HSTS, etc.)
- [ ] Dependency vulnerabilities scanned

## 📈 Success Metrics

Monitor these after deployment:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Uptime | > 99.9% | Monitoring dashboard |
| API latency (p95) | < 250ms | Prometheus metrics |
| Error rate | < 1% | Sentry dashboard |
| FHIR conformance | > 95% | Run conformance tests |
| User satisfaction | > 4.3/5 | User surveys |

## 🆘 Rollback Plan

If something goes wrong:

```bash
# 1. Stop new deployments
docker-compose -f docker-compose.production.yml down

# 2. Restore from backup
pg_restore -d violet_ehr_production latest_backup.dump

# 3. Deploy previous version
docker-compose -f docker-compose.production.yml up -d

# 4. Verify
./smoke_test.sh

# 5. Investigate
tail -f log/production.log
```

## 🎉 You Shipped It!

**Congratulations!** Your Violet Rails EHR is now live.

### What's Next?

1. **Monitor**: Watch dashboards for first 24 hours
2. **Iterate**: Collect feedback and improve
3. **Scale**: Add more resources as needed
4. **Extend**: Add more FHIR resources and integrations

### Share Your Success

- Tweet about it: #VioletRails #FHIR #HealthTech
- Write a blog post about your experience
- Contribute improvements back to the project

---

**Shipped**: ✅

**Production URL**: https://your-domain.com/fhir/metadata

**Status Page**: https://status.your-domain.com

**Docs**: https://docs.your-domain.com

---

**Built with ❤️ by developers who ship.**
