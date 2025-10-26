# 🧪 Testing Guide - Violet Rails EHR

## Quick Start

### 1. Setup (One-time)

```bash
# Make scripts executable
chmod +x local_setup.sh test_flows.sh

# Run setup
./local_setup.sh
```

This will:
- ✅ Check/install Ruby 2.6.6
- ✅ Install dependencies
- ✅ Setup PostgreSQL database
- ✅ Load FHIR namespaces
- ✅ Create sample data
- ✅ Start the server

### 2. Run Interactive Tests

```bash
# In a new terminal (while server is running)
./test_flows.sh
```

This will walk you through:
- ✅ FHIR Metadata endpoint
- ✅ Patient CRUD operations
- ✅ Patient search
- ✅ Observations
- ✅ Creating vital signs

---

## Manual Testing Flows

### Flow 1: FHIR Metadata

**Test**: Server capabilities

```bash
curl http://localhost:3000/fhir/metadata | jq
```

**Expected Response**:
```json
{
  "resourceType": "CapabilityStatement",
  "status": "active",
  "fhirVersion": "4.0.1",
  "format": ["json"],
  "rest": [
    {
      "mode": "server",
      "resource": [
        {
          "type": "Patient",
          "interaction": [
            {"code": "read"},
            {"code": "create"},
            {"code": "update"},
            {"code": "delete"},
            {"code": "search-type"}
          ]
        }
      ]
    }
  ]
}
```

**✅ Pass Criteria**: Returns CapabilityStatement with 8 resources

---

### Flow 2: List Patients

**Test**: Get all patients

```bash
curl http://localhost:3000/fhir/Patient | jq
```

**Expected Response**:
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
        "gender": "male",
        "birthDate": "1994-10-26"
      }
    }
  ]
}
```

**✅ Pass Criteria**: Returns Bundle with 3 sample patients

---

### Flow 3: Get Specific Patient

**Test**: Get patient by ID

```bash
curl http://localhost:3000/fhir/Patient/1 | jq
```

**Expected Response**:
```json
{
  "resourceType": "Patient",
  "id": "1",
  "meta": {
    "versionId": "...",
    "lastUpdated": "2025-10-26T..."
  },
  "name": [{"family": "Smith", "given": ["John"]}],
  "gender": "male",
  "birthDate": "1994-10-26",
  "active": true
}
```

**✅ Pass Criteria**: Returns single Patient resource

---

### Flow 4: Create Patient

**Test**: Create new patient

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
    "active": true
  }' | jq
```

**Expected Response**:
```json
{
  "resourceType": "Patient",
  "id": "4",
  "meta": {
    "versionId": "...",
    "lastUpdated": "2025-10-26T..."
  },
  "identifier": [{
    "system": "http://hospital.example.org",
    "value": "MRN-9999"
  }],
  "name": [{"family": "Doe", "given": ["Jane"]}],
  "gender": "female",
  "birthDate": "1985-05-15",
  "active": true
}
```

**✅ Pass Criteria**: Returns created Patient with new ID

---

### Flow 5: Update Patient

**Test**: Update existing patient

```bash
curl -X PUT http://localhost:3000/fhir/Patient/4 \
  -H "Content-Type: application/json" \
  -d '{
    "resourceType": "Patient",
    "name": [{
      "family": "Doe-Smith",
      "given": ["Jane", "Marie"]
    }],
    "gender": "female",
    "birthDate": "1985-05-15",
    "active": true
  }' | jq
```

**Expected Response**:
```json
{
  "resourceType": "Patient",
  "id": "4",
  "meta": {
    "versionId": "...",
    "lastUpdated": "2025-10-26T..." 
  },
  "name": [{"family": "Doe-Smith", "given": ["Jane", "Marie"]}],
  "gender": "female",
  "birthDate": "1985-05-15",
  "active": true
}
```

**✅ Pass Criteria**: Returns updated Patient with new lastUpdated

---

### Flow 6: Delete Patient

**Test**: Delete patient

```bash
curl -X DELETE http://localhost:3000/fhir/Patient/4 -v
```

**Expected Response**:
```
HTTP/1.1 204 No Content
```

**✅ Pass Criteria**: Returns 204 status, patient no longer exists

---

### Flow 7: Search Patients by Name

**Test**: Search with name parameter

```bash
curl "http://localhost:3000/fhir/Patient?name=Smith" | jq
```

**Expected Response**:
```json
{
  "resourceType": "Bundle",
  "type": "searchset",
  "total": 1,
  "entry": [
    {
      "resource": {
        "resourceType": "Patient",
        "name": [{"family": "Smith", "given": ["John"]}]
      }
    }
  ]
}
```

**✅ Pass Criteria**: Returns Bundle with matching patients

---

### Flow 8: Search by Gender

**Test**: Search with gender parameter

```bash
curl "http://localhost:3000/fhir/Patient?gender=male" | jq
```

**✅ Pass Criteria**: Returns only male patients

---

### Flow 9: Search by Birthdate

**Test**: Search with birthdate parameter

```bash
curl "http://localhost:3000/fhir/Patient?birthdate=1994-10-26" | jq
```

**✅ Pass Criteria**: Returns patients born on that date

---

### Flow 10: List Observations

**Test**: Get all observations

```bash
curl http://localhost:3000/fhir/Observation | jq
```

**Expected Response**:
```json
{
  "resourceType": "Bundle",
  "type": "searchset",
  "total": 12,
  "entry": [
    {
      "resource": {
        "resourceType": "Observation",
        "status": "final",
        "category": [{
          "coding": [{
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
        "valueQuantity": {
          "value": 72,
          "unit": "bpm"
        }
      }
    }
  ]
}
```

**✅ Pass Criteria**: Returns Bundle with sample observations

---

### Flow 11: Search Observations by Patient

**Test**: Get observations for specific patient

```bash
curl "http://localhost:3000/fhir/Observation?subject=Patient/1" | jq
```

**✅ Pass Criteria**: Returns observations linked to patient 1

---

### Flow 12: Create Observation

**Test**: Create vital sign observation

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
    "effectiveDateTime": "2025-10-26T12:00:00Z",
    "valueQuantity": {
      "value": 75,
      "unit": "bpm",
      "system": "http://unitsofmeasure.org",
      "code": "bpm"
    }
  }' | jq
```

**✅ Pass Criteria**: Returns created Observation with ID

---

## Admin Dashboard Testing

### Flow 13: Access Admin Dashboard

1. **Open**: http://localhost:3000/admin
2. **Login**:
   - Email: `admin@example.com`
   - Password: `password`

**✅ Pass Criteria**: Successfully logged in

---

### Flow 14: View API Namespaces

1. Navigate to **API Namespaces**
2. Look for FHIR namespaces:
   - FhirPatient
   - FhirObservation
   - FhirPractitioner
   - FhirOrganization
   - FhirEncounter
   - FhirDevice
   - FhirCondition
   - FhirCarePlan

**✅ Pass Criteria**: All 8 FHIR namespaces visible

---

### Flow 15: View API Resources

1. Navigate to **API Resources**
2. Filter by namespace: `FhirPatient`
3. View patient records

**✅ Pass Criteria**: See 3 sample patients

---

### Flow 16: View Observations

1. Navigate to **API Resources**
2. Filter by namespace: `FhirObservation`
3. View observation records

**✅ Pass Criteria**: See vital sign observations

---

## Error Testing

### Flow 17: Invalid Patient Creation

**Test**: Try to create patient without required fields

```bash
curl -X POST http://localhost:3000/fhir/Patient \
  -H "Content-Type: application/json" \
  -d '{
    "resourceType": "Patient"
  }' | jq
```

**Expected Response**:
```json
{
  "resourceType": "OperationOutcome",
  "issue": [{
    "severity": "error",
    "code": "invalid",
    "diagnostics": "name is required"
  }]
}
```

**✅ Pass Criteria**: Returns OperationOutcome with validation errors

---

### Flow 18: Patient Not Found

**Test**: Try to get non-existent patient

```bash
curl http://localhost:3000/fhir/Patient/99999 | jq
```

**Expected Response**:
```json
{
  "resourceType": "OperationOutcome",
  "issue": [{
    "severity": "error",
    "code": "not-found",
    "diagnostics": "Patient with id 99999 not found"
  }]
}
```

**✅ Pass Criteria**: Returns 404 with OperationOutcome

---

## Performance Testing

### Flow 19: Response Time

**Test**: Measure API latency

```bash
time curl -s http://localhost:3000/fhir/Patient > /dev/null
```

**✅ Pass Criteria**: Response time < 250ms (p95)

---

### Flow 20: Bulk Query

**Test**: Query with pagination

```bash
curl "http://localhost:3000/fhir/Patient?_count=10" | jq
```

**✅ Pass Criteria**: Returns max 10 results

---

## Test Summary Checklist

After running all flows, verify:

- [ ] FHIR Metadata endpoint works
- [ ] Can list all patients
- [ ] Can get specific patient
- [ ] Can create patient
- [ ] Can update patient
- [ ] Can delete patient
- [ ] Can search by name
- [ ] Can search by gender
- [ ] Can search by birthdate
- [ ] Can list observations
- [ ] Can search observations by patient
- [ ] Can create observation
- [ ] Admin dashboard accessible
- [ ] Can view API Namespaces
- [ ] Can view API Resources
- [ ] Validation errors work
- [ ] 404 errors work
- [ ] Response times acceptable

---

## Troubleshooting

### Server won't start

```bash
# Check if port 3000 is in use
lsof -ti:3000 | xargs kill -9

# Restart server
rails server
```

### Database errors

```bash
# Reset database
rails db:drop db:create db:migrate
rails runner "load 'db/seeds/fhir_setup.rb'"
```

### Ruby version issues

```bash
# Install correct Ruby version
rbenv install 2.6.6
rbenv local 2.6.6

# Or update to current
echo "3.4.7" > .ruby-version
```

### Bundle install fails

```bash
# Update bundler
gem install bundler

# Clean and reinstall
rm -rf vendor/bundle
bundle install
```

---

## Next Steps

After testing locally:

1. ✅ All tests passing? Great!
2. 📝 Follow `NEXT_STEPS.md` to implement remaining controllers
3. 🧪 Add automated tests (Week 2)
4. 🔒 Add security features (Week 3)
5. 🚀 Deploy to production (Week 4)

---

**Happy Testing!** 🧪
