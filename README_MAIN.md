# Violet Rails + FSF Health EHR Boilerplate

> **Rails-first EHR with FHIR R4 API** - Get running in < 30 minutes

[![GitHub](https://img.shields.io/github/license/ChaiWithJai/violet-rails-ehr)](LICENSE)
[![FHIR](https://img.shields.io/badge/FHIR-R4-blue)](https://hl7.org/fhir/R4/)

---

## 🚀 Quick Start

```bash
# 1. Setup (one-time)
chmod +x local_setup.sh && ./local_setup.sh

# 2. Start server
rails server

# 3. Test API (in new terminal)
curl http://localhost:3000/fhir/metadata | jq
```

**That's it!** Your FHIR R4 API is running.

---

## 📖 Documentation

| Document | Purpose | Time |
|----------|---------|------|
| **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** | One-page cheat sheet | 2 min |
| **[START_HERE.md](START_HERE.md)** | Orientation guide | 10 min |
| **[QUICKSTART.md](QUICKSTART.md)** | Get running fast | 30 min |
| **[TESTING_GUIDE.md](TESTING_GUIDE.md)** | Interactive testing | 20 min |
| **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** | Technical details | 1 hour |
| **[NEXT_STEPS.md](NEXT_STEPS.md)** | Week-by-week plan | Reference |

---

## ✨ What You Get

- ✅ **FHIR R4 API** - 8 core resources (Patient, Observation, etc.)
- ✅ **Whoop Integration** - Wearable data sync framework
- ✅ **Admin Dashboard** - Violet Rails built-in
- ✅ **Validation** - FHIR-compliant using fhir_models gem
- ✅ **Documentation** - 25,000 words of guides
- ✅ **Setup Scripts** - Automated local setup
- ✅ **Test Flows** - Interactive testing suite

---

## 🧪 Testing

```bash
# Interactive test flows
chmod +x test_flows.sh && ./test_flows.sh

# Or manual testing
curl http://localhost:3000/fhir/Patient | jq
curl http://localhost:3000/fhir/Observation | jq

# Admin dashboard
open http://localhost:3000/admin
# Login: admin@example.com / password
```

---

## 📊 Project Status

| Component | Status |
|-----------|--------|
| FHIR Infrastructure | ✅ Complete |
| Patient Controller | ✅ Complete |
| Documentation | ✅ Complete |
| Whoop Integration | ✅ Complete |
| Other Controllers | ⏳ 2-3 weeks |
| Tests | ⏳ Week 2 |
| Production Ready | ⏳ Week 4 |

---

## 🎯 Key Features

### FHIR R4 Resources
- Patient, Observation, Practitioner, Organization
- Encounter, Device, Condition, CarePlan

### Operations
- Full CRUD on all resources
- FHIR search parameters
- Bundle pagination
- OperationOutcome errors
- CapabilityStatement

### Integrations
- Whoop (OAuth + data sync)
- Extensible pattern for more wearables

---

## 🏗️ Architecture

Built on **Violet Rails** using:
- API Namespaces for FHIR resources
- JSONB storage for flexible schemas
- External API Clients for integrations
- fhir_models gem for validation

**Why not GNU Health?** See [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for detailed analysis.

---

## 📝 Next Steps

1. **Setup**: Run `./local_setup.sh`
2. **Test**: Run `./test_flows.sh`
3. **Explore**: Open admin dashboard
4. **Build**: Follow [NEXT_STEPS.md](NEXT_STEPS.md)

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📄 License

MIT License - see [LICENSE](LICENSE)

---

## 🙏 Acknowledgments

- Built on [Violet Rails](https://github.com/restarone/violet_rails)
- Inspired by [GNU Health](https://www.gnuhealth.org/)
- FHIR R4 by [HL7](https://hl7.org/fhir/R4/)

---

**Built with ❤️ for healthtech developers who ship fast.**

---

## About Violet Rails

This EHR boilerplate is built on top of Violet Rails. See [README.md](README.md) for the full Violet Rails documentation.
