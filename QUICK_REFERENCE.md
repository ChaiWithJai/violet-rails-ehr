# 🚀 Quick Reference - Violet Rails EHR

## One-Command Setup

```bash
chmod +x local_setup.sh && ./local_setup.sh
```

## Start Server

```bash
rails server
# Server at: http://localhost:3000
```

## Run Tests

```bash
chmod +x test_flows.sh && ./test_flows.sh
```

## Essential Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/fhir/metadata` | GET | Server capabilities |
| `/fhir/Patient` | GET | List patients |
| `/fhir/Patient/:id` | GET | Get patient |
| `/fhir/Patient` | POST | Create patient |
| `/fhir/Patient/:id` | PUT | Update patient |
| `/fhir/Patient/:id` | DELETE | Delete patient |
| `/fhir/Observation` | GET | List observations |
| `/admin` | GET | Admin dashboard |

## Quick Tests

```bash
# Metadata
curl http://localhost:3000/fhir/metadata | jq

# List patients
curl http://localhost:3000/fhir/Patient | jq

# Get patient
curl http://localhost:3000/fhir/Patient/1 | jq

# Create patient
curl -X POST http://localhost:3000/fhir/Patient \
  -H "Content-Type: application/json" \
  -d '{"resourceType":"Patient","name":[{"family":"Test"}],"birthDate":"2000-01-01"}' | jq
```

## Admin Login

- **URL**: http://localhost:3000/admin
- **Email**: admin@example.com
- **Password**: password

## Common Commands

```bash
# Reset database
rails db:drop db:create db:migrate
rails runner "load 'db/seeds/fhir_setup.rb'"

# Check routes
rails routes | grep fhir

# Rails console
rails console

# Run smoke test
./smoke_test.sh

# View logs
tail -f log/development.log
```

## File Locations

- **FHIR Definitions**: `config/initializers/fhir_namespaces.rb`
- **Controllers**: `app/controllers/fhir/`
- **Services**: `app/services/fhir/`
- **Routes**: `config/routes_fhir.rb`
- **Seeds**: `db/seeds/fhir_setup.rb`

## Documentation

- **START_HERE.md** - Start here!
- **QUICKSTART.md** - 30-min setup
- **TESTING_GUIDE.md** - All test flows
- **IMPLEMENTATION_GUIDE.md** - Technical details
- **NEXT_STEPS.md** - What to build next

## Troubleshooting

```bash
# Port in use
lsof -ti:3000 | xargs kill -9

# Bundle issues
rm -rf vendor/bundle && bundle install

# Ruby version
rbenv install 2.6.6 && rbenv local 2.6.6
```

## Next Steps

1. Run `./local_setup.sh`
2. Run `./test_flows.sh`
3. Open http://localhost:3000/admin
4. Follow `NEXT_STEPS.md`

---

**Need help?** Read `TESTING_GUIDE.md` for detailed flows.
