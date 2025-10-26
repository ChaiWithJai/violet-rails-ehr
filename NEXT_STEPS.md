# Next Steps - Violet Rails EHR Implementation

## 🎯 Current Status

✅ **MVP Core Infrastructure Complete**
- FHIR API Namespace definitions (8 resources)
- Validation & serialization layer
- Patient controller with full CRUD
- Whoop integration framework
- Documentation & quickstart guide

## 📋 Immediate Next Steps (Week 1)

### 1. Complete Remaining FHIR Controllers (3-4 days)

Copy the pattern from `patients_controller.rb` to create:

```bash
# Create these controllers
app/controllers/fhir/observations_controller.rb
app/controllers/fhir/practitioners_controller.rb
app/controllers/fhir/organizations_controller.rb
app/controllers/fhir/encounters_controller.rb
app/controllers/fhir/devices_controller.rb
app/controllers/fhir/conditions_controller.rb
app/controllers/fhir/care_plans_controller.rb
```

**Template for each controller:**

```ruby
module Fhir
  class ObservationsController < BaseController
    # Copy CRUD methods from PatientsController
    # Update namespace_slug
    # Add resource-specific search params
    
    private
    
    def namespace_slug
      'fhir-observation'
    end
    
    def observation_params
      params.require(:observation).permit!
    end
    
    def apply_resource_specific_search(scope)
      # Add Observation-specific search
      scope = apply_subject_search(scope) if params[:subject].present?
      scope = apply_code_search(scope) if params[:code].present?
      scope = apply_date_search(scope) if params[:date].present?
      scope
    end
  end
end
```

### 2. Add Gems to Main Gemfile (30 minutes)

```bash
# Add contents of Gemfile.ehr to main Gemfile
cat Gemfile.ehr >> Gemfile

# Install
bundle install
```

### 3. Integrate Routes (15 minutes)

```ruby
# In config/routes.rb, add at the end:
load Rails.root.join('config/routes_fhir.rb')
```

### 4. Run Setup (10 minutes)

```bash
# Create FHIR namespaces
rails runner "load 'db/seeds/fhir_setup.rb'"

# Verify
curl http://localhost:3000/fhir/metadata | jq
curl http://localhost:3000/fhir/Patient | jq
```

## 📅 Week 2: Testing & Validation

### 1. Write Controller Tests (2-3 days)

```ruby
# test/controllers/fhir/patients_controller_test.rb
require 'test_helper'

class Fhir::PatientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @namespace = api_namespaces(:fhir_patient)
    @patient = api_resources(:patient_one)
  end
  
  test "should get index" do
    get fhir_patients_url, as: :json
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal 'Bundle', json['resourceType']
    assert json['entry'].is_a?(Array)
  end
  
  test "should create patient" do
    assert_difference('@namespace.api_resources.count') do
      post fhir_patients_url, params: {
        patient: {
          resourceType: 'Patient',
          name: [{ family: 'Test', given: ['User'] }],
          birthDate: '1990-01-01'
        }
      }, as: :json
    end
    
    assert_response :created
  end
  
  test "should validate patient" do
    post fhir_patients_url, params: {
      patient: {
        resourceType: 'Patient'
        # Missing required fields
      }
    }, as: :json
    
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal 'OperationOutcome', json['resourceType']
  end
end
```

### 2. FHIR Conformance Testing (1-2 days)

```ruby
# test/integration/fhir_conformance_test.rb
require 'test_helper'

class FhirConformanceTest < ActionDispatch::IntegrationTest
  test "metadata endpoint returns valid CapabilityStatement" do
    get fhir_metadata_url, as: :json
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal 'CapabilityStatement', json['resourceType']
    assert_equal '4.0.1', json['fhirVersion']
    assert json['rest'].present?
  end
  
  test "all resources support CRUD operations" do
    resources = ['Patient', 'Observation', 'Practitioner']
    
    resources.each do |resource|
      # Test read
      get "/fhir/#{resource}", as: :json
      assert_response :success
      
      # Test create
      post "/fhir/#{resource}", params: valid_resource_params(resource), as: :json
      assert_response :created
    end
  end
end
```

### 3. Performance Testing (1 day)

```ruby
# test/performance/fhir_api_performance_test.rb
require 'test_helper'
require 'benchmark'

class FhirApiPerformanceTest < ActionDispatch::IntegrationTest
  test "patient index responds within 250ms" do
    time = Benchmark.realtime do
      get fhir_patients_url, as: :json
    end
    
    assert time < 0.25, "Response took #{time}s, expected < 0.25s"
  end
  
  test "patient create responds within 400ms" do
    time = Benchmark.realtime do
      post fhir_patients_url, params: { patient: valid_patient_params }, as: :json
    end
    
    assert time < 0.4, "Response took #{time}s, expected < 0.4s"
  end
end
```

## 📅 Week 3: Compliance & Security

### 1. Configure Encryption (1 day)

```ruby
# config/initializers/lockbox.rb
Lockbox.master_key = ENV['LOCKBOX_MASTER_KEY']

# app/models/api_resource.rb
class ApiResource < ApplicationRecord
  # Encrypt PHI fields in properties
  encrypts :properties, key: :encryption_key
  
  blind_index :properties, 
    key: :blind_index_key,
    attribute: :searchable_name,
    expression: ->(record) { record.properties.dig('name', 0, 'family') }
  
  private
  
  def encryption_key
    ENV['PHI_ENCRYPTION_KEY']
  end
  
  def blind_index_key
    ENV['BLIND_INDEX_KEY']
  end
end
```

Generate keys:
```bash
rails lockbox:generate_key
# Add to .env
```

### 2. Implement Consent Management (2 days)

```ruby
# Create Consent API Namespace
ApiNamespace.create!(
  name: 'Consent',
  slug: 'consent',
  properties: {
    patient_id: { type: 'string', required: true },
    scope: { type: 'string', enum: ['patient-privacy', 'research', 'treatment'] },
    status: { type: 'string', enum: ['active', 'inactive', 'revoked'] },
    dateTime: { type: 'datetime' },
    period: { type: 'object' },
    policy: { type: 'array' }
  }
)

# app/services/consent_checker.rb
class ConsentChecker
  def self.can_access?(user, patient_resource)
    consent_namespace = ApiNamespace.find_by(slug: 'consent')
    
    # Find active consent for this patient
    consent = consent_namespace.api_resources.where(
      "properties->>'patient_id' = ? AND properties->>'status' = ?",
      patient_resource.id.to_s,
      'active'
    ).first
    
    return false unless consent
    
    # Check scope matches user's role
    user_scope = user.role # e.g., 'treatment', 'research'
    consent.properties['scope'] == user_scope
  end
end

# Add to base controller
before_action :check_consent, only: [:show, :update]

def check_consent
  resource = api_namespace.api_resources.find(params[:id])
  
  unless ConsentChecker.can_access?(current_user, resource)
    render json: Fhir::Serializer.operation_outcome(
      ['Access denied: patient consent required'],
      severity: 'error'
    ), status: :forbidden
  end
end
```

### 3. Enhanced Audit Logging (1 day)

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern
  
  included do
    after_create :log_create
    after_update :log_update
    after_destroy :log_destroy
  end
  
  private
  
  def log_create
    AuditLog.create!(
      user: Current.user,
      action: 'create',
      resource_type: self.class.name,
      resource_id: id,
      changes: attributes,
      ip_address: Current.ip_address,
      request_id: Current.request_id
    )
  end
  
  def log_update
    AuditLog.create!(
      user: Current.user,
      action: 'update',
      resource_type: self.class.name,
      resource_id: id,
      changes: saved_changes,
      ip_address: Current.ip_address,
      request_id: Current.request_id
    )
  end
  
  def log_destroy
    AuditLog.create!(
      user: Current.user,
      action: 'destroy',
      resource_type: self.class.name,
      resource_id: id,
      ip_address: Current.ip_address,
      request_id: Current.request_id
    )
  end
end

# Include in ApiResource
class ApiResource < ApplicationRecord
  include Auditable
end
```

## 📅 Week 4: Deployment & Polish

### 1. Create Dockerfile (2 hours)

```dockerfile
# Dockerfile
FROM ruby:3.2-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs postgresql-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7
  
  web:
    build: .
    command: bundle exec rails server -b 0.0.0.0
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db/violet_rails_ehr
      REDIS_URL: redis://redis:6379/1

volumes:
  postgres_data:
```

### 2. Environment Configuration (1 hour)

```bash
# .env.production
DATABASE_URL=postgresql://user:pass@host:5432/dbname
SECRET_KEY_BASE=<generate with: rails secret>
LOCKBOX_MASTER_KEY=<generate with: rails lockbox:generate_key>
BLIND_INDEX_KEY=<generate with: rails lockbox:generate_key>
PHI_ENCRYPTION_KEY=<generate with: rails lockbox:generate_key>

# Whoop
WHOOP_CLIENT_ID=your_production_client_id
WHOOP_CLIENT_SECRET=your_production_client_secret

# FHIR
FHIR_BASE_URL=https://your-domain.com

# Monitoring
SENTRY_DSN=your_sentry_dsn
```

### 3. Deployment Script (1 hour)

```bash
#!/bin/bash
# deploy.sh

set -e

echo "🚀 Deploying Violet Rails EHR..."

# Build Docker image
docker build -t violet-rails-ehr:latest .

# Run migrations
docker-compose run web rails db:migrate

# Setup FHIR namespaces (if first deploy)
docker-compose run web rails runner "FhirNamespaces.create_all!"

# Restart services
docker-compose up -d

# Health check
sleep 5
curl -f http://localhost:3000/health || exit 1

echo "✅ Deployment complete!"
```

### 4. Monitoring Setup (2 hours)

```ruby
# config/initializers/prometheus.rb
require 'prometheus/client'

prometheus = Prometheus::Client.registry

# HTTP request metrics
http_requests = prometheus.counter(
  :http_requests_total,
  docstring: 'Total HTTP requests',
  labels: [:method, :path, :status]
)

# Response time
http_duration = prometheus.histogram(
  :http_request_duration_seconds,
  docstring: 'HTTP request duration',
  labels: [:method, :path]
)

# FHIR resource counts
fhir_resources = prometheus.gauge(
  :fhir_resources_total,
  docstring: 'Total FHIR resources',
  labels: [:resource_type]
)

# app/controllers/metrics_controller.rb
class MetricsController < ApplicationController
  def index
    render plain: Prometheus::Client::Formats::Text.marshal(Prometheus::Client.registry)
  end
end
```

## 🎯 Success Checklist

Before considering the project "production-ready":

- [ ] All 8 FHIR controllers implemented
- [ ] Full test coverage (>80%)
- [ ] FHIR conformance tests passing
- [ ] Performance benchmarks met (p95 < 250ms read, < 400ms write)
- [ ] Encryption configured and tested
- [ ] Consent management implemented
- [ ] Audit logging comprehensive
- [ ] Docker deployment working
- [ ] Monitoring configured
- [ ] Documentation complete
- [ ] Security audit performed
- [ ] Load testing completed

## 📚 Additional Resources to Create

### Documentation
- [ ] API Reference (OpenAPI/Swagger spec)
- [ ] Deployment Guide (AWS, GCP, Azure)
- [ ] Security Best Practices
- [ ] Compliance Checklist (HIPAA, SOC2)
- [ ] Troubleshooting Guide

### Code
- [ ] Rake tasks for common operations
- [ ] Database backup/restore scripts
- [ ] Migration rollback procedures
- [ ] Load testing scripts
- [ ] CI/CD pipeline configuration

## 🚨 Known Limitations & TODOs

1. **Authentication**: Currently no auth on FHIR endpoints (add in production)
2. **Rate Limiting**: No rate limiting implemented
3. **Bulk Operations**: FHIR Bulk Data spec not implemented
4. **Subscriptions**: FHIR Subscriptions not implemented
5. **GraphQL**: No GraphQL API (REST only)
6. **Mobile SDK**: No native mobile libraries

## 💡 Tips for Success

1. **Start small**: Get one resource working perfectly before adding more
2. **Test early**: Write tests as you build controllers
3. **Monitor always**: Set up monitoring from day one
4. **Document continuously**: Update docs as you make changes
5. **Security first**: Don't skip encryption and audit logging
6. **Performance matters**: Profile and optimize early

## 🆘 Getting Stuck?

1. Check `IMPLEMENTATION_GUIDE.md` for detailed patterns
2. Review `PROJECT_SUMMARY.md` for architecture decisions
3. Look at `patients_controller.rb` as reference implementation
4. Test with curl commands from `QUICKSTART.md`
5. Open GitHub issue if you find bugs

---

**Current Status**: 🟢 Ready to implement

**Estimated Time to Production**: 2-3 weeks with 2-person team

**Next Immediate Action**: Complete remaining FHIR controllers
