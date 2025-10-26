# Violet Rails EHR - Implementation Guide

## Overview

This implementation uses **Violet Rails' API Namespace system** as the foundation for FHIR R4 resources. Each FHIR resource type (Patient, Observation, etc.) is defined as an API Namespace with FHIR-compliant properties.

## Architecture Decision

After deep analysis of both Violet Rails and GNU Health source code, we chose **Pure Violet Rails** approach because:

1. ✅ **Meets "Rails-first" requirement** - 100% Ruby/Rails development
2. ✅ **Fast time-to-deploy** - 2-4 weeks vs 3-4 months for hybrid
3. ✅ **Minimal dependencies** - No Python/Tryton complexity
4. ✅ **Leverages Violet Rails strengths** - API Namespace, External API Connections, multi-tenant
5. ✅ **Extensible** - Easy to add new FHIR resources and integrations

## Core Components

### 1. FHIR API Namespaces (`config/initializers/fhir_namespaces.rb`)

Each FHIR resource is defined as a Violet Rails API Namespace:

```ruby
ApiNamespace.create(
  name: 'FhirPatient',
  slug: 'fhir-patient',
  properties: {
    resourceType: { type: 'string', default: 'Patient' },
    name: { type: 'array', required: true },
    birthDate: { type: 'date', required: true },
    # ... more FHIR fields
  }
)
```

**Why this works:**
- Violet Rails stores data as JSONB (perfect for FHIR's flexible structure)
- API Namespace provides CRUD operations out-of-box
- Associations map to FHIR references
- Searchable via JSONB queries

### 2. FHIR Validation Layer (`app/services/fhir/validator.rb`)

Uses `fhir_models` gem to validate FHIR resources:

```ruby
Fhir::Validator.validate_patient(data)
# => { valid: true, resource: <FHIR::Patient> }
# or
# => { valid: false, errors: [...], operation_outcome: {...} }
```

### 3. FHIR Serialization (`app/services/fhir/serializer.rb`)

Converts between API Resources and FHIR JSON:

```ruby
# API Resource → FHIR JSON
Fhir::Serializer.to_fhir(api_resource)

# Collection → FHIR Bundle
Fhir::Serializer.to_bundle(resources, 'Patient', request_url)

# Errors → OperationOutcome
Fhir::Serializer.operation_outcome(errors)
```

### 4. FHIR Controllers (`app/controllers/fhir/`)

Standard Rails controllers implementing FHIR REST operations:

```ruby
class Fhir::PatientsController < Fhir::BaseController
  def index   # GET /fhir/Patient
  def show    # GET /fhir/Patient/:id
  def create  # POST /fhir/Patient
  def update  # PUT /fhir/Patient/:id
  def destroy # DELETE /fhir/Patient/:id
end
```

### 5. Whoop Integration (`app/services/integrations/whoop_sync.rb`)

External API Client that syncs Whoop data to FHIR Observations:

```ruby
class WhoopSync
  def start
    sync_recovery_data  # → FHIR Observations (HRV, HR, etc.)
    sync_sleep_data     # → FHIR Observations (sleep duration, quality)
    sync_workout_data   # → FHIR Observations (strain, avg HR)
  end
end
```

## Setup Instructions

### 1. Add Gems

Add to `Gemfile`:

```ruby
gem 'fhir_models', '~> 4.3'
gem 'fhir_client', '~> 5.0'
gem 'lockbox', '~> 1.3'
gem 'blind_index', '~> 2.4'
gem 'oauth2', '~> 2.0'
```

Run: `bundle install`

### 2. Create FHIR Namespaces

```bash
rails runner "FhirNamespaces.create_all!"
```

Or run the seed:

```bash
rails db:seed:fhir
```

### 3. Add Routes

Add to `config/routes.rb`:

```ruby
# Load FHIR routes
load Rails.root.join('config/routes_fhir.rb')
```

### 4. Configure Whoop (Optional)

Set environment variables:

```bash
export WHOOP_CLIENT_ID=your_client_id
export WHOOP_CLIENT_SECRET=your_client_secret
```

Create External API Client in Violet Rails admin:
- Name: "Whoop Sync"
- Model Definition: Copy from `app/services/integrations/whoop_sync.rb`
- Metadata: `{ "patient_id": "1", "access_token": "...", "refresh_token": "..." }`

### 5. Test FHIR API

```bash
# Get CapabilityStatement
curl http://localhost:3000/fhir/metadata

# List patients
curl http://localhost:3000/fhir/Patient

# Create patient
curl -X POST http://localhost:3000/fhir/Patient \
  -H "Content-Type: application/json" \
  -d '{
    "resourceType": "Patient",
    "name": [{"family": "Smith", "given": ["John"]}],
    "gender": "male",
    "birthDate": "1990-01-01"
  }'

# Search observations by patient
curl "http://localhost:3000/fhir/Observation?subject=Patient/1"
```

## FHIR Search Parameters

### Patient Search

```bash
# By name
GET /fhir/Patient?name=Smith

# By birthdate
GET /fhir/Patient?birthdate=1990-01-01

# By gender
GET /fhir/Patient?gender=male

# By identifier
GET /fhir/Patient?identifier=MRN-1234

# By last updated
GET /fhir/Patient?_lastUpdated=ge2024-01-01
```

### Observation Search

```bash
# By patient
GET /fhir/Observation?subject=Patient/1

# By code (LOINC)
GET /fhir/Observation?code=8867-4

# By date range
GET /fhir/Observation?date=ge2024-01-01&date=le2024-12-31

# By category
GET /fhir/Observation?category=vital-signs
```

## Adding New FHIR Resources

### 1. Define API Namespace

Add to `config/initializers/fhir_namespaces.rb`:

```ruby
MEDICATION_REQUEST = {
  name: 'FhirMedicationRequest',
  slug: 'fhir-medication-request',
  properties: {
    resourceType: { type: 'string', default: 'MedicationRequest' },
    status: { type: 'string', required: true },
    intent: { type: 'string', required: true },
    # ... more fields
  }
}
```

### 2. Create Controller

```ruby
# app/controllers/fhir/medication_requests_controller.rb
module Fhir
  class MedicationRequestsController < BaseController
    # Implement CRUD operations
    
    private
    
    def namespace_slug
      'fhir-medication-request'
    end
  end
end
```

### 3. Add Routes

```ruby
# config/routes_fhir.rb
resources :medication_requests, only: [:index, :show, :create, :update, :destroy]
```

### 4. Add Validation

```ruby
# app/services/fhir/validator.rb
def self.validate_medication_request(data)
  validate_resource(FHIR::MedicationRequest, data)
end
```

## Compliance Features

### Audit Logging

Violet Rails has built-in `paper_trail` for audit logging. All API Resource changes are tracked.

To view audit trail:

```ruby
patient = ApiResource.find(1)
patient.versions # All changes
```

### Consent Management

Create a consent API Namespace:

```ruby
ApiNamespace.create(
  name: 'Consent',
  properties: {
    patient_id: { type: 'string', required: true },
    scope: { type: 'string' }, # data-access, research, etc.
    status: { type: 'string' }, # active, inactive
    dateTime: { type: 'datetime' }
  }
)
```

Check consent before data access in controllers.

### Encryption

Add to models:

```ruby
class ApiResource < ApplicationRecord
  # Encrypt PHI fields
  encrypts :properties, key: :encryption_key
  
  def encryption_key
    ENV['PHI_ENCRYPTION_KEY']
  end
end
```

## Performance Optimization

### 1. Add Indexes

```ruby
# db/migrate/xxx_add_fhir_indexes.rb
add_index :api_resources, 
  "(properties->>'birthDate')", 
  name: 'index_patients_on_birth_date',
  where: "api_namespace_id = (SELECT id FROM api_namespaces WHERE slug = 'fhir-patient')"

add_index :api_resources,
  "(properties->>'effectiveDateTime')",
  name: 'index_observations_on_effective_date',
  where: "api_namespace_id = (SELECT id FROM api_namespaces WHERE slug = 'fhir-observation')"
```

### 2. Eager Loading

```ruby
# In controllers
resources = api_namespace.api_resources.includes(:api_namespace)
```

### 3. Caching

```ruby
# Cache FHIR resources
Rails.cache.fetch("fhir/patient/#{id}", expires_in: 5.minutes) do
  Fhir::Serializer.to_fhir(resource)
end
```

## Testing

### Unit Tests

```ruby
# test/services/fhir/validator_test.rb
class Fhir::ValidatorTest < ActiveSupport::TestCase
  test "validates valid patient" do
    data = {
      resourceType: 'Patient',
      name: [{ family: 'Smith', given: ['John'] }],
      birthDate: '1990-01-01'
    }
    
    result = Fhir::Validator.validate_patient(data)
    assert result[:valid]
  end
end
```

### Integration Tests

```ruby
# test/controllers/fhir/patients_controller_test.rb
class Fhir::PatientsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get fhir_patients_url, as: :json
    assert_response :success
    assert_equal 'Bundle', JSON.parse(response.body)['resourceType']
  end
end
```

## Deployment

### Environment Variables

```bash
# Required
DATABASE_URL=postgresql://...
SECRET_KEY_BASE=...
PHI_ENCRYPTION_KEY=...

# Optional
WHOOP_CLIENT_ID=...
WHOOP_CLIENT_SECRET=...
FHIR_BASE_URL=https://your-domain.com
```

### Docker

```dockerfile
FROM ruby:3.2
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
CMD ["rails", "server", "-b", "0.0.0.0"]
```

### Health Checks

```ruby
# config/routes.rb
get '/health', to: proc { [200, {}, ['OK']] }
get '/health/fhir', to: 'fhir/metadata#show'
```

## Troubleshooting

### Issue: FHIR validation fails

**Solution**: Check that `fhir_models` gem is installed and data matches FHIR R4 spec.

### Issue: Whoop sync fails

**Solution**: Check OAuth tokens in External API Client metadata. Refresh tokens if expired.

### Issue: Slow queries

**Solution**: Add JSONB indexes on frequently searched fields.

### Issue: CORS errors

**Solution**: Configure `rack-cors` in Violet Rails (already included).

## Next Steps

1. ✅ **Add more FHIR resources** (Medication, Procedure, etc.)
2. ✅ **Implement SMART-on-FHIR** for OAuth scopes
3. ✅ **Add bulk data export** (FHIR Bulk Data spec)
4. ✅ **Implement CDS Hooks** for clinical decision support
5. ✅ **Add HL7 v2 message parsing** for legacy systems
6. ✅ **Build mobile app** using Violet Rails iOS client

## Resources

- [FHIR R4 Specification](https://hl7.org/fhir/R4/)
- [Violet Rails Documentation](https://github.com/restarone/violet_rails)
- [fhir_models Gem](https://github.com/fhir-crucible/fhir_models)
- [Whoop API Docs](https://developer.whoop.com/)

## Support

- GitHub Issues: [Create an issue](https://github.com/your-org/violet-rails-ehr/issues)
- Email: support@violet-rails-ehr.com
- Slack: [Join our community](#)

---

**Built with ❤️ for healthtech developers**
