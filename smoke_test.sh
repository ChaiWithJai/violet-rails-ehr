#!/bin/bash
set -e

echo "🔍 VIOLET RAILS EHR - SMOKE TEST"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "1. Checking file structure..."
echo "------------------------------"

# Check core implementation files
[ -f "config/initializers/fhir_namespaces.rb" ] && pass "FHIR namespaces config exists" || fail "Missing fhir_namespaces.rb"
[ -f "config/routes_fhir.rb" ] && pass "FHIR routes config exists" || fail "Missing routes_fhir.rb"
[ -f "app/controllers/fhir/base_controller.rb" ] && pass "FHIR base controller exists" || fail "Missing base_controller.rb"
[ -f "app/controllers/fhir/patients_controller.rb" ] && pass "Patient controller exists" || fail "Missing patients_controller.rb"
[ -f "app/services/fhir/validator.rb" ] && pass "FHIR validator exists" || fail "Missing validator.rb"
[ -f "app/services/fhir/serializer.rb" ] && pass "FHIR serializer exists" || fail "Missing serializer.rb"
[ -f "app/services/integrations/whoop_sync.rb" ] && pass "Whoop integration exists" || fail "Missing whoop_sync.rb"
[ -f "db/seeds/fhir_setup.rb" ] && pass "FHIR setup seed exists" || fail "Missing fhir_setup.rb"

echo ""
echo "2. Checking documentation..."
echo "----------------------------"

[ -f "START_HERE.md" ] && pass "START_HERE.md exists" || fail "Missing START_HERE.md"
[ -f "QUICKSTART.md" ] && pass "QUICKSTART.md exists" || fail "Missing QUICKSTART.md"
[ -f "IMPLEMENTATION_GUIDE.md" ] && pass "IMPLEMENTATION_GUIDE.md exists" || fail "Missing IMPLEMENTATION_GUIDE.md"
[ -f "PROJECT_SUMMARY.md" ] && pass "PROJECT_SUMMARY.md exists" || fail "Missing PROJECT_SUMMARY.md"
[ -f "NEXT_STEPS.md" ] && pass "NEXT_STEPS.md exists" || fail "Missing NEXT_STEPS.md"
[ -f "SHIP.md" ] && pass "SHIP.md exists" || fail "Missing SHIP.md"
[ -f "MANIFEST.md" ] && pass "MANIFEST.md exists" || fail "Missing MANIFEST.md"

echo ""
echo "3. Validating Ruby syntax..."
echo "----------------------------"

# Check Ruby syntax for all our files
for file in config/initializers/fhir_namespaces.rb \
            app/controllers/fhir/*.rb \
            app/services/fhir/*.rb \
            app/services/integrations/whoop_sync.rb \
            db/seeds/fhir_setup.rb; do
    if [ -f "$file" ]; then
        if ruby -c "$file" > /dev/null 2>&1; then
            pass "$(basename $file) - syntax OK"
        else
            fail "$(basename $file) - syntax error"
        fi
    fi
done

echo ""
echo "4. Checking FHIR namespace definitions..."
echo "------------------------------------------"

# Count FHIR resources defined
if grep -q "PATIENT = {" config/initializers/fhir_namespaces.rb; then
    pass "Patient resource defined"
else
    fail "Patient resource not found"
fi

if grep -q "OBSERVATION = {" config/initializers/fhir_namespaces.rb; then
    pass "Observation resource defined"
else
    fail "Observation resource not found"
fi

if grep -q "PRACTITIONER = {" config/initializers/fhir_namespaces.rb; then
    pass "Practitioner resource defined"
else
    fail "Practitioner resource not found"
fi

# Count total resources
resource_count=$(grep -c "name: 'Fhir" config/initializers/fhir_namespaces.rb || echo "0")
pass "Total FHIR resources defined: $resource_count"

echo ""
echo "5. Checking routes configuration..."
echo "-----------------------------------"

if grep -q "namespace :fhir" config/routes_fhir.rb; then
    pass "FHIR namespace route defined"
else
    fail "FHIR namespace route not found"
fi

if grep -q "resources :patients" config/routes_fhir.rb; then
    pass "Patient routes defined"
else
    fail "Patient routes not found"
fi

echo ""
echo "6. Checking Whoop integration..."
echo "--------------------------------"

if grep -q "class WhoopSync" app/services/integrations/whoop_sync.rb; then
    pass "WhoopSync class defined"
else
    fail "WhoopSync class not found"
fi

if grep -q "def sync_recovery_data" app/services/integrations/whoop_sync.rb; then
    pass "Recovery data sync method exists"
else
    fail "Recovery data sync method not found"
fi

if grep -q "LOINC_HEART_RATE" app/services/integrations/whoop_sync.rb; then
    pass "LOINC codes defined"
else
    fail "LOINC codes not found"
fi

echo ""
echo "7. Checking documentation quality..."
echo "------------------------------------"

# Check word counts
start_here_words=$(wc -w < START_HERE.md)
quickstart_words=$(wc -w < QUICKSTART.md)
impl_guide_words=$(wc -w < IMPLEMENTATION_GUIDE.md)

pass "START_HERE.md: $start_here_words words"
pass "QUICKSTART.md: $quickstart_words words"
pass "IMPLEMENTATION_GUIDE.md: $impl_guide_words words"

total_doc_words=$((start_here_words + quickstart_words + impl_guide_words))
pass "Total documentation: ~$total_doc_words words"

echo ""
echo "8. Code statistics..."
echo "--------------------"

# Count lines of code
total_lines=$(find app/controllers/fhir app/services/fhir app/services/integrations config/initializers/fhir_namespaces.rb -name "*.rb" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
pass "Total lines of implementation code: $total_lines"

echo ""
echo "9. Git status..."
echo "---------------"

if git remote get-url origin | grep -q "ChaiWithJai/violet-rails-ehr"; then
    pass "Git remote configured correctly"
else
    warn "Git remote may not be configured"
fi

if git log -1 --oneline | grep -q "feat: Add Violet Rails EHR"; then
    pass "Latest commit is EHR boilerplate"
else
    warn "Latest commit doesn't match expected"
fi

echo ""
echo "=================================="
echo "🎉 SMOKE TEST COMPLETE"
echo "=================================="
echo ""
echo "Summary:"
echo "--------"
echo "✓ All core files present"
echo "✓ All documentation present"
echo "✓ Ruby syntax valid"
echo "✓ FHIR resources defined"
echo "✓ Routes configured"
echo "✓ Whoop integration ready"
echo "✓ ~$total_doc_words words of documentation"
echo "✓ ~$total_lines lines of code"
echo ""
echo "Status: 🟢 READY FOR IMPLEMENTATION"
echo ""
echo "Next steps:"
echo "1. Read START_HERE.md"
echo "2. Run bundle install (may need Ruby 2.6.6)"
echo "3. Follow QUICKSTART.md"
echo ""
