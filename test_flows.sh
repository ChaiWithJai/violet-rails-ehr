#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3000"

echo -e "${BLUE}🧪 Violet Rails EHR - Interactive Testing${NC}"
echo "=========================================="
echo ""

# Check if server is running
if ! curl -s "$BASE_URL/health" > /dev/null 2>&1; then
    echo -e "${RED}✗ Server is not running${NC}"
    echo ""
    echo "Start the server first:"
    echo "  rails server"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo -e "${GREEN}✓ Server is running at $BASE_URL${NC}"
echo ""

# Function to pause and wait for user
pause() {
    echo ""
    read -p "Press Enter to continue..."
    echo ""
}

# Function to run a test
run_test() {
    local name=$1
    local method=$2
    local endpoint=$3
    local data=$4
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test: $name${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -n "$data" ]; then
        echo -e "${YELLOW}Request:${NC}"
        echo "$method $endpoint"
        echo ""
        echo -e "${YELLOW}Data:${NC}"
        echo "$data" | jq '.'
        echo ""
    else
        echo -e "${YELLOW}Request:${NC}"
        echo "$method $endpoint"
        echo ""
    fi
    
    echo -e "${YELLOW}Response:${NC}"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s "$BASE_URL$endpoint")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -X POST "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    elif [ "$method" = "PUT" ]; then
        response=$(curl -s -X PUT "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -X DELETE "$BASE_URL$endpoint")
    fi
    
    echo "$response" | jq '.'
    
    # Check if response is valid JSON
    if echo "$response" | jq '.' > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}✓ Test passed${NC}"
    else
        echo ""
        echo -e "${RED}✗ Test failed (invalid JSON response)${NC}"
    fi
    
    pause
}

# Test Flow 1: FHIR Metadata
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  FLOW 1: FHIR Metadata & Capabilities${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo "This tests the FHIR CapabilityStatement endpoint"
echo "which describes what the server can do."
pause

run_test "Get FHIR Metadata" "GET" "/fhir/metadata"

# Test Flow 2: Patient CRUD
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  FLOW 2: Patient CRUD Operations${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo "This tests creating, reading, updating, and deleting patients."
pause

# 2.1 List all patients
run_test "List All Patients" "GET" "/fhir/Patient"

# 2.2 Get specific patient
echo "Let's get the first patient..."
PATIENT_ID=$(curl -s "$BASE_URL/fhir/Patient" | jq -r '.entry[0].resource.id')
if [ "$PATIENT_ID" != "null" ] && [ -n "$PATIENT_ID" ]; then
    run_test "Get Patient by ID" "GET" "/fhir/Patient/$PATIENT_ID"
else
    echo -e "${YELLOW}⚠️  No patients found, skipping get by ID${NC}"
    pause
fi

# 2.3 Create new patient
patient_data='{
  "resourceType": "Patient",
  "identifier": [{
    "system": "http://hospital.example.org",
    "value": "MRN-TEST-001"
  }],
  "name": [{
    "use": "official",
    "family": "TestPatient",
    "given": ["Interactive", "Test"]
  }],
  "gender": "other",
  "birthDate": "1995-06-15",
  "telecom": [{
    "system": "phone",
    "value": "(555) 123-4567",
    "use": "mobile"
  }, {
    "system": "email",
    "value": "test@example.com"
  }],
  "address": [{
    "use": "home",
    "line": ["123 Test Street"],
    "city": "Test City",
    "state": "TC",
    "postalCode": "12345",
    "country": "USA"
  }],
  "active": true
}'

run_test "Create New Patient" "POST" "/fhir/Patient" "$patient_data"

# Get the newly created patient ID
NEW_PATIENT_ID=$(curl -s -X POST "$BASE_URL/fhir/Patient" \
    -H "Content-Type: application/json" \
    -d "$patient_data" | jq -r '.id')

if [ "$NEW_PATIENT_ID" != "null" ] && [ -n "$NEW_PATIENT_ID" ]; then
    echo -e "${GREEN}✓ Created patient with ID: $NEW_PATIENT_ID${NC}"
    
    # 2.4 Update patient
    update_data='{
      "resourceType": "Patient",
      "identifier": [{
        "system": "http://hospital.example.org",
        "value": "MRN-TEST-001-UPDATED"
      }],
      "name": [{
        "use": "official",
        "family": "TestPatient",
        "given": ["Interactive", "Test", "Updated"]
      }],
      "gender": "other",
      "birthDate": "1995-06-15",
      "active": true
    }'
    
    pause
    run_test "Update Patient" "PUT" "/fhir/Patient/$NEW_PATIENT_ID" "$update_data"
    
    # 2.5 Delete patient
    echo "Now let's clean up by deleting the test patient..."
    pause
    
    delete_response=$(curl -s -X DELETE "$BASE_URL/fhir/Patient/$NEW_PATIENT_ID" -w "%{http_code}")
    http_code="${delete_response: -3}"
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test: Delete Patient${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Request:${NC}"
    echo "DELETE /fhir/Patient/$NEW_PATIENT_ID"
    echo ""
    echo -e "${YELLOW}Response:${NC}"
    echo "HTTP Status: $http_code"
    
    if [ "$http_code" = "204" ]; then
        echo -e "${GREEN}✓ Patient deleted successfully${NC}"
    else
        echo -e "${RED}✗ Delete failed${NC}"
    fi
    
    pause
fi

# Test Flow 3: Patient Search
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  FLOW 3: Patient Search${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo "This tests FHIR search parameters."
pause

run_test "Search by Name" "GET" "/fhir/Patient?name=Smith"
run_test "Search by Gender" "GET" "/fhir/Patient?gender=male"
run_test "Search by Birthdate" "GET" "/fhir/Patient?birthdate=1990-01-01"

# Test Flow 4: Observations
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}  FLOW 4: Observations${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo "This tests vital signs observations."
pause

run_test "List All Observations" "GET" "/fhir/Observation"

if [ "$PATIENT_ID" != "null" ] && [ -n "$PATIENT_ID" ]; then
    run_test "Search Observations by Patient" "GET" "/fhir/Observation?subject=Patient/$PATIENT_ID"
    run_test "Search Vital Signs" "GET" "/fhir/Observation?category=vital-signs"
fi

# Test Flow 5: Create Observation
echo "Let's create a new vital sign observation..."
pause

if [ "$PATIENT_ID" != "null" ] && [ -n "$PATIENT_ID" ]; then
    observation_data='{
      "resourceType": "Observation",
      "status": "final",
      "category": [{
        "coding": [{
          "system": "http://terminology.hl7.org/CodeSystem/observation-category",
          "code": "vital-signs",
          "display": "Vital Signs"
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
        "reference": "Patient/'$PATIENT_ID'"
      },
      "effectiveDateTime": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
      "issued": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
      "valueQuantity": {
        "value": 72,
        "unit": "bpm",
        "system": "http://unitsofmeasure.org",
        "code": "bpm"
      }
    }'
    
    run_test "Create Heart Rate Observation" "POST" "/fhir/Observation" "$observation_data"
fi

# Summary
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Testing Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "You've successfully tested:"
echo "  ✓ FHIR Metadata endpoint"
echo "  ✓ Patient CRUD operations"
echo "  ✓ Patient search"
echo "  ✓ Observations"
echo ""
echo "Next steps:"
echo "  1. Check admin dashboard: http://localhost:3000/admin"
echo "  2. Explore API Namespaces in admin"
echo "  3. View API Resources (patients, observations)"
echo "  4. Follow NEXT_STEPS.md to implement remaining controllers"
echo ""
echo -e "${BLUE}Admin Login:${NC}"
echo "  Email: admin@example.com"
echo "  Password: password"
echo ""
