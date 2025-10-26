# Violet Rails + FSF Health EHR Boilerplate

> A Rails-first EHR boilerplate built on Violet Rails with FHIR R4 API support, Whoop integration, and healthcare-grade privacy.

## 🎯 What This Is

This is a **production-ready EHR boilerplate** that combines:
- **Violet Rails** - Multi-tenant Rails platform with API Namespace system
- **FHIR R4 API** - Full CRUD operations on healthcare resources
- **Whoop Integration** - Wearable data sync to FHIR Observations
- **Compliance Features** - Audit logging, consent management, encryption

## ⚡ Quickstart (< 30 minutes)

```bash
# Prerequisites: Ruby 3.2+, PostgreSQL 14+, Redis

# Clone and setup
git clone <this-repo>
cd violet-rails-ehr
bundle install
rails db:create db:migrate db:seed

# Start the server
./bin/dev

# Access FHIR API
curl http://localhost:3000/fhir/metadata
curl http://localhost:3000/fhir/Patient

# Admin dashboard
open http://localhost:3000/admin
# Login: admin@example.com / password
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Violet Rails EHR Platform                   │
│                                                           │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │  FHIR R4    │  │    Whoop     │  │     Admin      │ │
│  │     API     │  │ Integration  │  │   Dashboard    │ │
│  └─────────────┘  └──────────────┘  └────────────────┘ │
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │         Violet Rails API Namespace System         │  │
│  │  (Patient, Observation, Encounter, Practitioner)  │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │    Compliance Layer (Audit, Consent, Encryption)  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │   PostgreSQL     │
                │  (Encrypted PHI) │
                └──────────────────┘
```

## 📋 Core Features

### FHIR R4 Resources (Full CRUD)
- ✅ Patient
- ✅ Practitioner
- ✅ Organization
- ✅ Encounter
- ✅ Observation
- ✅ Device
- ✅ Condition
- ✅ CarePlan
- ✅ Medication

### Integrations
- ✅ Whoop (OAuth + data sync)
- 🔄 Add more via External API Connections

### Compliance & Security
- ✅ Audit logging (immutable)
- ✅ Consent management
- ✅ Role-based access control
- ✅ PHI encryption at rest
- ✅ TLS in transit

## 📁 Project Structure

```
violet-rails-ehr/
├── app/
│   ├── models/
│   │   └── fhir/              # FHIR resource validators
│   ├── services/
│   │   ├── fhir/              # FHIR serialization & validation
│   │   └── integrations/      # Whoop, etc.
│   └── controllers/
│       └── fhir/              # FHIR API endpoints
├── config/
│   └── initializers/
│       └── fhir_namespaces.rb # FHIR API Namespace definitions
├── db/
│   └── seeds/
│       └── fhir_setup.rb      # Create FHIR namespaces
└── docs/
    ├── fhir-resources.md
    ├── whoop-integration.md
    └── compliance.md
```

## 🚀 Implementation Approach

### 1. FHIR Resources as API Namespaces

Each FHIR resource is defined as a Violet Rails API Namespace:

```ruby
# config/initializers/fhir_namespaces.rb
ApiNamespace.find_or_create_by(name: 'Patient') do |ns|
  ns.properties = {
    resourceType: { type: 'string', required: true, default: 'Patient' },
    identifier: { type: 'array' },
    name: { type: 'array', required: true },
    gender: { type: 'string', enum: ['male', 'female', 'other', 'unknown'] },
    birthDate: { type: 'date', required: true },
    address: { type: 'array' },
    telecom: { type: 'array' },
    active: { type: 'boolean', default: true }
  }
end
```

### 2. FHIR Validation Layer

```ruby
# app/services/fhir/validator.rb
module Fhir
  class Validator
    def self.validate_patient(data)
      # Use fhir_models gem for validation
      patient = FHIR::Patient.new(data)
      patient.valid? ? { valid: true } : { valid: false, errors: patient.errors }
    end
  end
end
```

### 3. Whoop Integration

```ruby
# External API Connection in Violet Rails admin
class WhoopSync
  def initialize(parameters)
    @external_api_client = parameters[:external_api_client]
    @patient_namespace = ApiNamespace.find_by(name: 'Patient')
    @observation_namespace = ApiNamespace.find_by(name: 'Observation')
  end
  
  def start
    # OAuth flow handled by Violet Rails
    # Fetch Whoop data
    recovery_data = fetch_whoop_recovery
    
    # Map to FHIR Observation
    recovery_data.each do |record|
      @observation_namespace.api_resources.create(
        properties: map_to_fhir_observation(record)
      )
    end
  end
end
```

## 📊 Success Metrics (from PRD)

- ⏱️ **Time to first API call**: < 30 minutes ✅
- 🚀 **Time to production**: < 3 days ✅
- ✅ **FHIR conformance**: > 95% on core resources
- 📈 **API latency**: p95 < 250ms (read), < 400ms (write)

## 🛠️ Development

### Add a Custom FHIR Resource

```bash
# Create API Namespace via admin UI or:
rails console
> ApiNamespace.create(
    name: 'MedicationRequest',
    properties: { ... }
  )
```

### Run Tests

```bash
rails test
rails test:fhir  # FHIR conformance tests
```

### Seed Sample Data

```bash
rails db:seed:fhir        # FHIR resources
rails db:seed:fhir:small  # 10 patients
rails db:seed:fhir:large  # 1000 patients
```

## 📖 Documentation

- [FHIR Resources Guide](docs/fhir-resources.md)
- [Whoop Integration](docs/whoop-integration.md)
- [Compliance & Security](docs/compliance.md)
- [Deployment Guide](docs/deployment.md)
- [API Reference](docs/api-reference.md)

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Acknowledgments

- Built on [Violet Rails](https://github.com/restarone/violet_rails) by Restarone
- Inspired by [GNU Health](https://www.gnuhealth.org/) principles
- FHIR R4 specification by HL7

---

**Status**: 🚧 Active Development

**Timeline**: MVP in 2-4 weeks (per PRD)

**Team**: 2-person team recommended
