# Violet Rails EHR - Quickstart Guide

## 🚀 Get Running in < 30 Minutes

### Prerequisites

- Ruby 3.2+
- PostgreSQL 14+
- Redis (optional, for background jobs)
- Git

### Step 1: Clone and Setup (5 minutes)

```bash
# Clone the repository
cd /Users/shambhavi/CascadeProjects/violet-rails-ehr

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate

# Create FHIR namespaces and seed data
rails runner "load 'db/seeds/fhir_setup.rb'"
```

### Step 2: Start the Server (1 minute)

```bash
# Start Rails server
rails server

# Or use foreman (if configured)
./bin/dev
```

Server will be available at: http://localhost:3000

### Step 3: Test FHIR API (5 minutes)

#### Get CapabilityStatement

```bash
curl http://localhost:3000/fhir/metadata | jq
```

Expected response:
```json
{
  "resourceType": "CapabilityStatement",
  "status": "active",
  "fhirVersion": "4.0.1",
  "format": ["json"],
  "rest": [...]
}
```

#### List Patients

```bash
curl http://localhost:3000/fhir/Patient | jq
```

Expected response:
```json
{
  "resourceType": "Bundle",
  "type": "searchset",
  "total": 3,
  "entry": [
    {
      "fullUrl": "http://localhost:3000/fhir/Patient/1",
      "resource": {
        "resourceType": "Patient",
        "id": "1",
        "name": [{"family": "Smith", "given": ["John"]}],
        ...
      }
    }
  ]
}
```

#### Get Specific Patient

```bash
curl http://localhost:3000/fhir/Patient/1 | jq
```

#### Create New Patient

```bash
curl -X POST http://localhost:3000/fhir/Patient \
  -H "Content-Type: application/json" \
  -d '{
    "resourceType": "Patient",
    "identifier": [{
      "system": "http://hospital.example.org",
      "value": "MRN-9999"
    }],
    "name": [{
      "family": "Doe",
      "given": ["Jane"]
    }],
    "gender": "female",
    "birthDate": "1985-05-15",
    "telecom": [{
      "system": "phone",
      "value": "(555) 555-9999"
    }],
    "address": [{
      "line": ["456 Oak Ave"],
      "city": "Boston",
      "state": "MA",
      "postalCode": "02101"
    }]
  }' | jq
```

#### List Observations

```bash
curl http://localhost:3000/fhir/Observation | jq
```

#### Search Observations by Patient

```bash
curl "http://localhost:3000/fhir/Observation?subject=Patient/1" | jq
```

### Step 4: Access Admin Dashboard (2 minutes)

1. Open browser: http://localhost:3000/admin
2. Login with:
   - Email: `admin@example.com`
   - Password: `password`

3. Navigate to:
   - **API Namespaces** → See FHIR resources
   - **API Resources** → View patient data
   - **External API Clients** → Configure Whoop integration

### Step 5: Configure Whoop Integration (Optional, 10 minutes)

#### 5.1 Get Whoop API Credentials

1. Sign up at https://developer.whoop.com/
2. Create an application
3. Get Client ID and Client Secret

#### 5.2 Set Environment Variables

```bash
export WHOOP_CLIENT_ID=your_client_id
export WHOOP_CLIENT_SECRET=your_client_secret
```

Or add to `.env`:
```
WHOOP_CLIENT_ID=your_client_id
WHOOP_CLIENT_SECRET=your_client_secret
```

#### 5.3 Create External API Client

1. Go to Admin → External API Clients → New
2. Fill in:
   - **Label**: Whoop Sync
   - **API Namespace**: Select "FhirObservation"
   - **Model Definition**: Copy from `app/services/integrations/whoop_sync.rb`
   - **Metadata**: 
     ```json
     {
       "patient_id": "1",
       "access_token": "your_whoop_access_token",
       "refresh_token": "your_whoop_refresh_token"
     }
     ```
3. Save and click "Run" to sync data

#### 5.4 Verify Whoop Data

```bash
# Check for new observations
curl "http://localhost:3000/fhir/Observation?subject=Patient/1&category=vital-signs" | jq
```

You should see observations with codes like:
- `8867-4` (Heart Rate)
- `80404-7` (HRV)
- Custom Whoop codes (recovery-score, strain-score, etc.)

## 🎯 Common Tasks

### Add a New Patient via API

```bash
curl -X POST http://localhost:3000/fhir/Patient \
  -H "Content-Type: application/json" \
  -d @patient.json
```

Where `patient.json`:
```json
{
  "resourceType": "Patient",
  "name": [{"family": "Test", "given": ["User"]}],
  "gender": "other",
  "birthDate": "2000-01-01"
}
```

### Search Patients by Name

```bash
curl "http://localhost:3000/fhir/Patient?name=Smith" | jq
```

### Search Patients by Birthdate

```bash
curl "http://localhost:3000/fhir/Patient?birthdate=1990-01-01" | jq
```

### Get Patient's Observations

```bash
# Get patient ID first
PATIENT_ID=$(curl -s http://localhost:3000/fhir/Patient | jq -r '.entry[0].resource.id')

# Get observations
curl "http://localhost:3000/fhir/Observation?subject=Patient/$PATIENT_ID" | jq
```

### Create an Observation

```bash
curl -X POST http://localhost:3000/fhir/Observation \
  -H "Content-Type: application/json" \
  -d '{
    "resourceType": "Observation",
    "status": "final",
    "category": [{
      "coding": [{
        "system": "http://terminology.hl7.org/CodeSystem/observation-category",
        "code": "vital-signs"
      }]
    }],
    "code": {
      "coding": [{
        "system": "http://loinc.org",
        "code": "8867-4",
        "display": "Heart rate"
      }]
    },
    "subject": {
      "reference": "Patient/1"
    },
    "effectiveDateTime": "2024-01-15T10:30:00Z",
    "valueQuantity": {
      "value": 75,
      "unit": "bpm",
      "system": "http://unitsofmeasure.org",
      "code": "bpm"
    }
  }' | jq
```

## 🔧 Troubleshooting

### Database Connection Error

```bash
# Check PostgreSQL is running
pg_isready

# Recreate database
rails db:drop db:create db:migrate
rails runner "load 'db/seeds/fhir_setup.rb'"
```

### FHIR Namespaces Not Found

```bash
# Recreate FHIR namespaces
rails runner "FhirNamespaces.create_all!"
```

### Port Already in Use

```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use different port
rails server -p 3001
```

### Gem Installation Issues

```bash
# Update bundler
gem install bundler

# Clean and reinstall
rm -rf vendor/bundle
bundle install
```

## 📊 Verify Installation

Run this script to verify everything is working:

```bash
#!/bin/bash

echo "🔍 Verifying Violet Rails EHR installation..."

# Check server is running
if curl -s http://localhost:3000/fhir/metadata > /dev/null; then
  echo "✅ Server is running"
else
  echo "❌ Server is not running. Start with: rails server"
  exit 1
fi

# Check FHIR metadata
if curl -s http://localhost:3000/fhir/metadata | jq -e '.resourceType == "CapabilityStatement"' > /dev/null; then
  echo "✅ FHIR metadata endpoint working"
else
  echo "❌ FHIR metadata endpoint not working"
  exit 1
fi

# Check patients
PATIENT_COUNT=$(curl -s http://localhost:3000/fhir/Patient | jq -r '.total')
if [ "$PATIENT_COUNT" -gt 0 ]; then
  echo "✅ Found $PATIENT_COUNT patients"
else
  echo "⚠️  No patients found. Run: rails runner \"load 'db/seeds/fhir_setup.rb'\""
fi

# Check observations
OBS_COUNT=$(curl -s http://localhost:3000/fhir/Observation | jq -r '.total')
if [ "$OBS_COUNT" -gt 0 ]; then
  echo "✅ Found $OBS_COUNT observations"
else
  echo "⚠️  No observations found"
fi

echo ""
echo "🎉 Installation verified!"
echo ""
echo "📖 Next steps:"
echo "  - Read IMPLEMENTATION_GUIDE.md for detailed docs"
echo "  - Configure Whoop integration (optional)"
echo "  - Add more FHIR resources"
echo "  - Deploy to production"
```

Save as `verify.sh`, make executable, and run:

```bash
chmod +x verify.sh
./verify.sh
```

## 🚀 Next Steps

1. **Read the Implementation Guide**: `IMPLEMENTATION_GUIDE.md`
2. **Explore FHIR Resources**: Try creating Practitioners, Organizations, Encounters
3. **Configure Whoop**: Set up wearable data sync
4. **Customize**: Add your own FHIR resources and integrations
5. **Deploy**: See deployment guide for production setup

## 📚 Resources

- **FHIR R4 Spec**: https://hl7.org/fhir/R4/
- **Violet Rails Docs**: https://github.com/restarone/violet_rails
- **API Reference**: See `docs/api-reference.md`
- **Compliance Guide**: See `docs/compliance.md`

## 🆘 Getting Help

- **GitHub Issues**: Report bugs or request features
- **Documentation**: Check `IMPLEMENTATION_GUIDE.md`
- **Community**: Join our Slack/Discord

---

**Time to first API call**: ⏱️ < 30 minutes ✅

**Ready for production**: 🚀 2-4 weeks (with customization)
