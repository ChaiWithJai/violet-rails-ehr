# Violet Rails: Business User Guide
## Building Solutions for the Betterment of Humanity

---

## What This Guide Is For

This guide helps business users, domain experts, and non-technical stakeholders design and scope solutions using Violet Rails. You don't need to write code, but you'll learn how to think about business problems in a way that translates smoothly into working software.

We'll use the **PHI Access Approval** system as our reference example throughout this guide.

---

## Table of Contents

1. [What is Violet Rails?](#what-is-violet-rails)
2. [The Three-Plane Architecture (Explained Simply)](#the-three-plane-architecture)
3. [From Business Problem to Solution: The Framework](#from-business-problem-to-solution)
4. [Reference Example: PHI Access Approvals](#reference-example-phi-access-approvals)
5. [Your Scoping Toolkit](#your-scoping-toolkit)
6. [UI Principles: Don't Make Me Think](#ui-principles)
7. [Working with Your Development Team](#working-with-developers)
8. [High-Value Use Cases Across Industries](#industry-use-cases)

---

## What is Violet Rails?

**Violet Rails** is a pre-built foundation for creating enterprise-grade internal tools and workflows. Think of it as a starter kit that already handles the hard, common stuff:

- **User authentication and permissions** - Who can do what
- **Audit trails** - Complete records of all changes
- **Background jobs** - Work that happens behind the scenes
- **Modern UI components** - Clean, responsive interfaces
- **API integrations** - Connecting to other systems
- **Security best practices** - Built-in protection

### Who Uses Violet Rails?

Organizations building:
- **Approval workflows** (our focus) - Spend requests, access controls, exception handling
- **Tenant portals** - Customer dashboards with role-based access
- **Marketplace operations** - Order processing, inventory management
- **Internal tooling** - CRUD workflows, reporting, admin panels

### Why It Matters to You

Instead of starting from scratch, you start with proven patterns. Your job is to describe **what the business needs**, and Violet Rails provides the **how to build it**.

---

## The Three-Plane Architecture

Every Violet Rails solution has three layers. Think of building a house:

### 1. Data Plane (The Foundation)
**What it stores and remembers**

This is your database - where information lives permanently:
- **Who** made the request (requester, approver, system owner)
- **What** they're requesting (access to PHI, budget override, promotion)
- **When** it happened (timestamps, deadlines, expiration dates)
- **Why** they need it (justification, business case)
- **Status** tracking (submitted, approved, active, expired)
- **Policies** that govern decisions (risk thresholds, approval chains)

**Business Questions to Ask:**
- What information do we need to capture?
- What decisions can we look up later?
- What do auditors or regulators need to see?
- How long must we keep this data?

**PHI Example:**
```
Request:
  - Who needs access (staff member ID)
  - Which system (EMR, lab system, billing)
  - Why they need it (patient care, billing dispute)
  - How long they need it (2 days, 30 days)
  - Current status (submitted → approved → active)

Policy:
  - Maximum access duration (30 days)
  - Who must approve (compliance officer + data privacy)
  - Risk thresholds (high/medium/low)
  - Escalation rules (if SLA breached, notify director)
```

---

### 2. Control Plane (The Plumbing)
**What happens and in what order**

This is your business logic - the rules and workflows:
- **State machines** - Valid paths from start to finish
- **Approval routing** - Who reviews what, in what sequence
- **Risk assessment** - Automated scoring against policy
- **Integrations** - Talking to external systems (IAM, ERP, CRM)
- **Notifications** - Alerts, reminders, escalations
- **Validations** - Can this action happen right now?

**Business Questions to Ask:**
- What steps must happen in order?
- Who decides at each step?
- What happens if someone says no?
- How do we handle exceptions or urgent cases?
- What external systems need to know about this?
- When do we send notifications?

**PHI Example:**
```
Flow:
1. Staff member submits request → auto risk-score
2. If high risk → route to compliance officer
3. If approved by compliance → route to data privacy officer
4. If approved by privacy → route to system owner
5. If all approve → trigger provisioning job
6. Provisioning calls external IAM system
7. If IAM succeeds → mark request "active"
8. If IAM fails → notify approvers, mark "provisioning_failed"
9. When expiration date hits → auto-revoke access

Side flows:
- Any approver can reject → requester notified, can revise
- SLA breach → escalate to manager
- Emergency "break glass" → single approver, higher audit scrutiny
```

---

### 3. Management Plane (The Dashboard)
**How people see and interact with it**

This is your user interface and reporting:
- **Request forms** - How users submit new items
- **Approval queues** - Where approvers see pending work
- **Status dashboards** - Real-time view of the system
- **Compliance reports** - Exports for regulators or executives
- **Admin settings** - Configuring policies, thresholds, users

**Business Questions to Ask:**
- Who are the primary users? (requesters, approvers, admins, auditors)
- What's their most common task?
- What decisions do they make on this screen?
- What information helps them decide?
- How do we surface urgent items?
- What reports do stakeholders need?

**PHI Example:**
```
Screens:
1. Request Intake Form
   - Staff fills out: system, justification, duration
   - Shows: risk estimate, expected approval time
   - Primary action: "Submit Request"

2. Approval Queue (for compliance officer)
   - Shows: pending requests in risk order
   - Filters: by system, risk level, SLA status
   - Per-request: timeline, justification, policy match
   - Primary action: "Approve" or "Reject with note"

3. Admin Dashboard
   - Shows: queue depth, SLA metrics, bottleneck heatmap
   - Filters: date range, system, approver
   - Exports: compliance report (CSV), audit log (PDF)
   - Settings: edit policy matrix, manage approvers

4. Request Detail (for requester to track)
   - Shows: current status, timeline, who's reviewing
   - Countdown: "2 days remaining before expiration"
   - Actions: (if rejected) "Revise request"
```

---

## From Business Problem to Solution

Use this framework to scope any approval-heavy workflow:

### Step 1: Define the Job To Be Done

Complete this sentence:
> "When **[actor]** needs **[outcome]**, they can **[action]**, so that **[benefit]**."

**PHI Example:**
> "When a staff member needs temporary access to protected health data, they can request it, have it assessed against policy, routed for approvals, and audited later, so compliance/regulators trust all PHI access is controlled and provable."

---

### Step 2: Map the Actors

List everyone who interacts with this workflow:

| Actor | Role | What They Do | What They Need |
|-------|------|--------------|----------------|
| Requester | Staff needing PHI access | Submit request, track status | Simple form, status visibility |
| Compliance Officer | First approver | Review against HIPAA policy | Risk score, justification, policy match |
| Data Privacy Officer | Second approver | Assess data classification | Which data sets, duration, precedent |
| System Owner | Final approver | Grant technical access | System impact, approver consensus |
| Compliance AI | Automated risk scorer | Calculate risk level | Access to policy matrix, request details |
| Audit Reviewer | Post-hoc oversight | Generate compliance reports | Immutable logs, exportable evidence |

---

### Step 3: Define "Done-Done"

What does success look like? Be specific:

**PHI Example:**
- [ ] All happy paths and rejection/rework flows covered by request → approval → activation lifecycle
- [ ] End-to-end automated tests pass (green build)
- [ ] Immutable audit log captures every transition with timestamps, actor signatures, policy version
- [ ] Audit log is exportable (CSV, PDF) for regulator review
- [ ] Integration with IAM system confirms provisioning success/failure
- [ ] Status syncs back to source systems (HR system knows access is active)
- [ ] SLA breach alerts fire when approvals stall
- [ ] Admin dashboard shows queue depth, SLA metrics, bottleneck heatmap
- [ ] Compliance report matches policy matrix (no drift)
- [ ] Security team has reviewed threat model and signed off
- [ ] Data classification is documented (what's PHI, what's not)

---

### Step 4: Identify Domain Knowledge Requirements

What expertise must inform this solution?

**PHI Example:**
- HIPAA/HITECH privacy & security rules, especially:
  - Minimum necessary standard (only access what's needed for the task)
  - Role-based access controls
  - Business Associate Agreements (BAAs)
- Organizational PHI classification schema:
  - What data is PHI vs. de-identified
  - Data retention policies (how long to keep logs)
  - E-discovery obligations (legal hold procedures)
- Identity and access management practices:
  - Just-In-Time access (temporary elevation)
  - Segregation of duties (who can't approve their own request)
  - Break-glass protocols (emergency access when workflow can't wait)
- Incident response procedures:
  - Who to notify if access is misused
  - Audit requirements (quarterly reviews, annual attestations)
  - Regulator expectations for evidence quality

**Your Task:**
- Interview compliance, security, legal, IT stakeholders
- Review existing policies and procedures
- Check industry standards (HIPAA, SOX, GDPR, etc.)
- Understand what auditors or regulators ask for

---

### Step 5: Map to the Three Planes

Take your business logic and assign it to the right layer:

#### Data Plane Checklist
- [ ] What tables/models do we need?
  - `PHIAccessRequest`: core request record
  - `PHIAccessPolicy`: policy rules per system
  - `ApprovalStep`: sequenced approvals
  - `AuditEntry`: immutable log of all actions
- [ ] What fields capture business context?
  - requester_id, system_id, justification, risk_level, status, approved_until
- [ ] What statuses exist?
  - draft, submitted, risk_review, awaiting_privacy, awaiting_owner, approved, provisioning, active, expired, denied, revoked, awaiting_rework
- [ ] What metadata belongs in JSON fields?
  - Policy escalation rules, risk scoring factors, attached evidence

#### Control Plane Checklist
- [ ] What's the state machine?
  - Draw all valid transitions (submitted → risk_review → awaiting_privacy → ...)
  - Identify side flows (rejection, escalation, rework)
- [ ] What validations guard each transition?
  - Can't approve if SLA expired
  - Can't provision if any step rejected
  - Can't revoke if already expired
- [ ] What services orchestrate workflows?
  - `ApprovalEngine`: state machine entry point
  - `RiskScorer`: applies policy rules, returns risk level
  - `Provisioner`: calls external IAM, handles success/failure
  - `SlaNudger`: sends reminders when approvals stall
- [ ] What events get published?
  - `phi_access.requested`, `phi_access.approved`, `phi_access.provisioned`
  - Subscribe audit logger, notification service, analytics
- [ ] What external integrations are required?
  - IAM system (provision/revoke access)
  - HR system (validate requester is active employee)
  - ERP system (sync status for downstream reporting)

#### Management Plane Checklist
- [ ] What screens do users need?
  - Request intake form
  - Approval queue (per approver role)
  - Request detail/timeline
  - Admin dashboard
  - Compliance export page
- [ ] What filters and searches?
  - By risk level, system, SLA status, date range, approver
- [ ] What primary actions on each screen?
  - Intake: "Submit Request"
  - Queue: "Approve" / "Reject"
  - Detail: "Revise Request" (if rejected)
  - Admin: "Export Compliance Report", "Edit Policy Matrix"
- [ ] What real-time updates?
  - Queue updates when new requests arrive (Hotwire Turbo Streams)
  - Status badge updates when approval granted
  - SLA countdown changes color (amber → red)
- [ ] What reports/exports?
  - Compliance CSV: all requests for date range, with audit trail
  - SLA metrics: average approval time, bottleneck heatmap
  - Policy coverage: which systems have policies, which don't

---

## Reference Example: PHI Access Approvals

Let's walk through the complete PHI example to see all pieces together:

### The Business Problem
Healthcare organizations must control and audit all access to Protected Health Information (PHI). Staff need temporary access to perform their jobs (patient care, billing, research), but:
- HIPAA requires documented justification
- Access must be "minimum necessary" (right data, right duration)
- Multiple approvers ensure oversight
- Regulators audit access logs during inspections
- Unauthorized access can result in fines, loss of accreditation, harm to patients

### The Solution Scope
Build an approval workflow that:
1. Captures request details (who, what, why, how long)
2. Auto-scores risk based on policy (low/medium/high)
3. Routes to required approvers in sequence
4. Integrates with IAM to actually provision access
5. Creates immutable audit trail
6. Provides compliance reporting for regulators

### Mapped to Three Planes

**Data Plane:**
- `PHIAccessRequest`: id, requester_id, system_id, justification, risk_level, status, approved_until
- `PHIAccessPolicy`: id, system_id, risk_threshold, max_duration_days, escalation_rule (JSON)
- `ApprovalStep`: id, request_id, position, role, status, acted_at, approver_id, note
- `AuditEntry`: id, actor_type, actor_id, action, payload (JSON), signed_digest, created_at

**Control Plane:**
- `Violet::Workflow::ApprovalEngine`: orchestrates state transitions
- `Violet::Workflow::StateMaps::PHIAccess`: defines valid states and transitions
- `Violet::Policies::RiskScorer`: applies HIPAA policy rules, returns risk level
- `Violet::Integrations::Provisioner`: calls external IAM API
- `Violet::Integrations::ProvisionerJob`: background job for async provisioning
- `Violet::Notifications::SlaNudger`: sends email/Slack when SLA at risk

**Management Plane:**
- `Violet::Admin::PHIAccessRequestsController`: request intake, queue, detail views
- `Violet::Admin::Dashboards::PHIAccessController`: metrics dashboard
- `Violet::Reporting::ComplianceExport`: CSV/PDF generation
- Views:
  - `new.html.erb`: request intake form
  - `index.html.erb`: approval queue
  - `show.html.erb`: request detail + timeline
  - `dashboard.html.erb`: SLA metrics, bottleneck heatmap

### Key Workflows

**Happy Path:**
```
1. Staff submits request via form
2. ApprovalEngine.submit(request_attrs, actor) creates request
3. RiskScorer.score(request) returns "medium"
4. Engine builds approval chain: [compliance, privacy, system_owner]
5. AuditLogger logs "request.created"
6. Compliance officer sees request in queue, reviews, approves
7. AuditLogger logs "approval_step.approved"
8. Privacy officer sees request, approves
9. System owner approves
10. Engine detects all steps approved, transitions to "provisioning"
11. ProvisionerJob enqueued
12. Job calls IAM API: POST /access_grants
13. IAM returns success
14. Job logs "access.provisioned", transitions request to "active"
15. Requester notified via email
16. On approved_until date, cron job auto-revokes access
```

**Rejection Flow:**
```
1-4. (same as happy path)
5. Compliance officer rejects with note: "Justification insufficient"
6. Engine transitions to "awaiting_rework"
7. Requester notified with rejection reason
8. Requester revises justification, resubmits
9. Engine resets approval steps, starts over
```

**SLA Breach Flow:**
```
1-5. (same as happy path)
6. Compliance officer doesn't act within 24 hours
7. SlaNudger job runs hourly, detects breach
8. Sends email to compliance officer: "Request #123 pending 26 hours"
9. If still no action after 48 hours, escalates to director
10. Director can approve on behalf of compliance
```

### UI Walkthrough

**Request Intake Form:**
- Fields: System dropdown, Justification textarea, Duration selector (days)
- Progressive disclosure: If duration > 7 days, show "Extended Access Reason" field
- Risk estimate: Client-side JavaScript previews risk level based on system + duration
- Primary action: "Submit Request" button (prominent, blue)
- Secondary: "Save as Draft" link (gray)

**Approval Queue:**
- Layout: Kanban lanes (Pending My Review | Approved by Me | Rejected by Me)
- Card shows: Request #, Requester name + avatar, System, Risk badge, SLA countdown chip
- Filters: Risk level toggles, System dropdown, SLA status (On Time | At Risk | Breached)
- Sort: Default by SLA (breached first), can toggle to newest/oldest
- Click card → opens Request Detail modal

**Request Detail:**
- Top: Status badge (large), Risk badge, SLA countdown
- Timeline: Vertical list of events (submitted, approved by X, provisioned)
- Right panel: Approver avatars, current step highlighted
- Justification: Shown in card, expandable if long
- Decision panel (if pending my review):
  - Textarea for note
  - "Approve" button (green), "Reject" button (red)
  - After click: optimistic UI (disable buttons, show spinner)
  - Turbo Stream updates queue in background

**Admin Dashboard:**
- Top metrics: Avg approval time, Queue depth, SLA compliance %
- Bottleneck heatmap: Table showing which approval step has longest avg time
- Filters: Date range picker, System dropdown, Approver multiselect
- Export: "Download Compliance Report" button (generates CSV, emails link)
- Policy matrix: Table of systems with risk thresholds, editable inline

---

## Your Scoping Toolkit

When vibe coding a new solution, use these prompts:

### 1. Problem Statement
```
When [actor] needs [outcome], they can [action], so that [benefit].
```

### 2. Actors & Roles
| Actor | What They Do | What They Need to See | What They Decide |
|-------|--------------|----------------------|------------------|
| ... | ... | ... | ... |

### 3. Done-Done Criteria
- [ ] Functional: All user stories covered, edge cases handled
- [ ] Technical: Tests green, integrations working, performance acceptable
- [ ] Audit: Immutable logs, exportable evidence
- [ ] Compliance: Stakeholder sign-off, threat model reviewed
- [ ] Operational: Monitoring, alerts, runbooks documented

### 4. Domain Knowledge Sources
- **Regulatory:** HIPAA, SOX, GDPR, FDA, etc.
- **Internal policies:** Approval matrices, delegation of authority, data classification
- **Industry standards:** ISO 27001, NIST, CIS controls
- **Subject matter experts:** Compliance officers, security architects, legal counsel

### 5. Three-Plane Mapping

**Data Plane:**
- What models/tables?
- What fields/attributes?
- What statuses/states?
- What policies or rules?

**Control Plane:**
- What's the state machine?
- What validations?
- What services orchestrate?
- What external integrations?
- What notifications?

**Management Plane:**
- What screens?
- What actions per screen?
- What filters/searches?
- What real-time updates?
- What reports/exports?

### 6. Workflow Diagram
Draw (or describe) the happy path, rejection flows, escalations, and exception handling.

### 7. UI Sketches
Wireframe the key screens. Focus on:
- What's the primary action?
- What information helps the user decide?
- What updates in real-time?
- What's the path back if they change their mind?

---

## UI Principles: Don't Make Me Think

Every screen you design should pass the "5-second test": Can a user understand what this screen is for and what to do next in 5 seconds?

### Visual Hierarchy
1. **Status/context** at top (where am I?)
2. **Primary action** prominent (what should I do?)
3. **Supporting info** secondary (why/how?)
4. **Navigation** predictable (where can I go?)

**PHI Example:**
```
┌─────────────────────────────────────────┐
│ PHI Access Request #12345               │ ← Context
│ [Awaiting Privacy Approval] [Medium Risk]│ ← Status badges
├─────────────────────────────────────────┤
│ Requester: Jane Doe (Billing)           │
│ System: Electronic Medical Records      │
│ Duration: 7 days                         │
│ Justification: "Resolving claim dispute │
│ for patient #987, need to verify..."    │ ← Supporting info
│                                          │
│ Timeline:                                │
│ ✓ Submitted by Jane Doe (2d ago)        │
│ ✓ Approved by Compliance (1d ago)       │
│ ⧗ Pending Data Privacy approval         │ ← Current step
│ ○ Awaiting System Owner                 │
│                                          │
│ [Approve] [Reject]                       │ ← Primary actions
└─────────────────────────────────────────┘
```

### Action Clarity
- **One primary action per screen** (big, colorful button)
- **Label actions with verbs** ("Approve Request", not "OK")
- **Show consequences** ("Reject and notify requester")
- **Disable unavailable actions** (don't hide, explain why disabled)

### Feedback Loops
- **Optimistic UI**: Show result immediately, sync in background
- **Progress indicators**: Spinner, percentage, estimated time
- **Confirmation messages**: Toast notification, banner
- **Error recovery**: Clear message, suggest fix, preserve user input

### Reduce Cognitive Load
- **Default to most common choice** (pre-select typical duration)
- **Progressive disclosure** (show advanced options only if needed)
- **Inline help** (tooltip on hover, not separate help page)
- **Consistent patterns** (approval flows look the same across features)

### Accessibility
- **Keyboard navigation**: Tab through form, Enter to submit, Esc to cancel
- **Screen reader labels**: Descriptive ARIA attributes
- **Color contrast**: WCAG AA minimum (4.5:1 for text)
- **Focus indicators**: Visible outline on active element

---

## Working with Your Development Team

### What You Provide (The Brief)
1. **Problem statement** (Job To Be Done)
2. **Actors and roles**
3. **Done-Done criteria**
4. **Domain knowledge** (or who to interview)
5. **Three-plane mapping** (your best guess)
6. **Workflow diagram**
7. **UI wireframes or sketches**
8. **Edge cases** you're worried about
9. **Success metrics** (how we measure this is working)

### What Developers Provide (The Implementation)
1. **Technical feasibility** assessment
2. **Effort estimate** (story points, days, sprints)
3. **Risks and dependencies**
4. **Data model refinements**
5. **Test strategy**
6. **Security review**
7. **Deployment plan**
8. **Working software** (incremental demos)

### Collaboration Cadence
- **Kickoff:** Review brief, align on scope, identify unknowns
- **Design review:** Validate data model, state machine, UI flows
- **Mid-sprint check:** Demo progress, adjust based on feedback
- **Pre-release:** User acceptance testing, final tweaks
- **Retrospective:** What went well, what to improve

### Common Pitfalls
1. **Scope creep:** "Can we also add...?" → Document as follow-up story
2. **Vague acceptance criteria:** "Easy to use" → Define specific actions, time limits
3. **Missing edge cases:** "What if approver is on vacation?" → Delegation rules
4. **Integration surprises:** "We assumed IAM had an API" → Validate early
5. **Performance blindness:** "1000 pending requests loads in 30 seconds" → Set SLAs upfront

---

## High-Value Use Cases Across Industries

Approvals-heavy workflows show up wherever businesses need documented, auditable decisions. Here are proven high-value domains:

### Finance & Procurement
**Why:** SOX compliance, audit requirements, fraud prevention
- **Spend approvals:** Purchase orders, expense reports, budget overrides
- **Invoice exceptions:** Payment holds, dispute resolution, vendor credits
- **Contract approvals:** Legal review, signature authority, amendments
- **Patterns:** Multi-tier based on amount, segregation of duties, immutable audit trail

### HR & People Ops
**Why:** Fairness, documentation, privacy compliance (GDPR, CCPA)
- **Headcount requests:** New role justification, budget approval, offer sign-off
- **Promotions & transfers:** Peer review, compensation committee, mobility approval
- **Leave exceptions:** Extended medical leave, unpaid sabbatical, FMLA certification
- **Patterns:** Role-based routing, privacy-sensitive data handling, manager delegation

### Healthcare & Life Sciences
**Why:** Regulatory oversight (HIPAA, FDA, GMP)
- **PHI access** (our example): Temporary access, break-glass protocols
- **Clinical protocol changes:** IRB approval, safety review, documentation
- **Equipment/drug spend:** Capital approval, formulary committee, safety attestation
- **Patterns:** Multi-disciplinary review, evidence attachments, regulator-ready exports

### Energy & Utilities
**Why:** Safety-critical environments, strict regulatory obligations
- **Work permits:** Hot work, confined space, high-voltage, lockout/tagout
- **Safety overrides:** Bypassing interlocks, maintenance mode, emergency procedures
- **Capital projects:** Environmental review, safety analysis, budget approval
- **Patterns:** Sequential safety checks, site-specific rules, incident correlation

### Manufacturing & Supply Chain
**Why:** Traceability, defect prevention, regulatory compliance (ISO, FDA)
- **Engineering change orders:** Design changes, BOM updates, validation testing
- **Quality deviations:** Non-conformance, rework authorization, scrap approval
- **Supplier onboarding:** Quality audit, financial review, contract negotiation
- **Patterns:** Revision control, impact analysis, supply chain visibility

### Legal & Compliance
**Why:** Risk exposure, contractual obligations, regulatory filings
- **Contract approvals:** Redlines, non-standard terms, signature authority
- **Policy exceptions:** Risk acceptance, temporary waivers, compensating controls
- **Marketing sign-offs:** Claims review, regulatory compliance (FDA, FTC), brand approval
- **Patterns:** Legal hold integration, version control, expiration tracking

### IT & Security
**Why:** Auditability, least privilege, incident response readiness
- **Access provisioning:** Role requests, elevated privileges, third-party access
- **Change management:** Production changes, maintenance windows, rollback plans
- **Vulnerability remediation:** Risk acceptance, patching schedules, compensating controls
- **Patterns:** Just-In-Time access, approval expiration, integration with IAM/SIEM

---

## Template: Your Next Feature

Copy this template to scope your next approval workflow:

```markdown
# Feature: [Name]

## Problem Statement
When [actor] needs [outcome], they can [action], so that [benefit].

## Actors & Roles
| Actor | Role | What They Do | What They Need | What They Decide |
|-------|------|--------------|----------------|------------------|
| | | | | |

## Done-Done Criteria
- [ ] Functional:
- [ ] Technical:
- [ ] Audit:
- [ ] Compliance:
- [ ] Operational:

## Domain Knowledge
- **Regulatory:**
- **Internal policies:**
- **Subject matter experts:**
- **Industry standards:**

## Data Plane
**Models:**
- `ModelName`: fields...

**Statuses:**
- draft → submitted → ...

**Policies:**
- What rules govern decisions?

## Control Plane
**State Machine:**
- (Draw or describe transitions)

**Services:**
- `ServiceName`: what it orchestrates

**Integrations:**
- External system X: for purpose Y

**Notifications:**
- When to alert, who to notify

## Management Plane
**Screens:**
1. **Screen Name:**
   - Fields:
   - Primary action:
   - Filters:
   - Real-time updates:

**Reports:**
- Report name: what it exports

## Workflows
**Happy Path:**
1. Step 1
2. Step 2
...

**Rejection Flow:**
...

**Edge Cases:**
- What if approver is unavailable?
- What if integration fails?
- What if request is duplicated?

## UI Sketches
(Wireframes or descriptions)

## Success Metrics
- How we know it's working:
- Usage targets:
- SLA targets:
```

---

## Next Steps

1. **Read the PHI example** in `claude-instructions.md` to see a complete worked example
2. **Review existing code** in `app/models/violet/security/phi_access_request.rb` and related files
3. **Try the template** above with a problem from your domain
4. **Collaborate with developers** to refine your scoping into implementation stories
5. **Iterate based on user feedback** after first release

---

## Questions?

- **Technical setup:** See `START_HERE.md`, `QUICKSTART.md`
- **Testing strategy:** See `TESTING_GUIDE.md`
- **Deployment:** See `SHIP.md`
- **Contributing:** See `CONTRIBUTING.md`

---

## Appendix: Common Patterns

### Approval Chain Patterns
- **Parallel:** Multiple approvers, any order (e.g., legal + finance)
- **Sequential:** Specific order required (e.g., manager → director → VP)
- **Threshold-based:** Routes to different approvers based on amount/risk
- **Exception-based:** Fast-track for urgent, higher scrutiny afterward
- **Delegation:** Approver assigns to backup when unavailable

### Audit Trail Patterns
- **Immutable logs:** Write-only, cryptographically signed
- **Event sourcing:** Reconstruct state from events
- **Retention policies:** Automatic archival, legal hold support
- **Privacy redaction:** Mask PII in exports while preserving auditability

### Integration Patterns
- **Webhooks:** Push updates to external systems
- **Polling:** Pull status from external systems
- **API-first:** Expose your workflow as API for other systems to consume
- **Event bus:** Publish to message queue (Kafka, RabbitMQ) for async consumers

### Notification Patterns
- **Multi-channel:** Email + Slack + in-app
- **Escalation:** Reminder after N hours, escalate to manager after 2N
- **Digest:** Bundle related notifications (daily summary)
- **User preferences:** Allow users to configure frequency, channels

---

**Built with Violet Rails. For the betterment of humanity.**
