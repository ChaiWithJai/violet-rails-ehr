# Vibe Coding Cheat Sheet
## Quick Reference for Scoping Violet Rails Solutions

---

## The 5-Minute Scoping Framework

### 1. The Job (30 seconds)
```
When [WHO] needs [WHAT], they can [HOW], so that [WHY].
```

**Example:** When a billing specialist needs temporary EMR access, they can submit a request, have it approved by compliance, so that patient claims are processed accurately.

---

### 2. The Actors (1 minute)
| Actor | Does | Sees | Decides |
|-------|------|------|---------|
| Requester | Submits | Status | Revise if rejected |
| Approver | Reviews | Queue | Approve/Reject |
| Admin | Configures | Dashboard | Policy changes |
| Auditor | Investigates | Logs | Compliance status |
| System | Automates | Rules | Risk scoring |

---

### 3. The States (1 minute)
```
draft → submitted → reviewing → approved → active → expired
                  ↓
                rejected → awaiting_rework
```

**Questions:**
- What's the starting state?
- What's the "done" state?
- What's the "it failed" state?
- What states can go backwards?

---

### 4. The Screens (1.5 minutes)
1. **Intake form** - How users start
2. **Queue/List** - Where work piles up
3. **Detail view** - Everything about one item
4. **Dashboard** - Health overview
5. **Reports** - Export for stakeholders

---

### 5. The "What If" (1 minute)
- What if approver is on vacation?
- What if the system is down?
- What if someone changes their mind?
- What if it's urgent?
- What if data is missing?

---

## Three-Plane Cheat Sheet

### Data Plane = "What we remember"
```
✓ Who did what
✓ When it happened
✓ Current status
✓ Approval history
✓ Policy rules
✓ Audit trail
```

**Ask:** What does the auditor need to see 6 months from now?

---

### Control Plane = "What happens automatically"
```
✓ State transitions (submitted → approved)
✓ Routing logic (high risk → VP approval)
✓ Risk scoring (auto-calculate from policy)
✓ External calls (provision access in IAM)
✓ Notifications (email approver when stuck)
✓ Validations (can't approve own request)
```

**Ask:** What steps happen without anyone clicking?

---

### Management Plane = "What users see and click"
```
✓ Forms (simple, guided, clear errors)
✓ Queues (filterable, sortable, actionable)
✓ Dashboards (metrics, bottlenecks, trends)
✓ Reports (exportable, auditable, scheduled)
✓ Settings (configurable by admins)
```

**Ask:** What's the one thing this user needs to do here?

---

## Common Workflow Patterns

### Pattern: Sequential Approval
```
Request → Approver 1 → Approver 2 → Approver 3 → Done
```
**When:** Order matters (manager → director → VP)

### Pattern: Parallel Approval
```
Request → ┬→ Legal
          ├→ Finance  → (all done) → Done
          └→ Security
```
**When:** Independent reviews, any order

### Pattern: Threshold Routing
```
Request → if < $1K → Manager
          if < $10K → Director
          if >= $10K → VP + CFO
```
**When:** Different authority levels

### Pattern: Exception Fast-Track
```
Request → if URGENT → Single approver → Done (+ higher audit scrutiny)
          if NORMAL → Standard flow
```
**When:** Emergency "break glass" scenarios

### Pattern: Rework Loop
```
Request → Review → if REJECTED → Requester revises → Review again
                 → if APPROVED → Done
```
**When:** Iterative refinement needed

---

## UI Design Patterns

### Form Best Practices
```
┌─────────────────────────────────────┐
│ Clear title                         │
│                                     │
│ Required Field *                    │
│ [____________________________]      │
│ Help text: Why we need this         │
│                                     │
│ Optional Field                      │
│ [____________________________]      │
│                                     │
│ [Primary Action] [Cancel]           │
└─────────────────────────────────────┘
```

**Rules:**
- Required fields marked with *
- One field per row (mobile-friendly)
- Primary action = solid button, secondary = link
- Validate on blur, confirm on submit
- Progressive disclosure (show advanced only if needed)

---

### Queue/List Best Practices
```
┌─────────────────────────────────────┐
│ Filter: [All ▾] [Risk ▾] [SLA ▾]   │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [!] Request #123 · 2h ago       │ │
│ │ Jane Doe · EMR Access · 7 days  │ │
│ │ [High Risk] [SLA Breach]        │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Request #122 · 4h ago           │ │
│ │ John Smith · Lab System · 2d    │ │
│ │ [Medium Risk] [On Track]        │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Rules:**
- Most urgent on top (SLA breach, then newest)
- Color-coded badges (red = urgent, yellow = warning, green = good)
- Filter chips (not hidden dropdowns)
- Click card → opens detail
- Empty state: helpful guidance, not blank

---

### Detail View Best Practices
```
┌─────────────────────────────────────┐
│ Request #123                        │
│ [Status Badge] [Risk Badge]         │
│ ⏱ SLA: 2h remaining                │
├─────────────────────────────────────┤
│ Requester: Jane Doe                 │
│ System: EMR                         │
│ Duration: 7 days                    │
│ Justification: "Need to..."         │
├─────────────────────────────────────┤
│ Timeline:                           │
│ ✓ Submitted (2d ago)                │
│ ✓ Approved by Compliance (1d ago)   │
│ ⧗ Awaiting Privacy approval ← YOU   │
│ ○ Awaiting System Owner             │
├─────────────────────────────────────┤
│ Your Decision:                      │
│ [Approve] [Reject with note]        │
└─────────────────────────────────────┘
```

**Rules:**
- Context at top (status, urgency)
- Timeline shows progress
- Highlight what needs attention
- Primary action prominent
- Real-time updates (status changes while viewing)

---

### Dashboard Best Practices
```
┌─────────────────────────────────────┐
│ ┌──────┐ ┌──────┐ ┌──────┐         │
│ │  42  │ │ 98%  │ │ 3.2h │         │
│ │Pending│ │SLA OK│ │ Avg  │         │
│ └──────┘ └──────┘ └──────┘         │
├─────────────────────────────────────┤
│ Bottleneck Analysis:                │
│ ████████████ Privacy (avg 6h)       │
│ ██████ Compliance (avg 3h)          │
│ ███ System Owner (avg 1.5h)         │
├─────────────────────────────────────┤
│ [Export Report] [View All Requests] │
└─────────────────────────────────────┘
```

**Rules:**
- Key metrics at a glance (big numbers)
- Visual trends (charts, not just tables)
- Drill-down capability (click metric → filtered list)
- Export prominent but secondary
- Refresh automatically (live updates)

---

## Domain Knowledge Cheat Sheet

### HIPAA (Healthcare)
- **Minimum Necessary:** Only access data needed for the task
- **Business Associate Agreements:** Third parties handling PHI need BAAs
- **Breach Notification:** Must report unauthorized access within 60 days
- **Audit Controls:** Log all access, review periodically
- **Access Management:** Role-based, terminated when job changes

### SOX (Finance)
- **Segregation of Duties:** Can't approve own request
- **Change Management:** Production changes require approval
- **Access Controls:** Least privilege, periodic review
- **Audit Trail:** Immutable logs of financial data access
- **Attestation:** Executives certify control effectiveness

### GDPR (Privacy)
- **Lawful Basis:** Document why processing is allowed
- **Data Minimization:** Collect only what's necessary
- **Purpose Limitation:** Use data only for stated purpose
- **Right to Access:** Individuals can request their data
- **Retention Limits:** Delete data when no longer needed

### ISO 27001 (Security)
- **Risk Assessment:** Identify threats, prioritize controls
- **Access Control Policy:** Who can access what
- **Incident Response:** Documented procedures for breaches
- **Supplier Management:** Third-party risk evaluation
- **Continual Improvement:** Regular audits, corrective actions

---

## Decision Trees

### "What Approval Pattern Do I Need?"

```
Is order important?
├─ YES → Sequential approval
│         (manager → director → VP)
└─ NO → Are reviews independent?
        ├─ YES → Parallel approval
        │         (legal + finance + security, any order)
        └─ NO → Is it threshold-based?
                ├─ YES → Conditional routing
                │         (< $1K: manager, >= $1K: director)
                └─ NO → Is it urgent sometimes?
                        ├─ YES → Exception fast-track
                        │         (normal vs. emergency paths)
                        └─ NO → Single approver
```

---

### "What Data Do I Store?"

```
Will auditors need this?
├─ YES → Store with timestamp, actor, immutable
└─ NO → Is it for decision-making?
        ├─ YES → Store, make searchable/filterable
        └─ NO → Is it temporary?
                ├─ YES → Store in session or cache
                └─ NO → Don't store it
```

---

### "What Integration Do I Need?"

```
Does external system need to know?
├─ YES → Real-time or batch?
│        ├─ Real-time → Webhook (push) or API call
│        └─ Batch → Scheduled export (nightly CSV)
└─ NO → Does it provide data I need?
        ├─ YES → API call when needed
        └─ NO → No integration required
```

---

## Anti-Patterns (Avoid These!)

### ❌ "We'll figure it out later"
**Problem:** Vague acceptance criteria lead to scope creep
**Fix:** Define done-done upfront

### ❌ "Just add a field for..."
**Problem:** Database bloat, forms become overwhelming
**Fix:** Progressive disclosure, JSON for flexible metadata

### ❌ "Everyone should be able to..."
**Problem:** Permission sprawl, audit nightmares
**Fix:** Role-based access, principle of least privilege

### ❌ "It'll be fast enough"
**Problem:** 1000 records load in 30 seconds
**Fix:** Set SLAs upfront, paginate/virtualize

### ❌ "Admins can edit anything"
**Problem:** Accidental data corruption, audit gaps
**Fix:** Immutable logs, soft deletes, approval for sensitive changes

### ❌ "Users will read the docs"
**Problem:** They won't
**Fix:** Self-explanatory UI, inline help, sensible defaults

---

## Scoping Checklist

### Before You Start
- [ ] Problem statement written (Job To Be Done)
- [ ] Actors identified
- [ ] Done-Done criteria defined
- [ ] Domain knowledge gathered (compliance, legal, SMEs)
- [ ] Similar existing features reviewed

### Data Plane
- [ ] Models/tables listed
- [ ] Fields/attributes defined
- [ ] Statuses/states enumerated
- [ ] Policies/rules documented
- [ ] Audit requirements met

### Control Plane
- [ ] State machine drawn
- [ ] Transitions validated (no dead ends)
- [ ] Guards/validations defined
- [ ] Services identified
- [ ] External integrations mapped
- [ ] Notifications scoped

### Management Plane
- [ ] Screens wireframed
- [ ] Primary action per screen identified
- [ ] Filters/searches defined
- [ ] Real-time updates scoped
- [ ] Reports/exports specified
- [ ] Empty states designed
- [ ] Error states designed

### Edge Cases
- [ ] Approver unavailable (delegation, timeout)
- [ ] Integration fails (retry, fallback, alert)
- [ ] User changes mind (cancel, revise)
- [ ] Urgent override (break glass, higher scrutiny)
- [ ] Data missing (validation, helpful errors)
- [ ] Duplicate request (detection, merge, warn)

### Collaboration
- [ ] Developer reviewed for feasibility
- [ ] Effort estimated
- [ ] Risks identified
- [ ] Dependencies mapped
- [ ] Security consulted
- [ ] Compliance signed off

---

## Quick Wins vs. Complex Builds

### Quick Win (2-4 weeks)
- Single approver
- Simple form (5-7 fields)
- Basic list view
- Email notifications
- CSV export
- Straightforward state machine (3-5 states)

**Example:** Manager approval for PTO requests

### Medium Build (1-2 months)
- Sequential approval chain (2-3 steps)
- Moderate form with attachments
- Filtered queue view
- Multi-channel notifications
- Dashboard with basic metrics
- Integration with 1-2 systems

**Example:** Purchase order approval with budget check

### Complex Build (2-4 months)
- Parallel + sequential approvals
- Risk-based routing
- Advanced form with progressive disclosure
- Real-time queue updates
- Custom analytics dashboard
- Integration with 3+ systems
- Compliance reporting

**Example:** PHI access approval (our reference)

---

## Success Metrics Template

### Usage Metrics
- Requests submitted per week: [target]
- Avg approval time: [target]
- SLA compliance %: [target]
- Active users per month: [target]

### Quality Metrics
- Rejection rate: [target] (lower = clearer guidance)
- Rework cycles: [target] (lower = better requirements)
- Support tickets: [target] (lower = better UX)

### Business Metrics
- Cost per request processed: [target]
- Audit findings reduced: [target]
- Compliance violations: [target] (zero tolerance)
- Time to provision access: [target]

### User Satisfaction
- NPS score: [target]
- Task completion rate: [target]
- Time to first success: [target]
- Return user rate: [target]

---

## One-Pager Template

Use this for stakeholder review:

```markdown
# [Feature Name]

## Problem (2 sentences)
[Who has what problem, why it matters]

## Solution (3 bullets)
- [What we're building]
- [How it works]
- [Key benefit]

## Actors
[Who uses this]

## Key Screens
1. [Screen name]: [primary action]
2. [Screen name]: [primary action]

## Workflow
[Happy path in 5 steps]

## Edge Cases
[Top 3 "what if" scenarios]

## Success Metrics
- [Metric 1]
- [Metric 2]
- [Metric 3]

## Timeline
- [Phase 1]: [scope]
- [Phase 2]: [scope]

## Dependencies
- [System integration]
- [Stakeholder approval]

## Risks
- [Risk]: [mitigation]
```

---

## Remember

1. **Start simple** - Build happy path first, add complexity later
2. **Ask "why"** - Understand the business need before designing
3. **Show don't tell** - Wireframes beat paragraphs
4. **Test early** - Put mockups in front of users
5. **Iterate** - First version won't be perfect
6. **Document decisions** - Future you will thank present you

---

**Keep this handy during scoping sessions. Refer to BUSINESS_USER_GUIDE.md for detailed explanations.**
