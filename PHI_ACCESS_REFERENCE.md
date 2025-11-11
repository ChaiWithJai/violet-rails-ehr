# PHI Access Approval: Reference Implementation
## From Business Concept to Working Code

This document shows how the PHI Access Approval workflow maps from business requirements through the three-plane architecture to actual code in the Violet Rails codebase.

---

## Table of Contents

1. [Business Context](#business-context)
2. [Architecture Overview](#architecture-overview)
3. [Data Plane Deep Dive](#data-plane-deep-dive)
4. [Control Plane Deep Dive](#control-plane-deep-dive)
5. [Management Plane Deep Dive](#management-plane-deep-dive)
6. [User Journey Walkthrough](#user-journey-walkthrough)
7. [Testing Strategy](#testing-strategy)
8. [Extending This Pattern](#extending-this-pattern)

---

## Business Context

### The Problem
Healthcare organizations must comply with HIPAA by:
- Documenting every access to Protected Health Information (PHI)
- Ensuring access is "minimum necessary" (right data, right duration)
- Maintaining approval workflows with multiple reviewers
- Providing audit trails for regulatory inspections

### The Solution
A structured approval workflow that:
1. Captures request details (who, what, why, how long)
2. Auto-scores risk based on organizational policy
3. Routes to required approvers in sequence
4. Integrates with IAM to provision access
5. Creates immutable audit trail
6. Generates compliance reports for regulators

### Success Metrics
- **Approval time:** < 24 hours for routine requests
- **SLA compliance:** > 95% of requests approved within policy window
- **Audit readiness:** Zero findings during regulatory inspections
- **User satisfaction:** > 4.5/5 rating from requesters and approvers

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    MANAGEMENT PLANE                         │
│  (What users see and interact with)                         │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │  Request   │  │  Approval  │  │  Dashboard │           │
│  │   Form     │  │   Queue    │  │  & Reports │           │
│  └────────────┘  └────────────┘  └────────────┘           │
│         │                │                │                 │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                     CONTROL PLANE                           │
│  (Business logic and orchestration)                         │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │  Approval  │  │    Risk    │  │Provisioner │           │
│  │  Engine    │  │  Scorer    │  │    Job     │           │
│  └────────────┘  └────────────┘  └────────────┘           │
│         │                │                │                 │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                      DATA PLANE                             │
│  (Persistent storage)                                       │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │ PHIAccess  │  │ Approval   │  │   Audit    │           │
│  │  Request   │  │   Step     │  │   Entry    │           │
│  └────────────┘  └────────────┘  └────────────┘           │
│                                                              │
│  [PostgreSQL Database]                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Plane Deep Dive

### Models and Database Schema

#### 1. PHIAccessRequest
**File:** `app/models/violet/security/phi_access_request.rb`

**Business Concept:** A staff member's request for temporary access to PHI

**Database Table:** `violet_security_phi_access_requests`

**Key Fields:**
```ruby
id                # UUID primary key
requester_id      # Who is requesting (references users)
system_id         # Which system (EMR, Lab, Billing)
justification     # Why they need access (text)
risk_level        # low, medium, high (calculated by RiskScorer)
status            # Current workflow state (enum)
approved_until    # When access expires (datetime)
created_at        # Request submitted timestamp
updated_at        # Last modification timestamp
```

**Status Values:**
```ruby
draft              # Being composed, not yet submitted
submitted          # Submitted, awaiting risk scoring
risk_review        # Being scored by policy engine
awaiting_compliance# Waiting for compliance officer approval
awaiting_privacy   # Waiting for data privacy officer approval
awaiting_owner     # Waiting for system owner approval
approved           # All approvals complete, ready to provision
provisioning       # IAM provisioning in progress
active             # Access granted and live
expired            # Access period ended
denied             # Rejected during approval
revoked            # Manually revoked before expiration
awaiting_rework    # Sent back to requester for revision
```

**Business Rules (Validations):**
- Requester must be active employee
- Justification must be present and > 10 characters
- Duration must be > 0 and <= max_duration from policy
- Can't approve if already expired
- Can't provision if any approval step rejected

**Sample Record:**
```ruby
{
  id: "550e8400-e29b-41d4-a716-446655440000",
  requester_id: "user_123",
  system_id: "emr_prod",
  justification: "Need to review patient chart for billing dispute resolution on claim #98765",
  risk_level: "medium",
  status: "awaiting_privacy",
  approved_until: "2025-11-18 23:59:59 UTC",
  created_at: "2025-11-11 14:00:00 UTC",
  updated_at: "2025-11-11 15:30:00 UTC"
}
```

---

#### 2. PHIAccessPolicy
**File:** `app/models/violet/security/phi_access_policy.rb`

**Business Concept:** Rules governing access to a specific system

**Database Table:** `violet_security_phi_access_policies`

**Key Fields:**
```ruby
id                   # UUID primary key
system_id            # Which system this policy governs
risk_threshold       # low, medium, high (enum)
max_duration_days    # Maximum access period (integer)
escalation_rule      # JSONB: complex escalation logic
approval_chain       # JSONB: required approver roles in order
created_at
updated_at
```

**Sample Record:**
```ruby
{
  id: "policy_001",
  system_id: "emr_prod",
  risk_threshold: "high",
  max_duration_days: 30,
  escalation_rule: {
    "sla_hours": 24,
    "escalate_to": "compliance_director",
    "escalation_hours": 48
  },
  approval_chain: [
    { "role": "compliance_officer", "required": true },
    { "role": "data_privacy_officer", "required": true },
    { "role": "system_owner", "required": true }
  ]
}
```

---

#### 3. PHIAccessApprovalStep
**File:** `app/models/violet/security/phi_access_approval_step.rb`

**Business Concept:** One approver's decision in the chain

**Database Table:** `violet_security_phi_access_approval_steps`

**Key Fields:**
```ruby
id                    # UUID primary key
request_id            # Which request (foreign key)
position              # Order in chain (0, 1, 2...)
role                  # compliance_officer, data_privacy_officer, etc.
status                # pending, approved, rejected
acted_at              # When decision made (datetime, null if pending)
approver_id           # Who decided (references users, null if pending)
note                  # Optional comment from approver
created_at
updated_at
```

**Sample Records:**
```ruby
# Step 1: Compliance Officer (approved)
{
  id: "step_001",
  request_id: "550e8400-e29b-41d4-a716-446655440000",
  position: 0,
  role: "compliance_officer",
  status: "approved",
  acted_at: "2025-11-11 15:30:00 UTC",
  approver_id: "user_456",
  note: "Justification meets HIPAA minimum necessary standard"
}

# Step 2: Data Privacy Officer (pending)
{
  id: "step_002",
  request_id: "550e8400-e29b-41d4-a716-446655440000",
  position: 1,
  role: "data_privacy_officer",
  status: "pending",
  acted_at: null,
  approver_id: null,
  note: null
}

# Step 3: System Owner (not yet reached)
{
  id: "step_003",
  request_id: "550e8400-e29b-41d4-a716-446655440000",
  position: 2,
  role: "system_owner",
  status: "pending",
  acted_at: null,
  approver_id: null,
  note: null
}
```

---

#### 4. AuditEntry
**File:** `app/models/violet/audit/entry.rb`

**Business Concept:** Immutable record of every action

**Database Table:** `violet_audit_entries`

**Key Fields:**
```ruby
id                # UUID primary key
auditable_type    # Polymorphic: "Violet::Security::PHIAccessRequest"
auditable_id      # Which record
actor_type        # "User", "System", "Integration"
actor_id          # Who/what did this
action            # "created", "approved", "rejected", "provisioned"
payload           # JSONB: full context of the action
signed_digest     # Cryptographic signature for tamper detection
created_at        # When it happened (immutable, no updated_at)
```

**Sample Record:**
```ruby
{
  id: "audit_001",
  auditable_type: "Violet::Security::PHIAccessRequest",
  auditable_id: "550e8400-e29b-41d4-a716-446655440000",
  actor_type: "User",
  actor_id: "user_456",
  action: "approval_step_approved",
  payload: {
    "step_position": 0,
    "step_role": "compliance_officer",
    "note": "Justification meets HIPAA minimum necessary standard",
    "policy_version": "v2.3",
    "request_risk_level": "medium",
    "timestamp": "2025-11-11T15:30:00Z"
  },
  signed_digest: "sha256:abc123...",
  created_at: "2025-11-11 15:30:00 UTC"
}
```

**Why Immutable?**
- Regulators require tamper-proof audit trails
- Signed digest detects unauthorized changes
- No `updated_at` or soft deletes - once written, forever preserved
- Supports event sourcing: reconstruct state by replaying entries

---

### Database Relationships

```
PHIAccessRequest
  ├─ has_many :approval_steps (sorted by position)
  ├─ has_many :audit_entries (polymorphic)
  └─ belongs_to :policy

PHIAccessPolicy
  └─ has_many :requests

PHIAccessApprovalStep
  ├─ belongs_to :request
  ├─ belongs_to :approver (User)
  └─ has_many :audit_entries (polymorphic)

AuditEntry
  └─ belongs_to :auditable (polymorphic: Request or Step)
```

---

## Control Plane Deep Dive

### Services and Business Logic

#### 1. ApprovalEngine
**File:** `app/services/violet/workflow/approval_engine.rb`

**Business Purpose:** Orchestrates the entire approval lifecycle

**Key Methods:**

##### `submit(request_attrs:, actor:)`
**What it does:**
1. Creates new `PHIAccessRequest` record
2. Calls `RiskScorer.score(request)` to calculate risk level
3. Looks up applicable `PHIAccessPolicy` for the system
4. Builds approval steps from policy's approval chain
5. Transitions request to `submitted` state
6. Publishes `phi_access.requested` event
7. Returns request object

**Code Example:**
```ruby
def submit(request_attrs:, actor:)
  request = PHIAccessRequest.new(request_attrs)
  request.requester = actor
  request.status = :draft

  # Calculate risk
  request.risk_level = RiskScorer.score(request)

  # Find applicable policy
  policy = PHIAccessPolicy.find_by(system_id: request.system_id)
  raise PolicyNotFoundError unless policy

  # Validate against policy
  raise DurationExceedsPolicy if request.duration_days > policy.max_duration_days

  # Build approval chain
  policy.approval_chain.each_with_index do |step_config, position|
    request.approval_steps.build(
      position: position,
      role: step_config["role"],
      status: :pending
    )
  end

  # Save and transition
  request.save!
  request.update!(status: :submitted)

  # Audit
  AuditLogger.log(request, actor, "request.submitted", request.attributes)

  # Notify first approver
  notify_next_approver(request)

  request
end
```

---

##### `advance(step_id:, decision:, actor:, note:)`
**What it does:**
1. Validates actor has permission to approve this step
2. Records decision (approve/reject) and note
3. Publishes audit event
4. If approved:
   - Checks if more steps remain
   - If yes: transitions to next step, notifies next approver
   - If no: transitions to `approved`, enqueues provisioning job
5. If rejected:
   - Transitions to `awaiting_rework`
   - Notifies requester with rejection reason

**Code Example:**
```ruby
def advance(step_id:, decision:, actor:, note:)
  step = PHIAccessApprovalStep.find(step_id)
  request = step.request

  # Validate
  raise UnauthorizedError unless can_approve?(actor, step)
  raise InvalidStateError unless step.pending?

  # Record decision
  step.update!(
    status: decision, # :approved or :rejected
    approver: actor,
    acted_at: Time.current,
    note: note
  )

  # Audit
  AuditLogger.log(step, actor, "approval_step.#{decision}", {
    step_position: step.position,
    note: note
  })

  # Handle based on decision
  if decision == :approved
    if all_steps_approved?(request)
      request.update!(status: :approved)
      ProvisionerJob.perform_later(request.id)
    else
      notify_next_approver(request)
    end
  elsif decision == :rejected
    request.update!(status: :awaiting_rework)
    notify_requester_of_rejection(request, step)
  end

  request
end
```

---

#### 2. RiskScorer
**File:** `app/services/violet/policies/risk_scorer.rb`

**Business Purpose:** Calculate risk level based on HIPAA policy

**Risk Factors:**
- System sensitivity (EMR = high, Billing = medium, Lab = low)
- Duration requested (> 14 days = higher risk)
- Requester's role (clinical = lower risk, admin = higher risk)
- Recent access history (frequent requester = lower risk)
- Time of day (after hours = higher risk)

**Key Method:**

##### `score(request)`
**What it does:**
1. Retrieves system sensitivity from policy
2. Evaluates duration against thresholds
3. Checks requester's role and history
4. Applies scoring algorithm
5. Returns risk level: `:low`, `:medium`, or `:high`

**Code Example:**
```ruby
def self.score(request)
  score = 0

  # System sensitivity
  system_risk = SYSTEM_RISK_MAP[request.system_id] || :medium
  score += RISK_POINTS[system_risk]

  # Duration
  if request.duration_days > 14
    score += 30
  elsif request.duration_days > 7
    score += 15
  end

  # Requester role
  if request.requester.role.in?(%w[clinical_staff physician])
    score -= 10 # Lower risk for clinical roles
  elsif request.requester.role == "administrative"
    score += 10 # Higher risk for admin roles
  end

  # Recent access history
  recent_requests = PHIAccessRequest
    .where(requester: request.requester)
    .where("created_at > ?", 90.days.ago)
    .count

  score -= 5 if recent_requests > 5 # Frequent, trusted requester

  # Time of day (after hours = suspicious)
  score += 10 if Time.current.hour.in?(22..6)

  # Map score to risk level
  case score
  when 0..30 then :low
  when 31..60 then :medium
  else :high
  end
end
```

**Why This Matters:**
- Automated risk scoring reduces manual review burden
- High-risk requests get extra scrutiny
- Low-risk requests can be fast-tracked
- Transparent algorithm can be audited

---

#### 3. Provisioner
**File:** `app/services/violet/integrations/provisioner.rb`

**Business Purpose:** Interface with external IAM system to grant/revoke access

**Key Methods:**

##### `provision(request)`
**What it does:**
1. Constructs IAM API payload (user, system, permissions, expiration)
2. Calls external IAM API endpoint
3. Parses response
4. If success: returns access grant details
5. If failure: raises error with diagnostic info

**Code Example:**
```ruby
def self.provision(request)
  payload = {
    user_id: request.requester.external_id,
    system_id: request.system_id,
    permissions: ["read", "write"], # Derived from policy
    expires_at: request.approved_until.iso8601,
    justification: request.justification,
    approval_ids: request.approval_steps.pluck(:id)
  }

  response = HTTParty.post(
    ENV["IAM_API_URL"] + "/access_grants",
    body: payload.to_json,
    headers: {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{ENV['IAM_API_KEY']}"
    },
    timeout: 10
  )

  if response.success?
    {
      grant_id: response["id"],
      status: "active",
      provisioned_at: Time.current
    }
  else
    raise ProvisioningError, "IAM API error: #{response.code} - #{response.body}"
  end
end
```

---

#### 4. ProvisionerJob
**File:** `app/jobs/violet/integrations/provisioner_job.rb`

**Business Purpose:** Background job for async provisioning (doesn't block UI)

**Key Method:**

##### `perform(request_id)`
**What it does:**
1. Loads request from database
2. Calls `Provisioner.provision(request)`
3. If success:
   - Transitions request to `active`
   - Logs audit entry
   - Notifies requester "access granted"
4. If failure:
   - Retries up to 3 times (exponential backoff)
   - If still failing: transitions to `provisioning_failed`
   - Alerts approvers and SRE team

**Code Example:**
```ruby
class ProvisionerJob < ApplicationJob
  queue_as :urgent
  retry_on ProvisioningError, wait: :exponentially_longer, attempts: 3

  def perform(request_id)
    request = PHIAccessRequest.find(request_id)

    # Transition to provisioning state
    request.update!(status: :provisioning)

    # Call IAM
    result = Provisioner.provision(request)

    # Success: activate request
    request.update!(
      status: :active,
      external_grant_id: result[:grant_id]
    )

    AuditLogger.log(request, :system, "access.provisioned", result)

    notify_requester(request, :granted)

  rescue ProvisioningError => e
    # Log failure
    AuditLogger.log(request, :system, "access.provisioning_failed", {
      error: e.message,
      attempt: executions
    })

    if executions >= 3
      # Permanent failure
      request.update!(status: :provisioning_failed)
      alert_ops_team(request, e)
      notify_approvers(request, :provisioning_failed)
    else
      # Will retry
      raise e
    end
  end
end
```

**Why Background Job?**
- External API calls can be slow (seconds)
- User shouldn't wait for IAM to respond
- Retries handle transient network issues
- Failures don't block approval workflow

---

#### 5. SlaNudger
**File:** `app/services/violet/notifications/sla_nudger.rb`

**Business Purpose:** Monitor SLA compliance, send reminders/escalations

**Key Method:**

##### `check_and_notify`
**What it does:**
1. Finds all requests in approval states
2. For each, calculates time since last action
3. If SLA threshold exceeded (from policy):
   - Sends reminder email/Slack to pending approver
4. If escalation threshold exceeded:
   - Notifies approver's manager
   - Marks request for escalation in dashboard

**Code Example:**
```ruby
def self.check_and_notify
  pending_requests = PHIAccessRequest
    .where(status: [:awaiting_compliance, :awaiting_privacy, :awaiting_owner])

  pending_requests.each do |request|
    current_step = request.current_approval_step
    policy = request.policy

    hours_waiting = (Time.current - current_step.created_at) / 1.hour

    if hours_waiting > policy.escalation_rule["escalation_hours"]
      escalate(request, current_step)
    elsif hours_waiting > policy.escalation_rule["sla_hours"]
      remind(request, current_step)
    end
  end
end

private

def self.remind(request, step)
  ApproverMailer.sla_reminder(
    approver: step.approver_candidate,
    request: request,
    hours_waiting: hours_waiting
  ).deliver_later
end

def self.escalate(request, step)
  manager = step.approver_candidate.manager

  ApproverMailer.sla_breach_escalation(
    manager: manager,
    approver: step.approver_candidate,
    request: request
  ).deliver_later

  request.update!(escalated: true)
end
```

**Runs via cron:**
```ruby
# config/schedule.rb
every 1.hour do
  runner "Violet::Notifications::SlaNudger.check_and_notify"
end
```

---

### State Machine

**File:** `app/services/violet/workflow/state_maps/phi_access.rb`

**States and Transitions:**

```
draft
  └─ submit → submitted

submitted
  └─ score → risk_review

risk_review
  ├─ low_risk → awaiting_owner (skip compliance/privacy)
  └─ med/high → awaiting_compliance

awaiting_compliance
  ├─ approve → awaiting_privacy
  └─ reject → awaiting_rework

awaiting_privacy
  ├─ approve → awaiting_owner
  └─ reject → awaiting_rework

awaiting_owner
  ├─ approve → approved
  └─ reject → awaiting_rework

approved
  └─ provision → provisioning

provisioning
  ├─ success → active
  └─ failure → provisioning_failed

active
  ├─ expire → expired
  └─ revoke → revoked

awaiting_rework
  └─ resubmit → submitted (loops back)
```

**Guards (Validations on Transitions):**
- Can't provision if `approved_until` is in the past
- Can't approve own request (segregation of duties)
- Can't revoke if already expired
- Can't resubmit without changing justification

---

## Management Plane Deep Dive

### Controllers and Views

#### 1. PHIAccessRequestsController
**File:** `app/controllers/violet/admin/phi_access_requests_controller.rb`

**Routes:**
```ruby
# config/routes.rb
namespace :violet do
  namespace :admin do
    resources :phi_access_requests do
      member do
        post :approve_step
        post :reject_step
        post :revoke
      end
      collection do
        get :dashboard
      end
    end
  end
end
```

**Actions:**

##### `index` (Approval Queue)
**What it shows:**
- All requests pending current user's approval
- Filterable by risk level, system, SLA status
- Sortable by SLA urgency, date submitted

**View:** `app/views/violet/admin/phi_access_requests/index.html.erb`

**Code:**
```ruby
def index
  @requests = PHIAccessRequest
    .awaiting_approval_by(current_user)
    .includes(:requester, :current_approval_step)
    .filter_by(params[:filters])
    .sort_by_sla_urgency

  # Turbo Stream updates for real-time queue changes
  respond_to do |format|
    format.html
    format.turbo_stream
  end
end
```

**View Excerpt:**
```erb
<%= turbo_frame_tag "requests_queue" do %>
  <div class="filters">
    <%= form_with url: violet_admin_phi_access_requests_path, method: :get, data: { turbo_frame: "requests_queue" } do |f| %>
      <%= f.select :risk_level, options_for_select([["All", ""], ["Low", "low"], ["Medium", "medium"], ["High", "high"]], params[:risk_level]) %>
      <%= f.select :sla_status, options_for_select([["All", ""], ["On Time", "on_time"], ["At Risk", "at_risk"], ["Breached", "breached"]], params[:sla_status]) %>
      <%= f.submit "Filter", class: "btn-secondary" %>
    <% end %>
  </div>

  <div class="requests-list">
    <% @requests.each do |request| %>
      <%= render "request_card", request: request %>
    <% end %>
  </div>
<% end %>
```

---

##### `show` (Request Detail)
**What it shows:**
- Full request details
- Timeline of all approval steps
- Decision panel (if pending current user's approval)
- Audit log (expandable)

**View:** `app/views/violet/admin/phi_access_requests/show.html.erb`

**Code:**
```ruby
def show
  @request = PHIAccessRequest
    .includes(approval_steps: :approver, audit_entries: :actor)
    .find(params[:id])

  @can_decide = @request.can_be_decided_by?(current_user)
  @current_step = @request.current_approval_step
end
```

**View Excerpt:**
```erb
<div class="request-detail">
  <header>
    <h1>PHI Access Request #<%= @request.id.first(8) %></h1>
    <%= render "status_badge", status: @request.status %>
    <%= render "risk_badge", risk: @request.risk_level %>
    <div class="sla-countdown" data-controller="countdown" data-countdown-target-value="<%= @request.sla_deadline.iso8601 %>">
      <%= distance_of_time_in_words_to_now(@request.sla_deadline) %> remaining
    </div>
  </header>

  <section class="request-info">
    <dl>
      <dt>Requester</dt>
      <dd><%= @request.requester.name %> (<%= @request.requester.role %>)</dd>

      <dt>System</dt>
      <dd><%= @request.system_id %></dd>

      <dt>Duration</dt>
      <dd><%= @request.duration_days %> days (until <%= @request.approved_until&.to_date %>)</dd>

      <dt>Justification</dt>
      <dd><%= simple_format(@request.justification) %></dd>
    </dl>
  </section>

  <section class="approval-timeline">
    <h2>Approval Progress</h2>
    <%= render "timeline", steps: @request.approval_steps %>
  </section>

  <% if @can_decide %>
    <section class="decision-panel">
      <%= render "decision_form", request: @request, step: @current_step %>
    </section>
  <% end %>

  <details class="audit-log">
    <summary>View Audit Log</summary>
    <%= render "audit_entries", entries: @request.audit_entries %>
  </details>
</div>
```

---

##### `approve_step` (Approve Action)
**What it does:**
1. Validates current user can approve this step
2. Calls `ApprovalEngine.advance` with `:approved` decision
3. Updates UI via Turbo Stream (removes from queue, updates detail view)

**Code:**
```ruby
def approve_step
  @request = PHIAccessRequest.find(params[:id])
  @step = @request.current_approval_step

  authorize! :approve, @request

  ApprovalEngine.advance(
    step_id: @step.id,
    decision: :approved,
    actor: current_user,
    note: params[:note]
  )

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.remove("request_card_#{@request.id}"), # Remove from queue
        turbo_stream.update("flash", partial: "shared/flash", locals: { notice: "Request approved" })
      ]
    end
    format.html { redirect_to violet_admin_phi_access_requests_path, notice: "Request approved" }
  end
end
```

**Turbo Stream Response:**
The response automatically updates the page without full reload:
- Removes request card from queue (it's no longer pending current user)
- Shows success toast notification
- If detail view is open, updates timeline to show approval

---

#### 2. DashboardsController
**File:** `app/controllers/violet/admin/dashboards/phi_access_controller.rb`

**Route:**
```ruby
get "violet/admin/phi_access/dashboard", to: "violet/admin/dashboards/phi_access#show"
```

**What it shows:**
- Key metrics: pending count, SLA compliance %, avg approval time
- Bottleneck heatmap: which approval step is slowest
- Trend chart: requests over time
- Export button for compliance report

**Code:**
```ruby
def show
  date_range = params[:date_range]&.to_sym || :last_30_days

  @metrics = {
    pending_count: PHIAccessRequest.pending.count,
    sla_compliance: calculate_sla_compliance(date_range),
    avg_approval_time: calculate_avg_approval_time(date_range)
  }

  @bottleneck_data = bottleneck_analysis(date_range)
  @trend_data = requests_over_time(date_range)
end

private

def calculate_sla_compliance(date_range)
  completed = PHIAccessRequest.completed.where(created_at: range_for(date_range))
  on_time = completed.where("completed_at <= sla_deadline")

  (on_time.count.to_f / completed.count * 100).round(1)
end

def bottleneck_analysis(date_range)
  PHIAccessApprovalStep
    .where(created_at: range_for(date_range))
    .where.not(acted_at: nil)
    .group(:role)
    .average("EXTRACT(EPOCH FROM (acted_at - created_at)) / 3600") # Hours
    .sort_by { |_, hours| -hours }
end
```

**View Excerpt:**
```erb
<div class="dashboard">
  <div class="metrics-cards">
    <div class="metric">
      <h3><%= @metrics[:pending_count] %></h3>
      <p>Pending Requests</p>
    </div>
    <div class="metric">
      <h3><%= @metrics[:sla_compliance] %>%</h3>
      <p>SLA Compliance</p>
    </div>
    <div class="metric">
      <h3><%= @metrics[:avg_approval_time].round(1) %>h</h3>
      <p>Avg Approval Time</p>
    </div>
  </div>

  <div class="bottleneck-chart">
    <h2>Bottleneck Analysis</h2>
    <% @bottleneck_data.each do |role, hours| %>
      <div class="bar">
        <span class="label"><%= role.humanize %></span>
        <div class="progress" style="width: <%= hours / @bottleneck_data.values.max * 100 %>%">
          <%= hours.round(1) %>h
        </div>
      </div>
    <% end %>
  </div>

  <%= link_to "Export Compliance Report", export_violet_admin_phi_access_requests_path(format: :csv), class: "btn-secondary" %>
</div>
```

---

### Real-Time Updates (Hotwire/Turbo)

**How it works:**
1. When request state changes (e.g., approval granted), controller broadcasts Turbo Stream
2. All connected clients subscribed to that request receive update
3. Browser updates specific page elements without full refresh

**Broadcasting from Controller:**
```ruby
# After successful approval
broadcast_update_to(
  @request,
  target: "request_#{@request.id}_timeline",
  partial: "violet/admin/phi_access_requests/timeline",
  locals: { steps: @request.approval_steps.reload }
)
```

**Subscribing in View:**
```erb
<%= turbo_stream_from @request %>

<div id="request_<%= @request.id %>_timeline">
  <%= render "timeline", steps: @request.approval_steps %>
</div>
```

**Result:** Approver sees timeline update instantly when someone else approves a step

---

## User Journey Walkthrough

### Journey 1: Requester Submits Request

**Step 1: Navigate to Request Form**
- URL: `/violet/admin/phi_access_requests/new`
- Sees form with fields: System dropdown, Justification textarea, Duration selector

**Step 2: Fill Out Form**
- Selects "EMR Production" from system dropdown
- Enters justification: "Need to review patient chart for billing dispute on claim #98765"
- Selects duration: 7 days
- Sees client-side risk preview: "Medium Risk" (calculated via JavaScript, previews RiskScorer logic)

**Step 3: Submit**
- Clicks "Submit Request" button
- Form submits to `POST /violet/admin/phi_access_requests`
- Controller calls `ApprovalEngine.submit`
- Engine creates request, scores risk, builds approval steps
- Redirects to request detail page with success message

**Backend Flow:**
```
1. PHIAccessRequestsController#create
2. ApprovalEngine.submit(request_attrs, actor: current_user)
   3. RiskScorer.score(request) → "medium"
   4. Find policy for "emr_prod"
   5. Build 3 approval steps (compliance, privacy, owner)
   6. Save request (status: submitted)
   7. AuditLogger.log("request.submitted")
   8. Notify compliance officer (email + Slack)
9. Return request
10. Redirect to show page
```

**What requester sees:**
- Request detail page with status "Awaiting Compliance Approval"
- Timeline showing: ✓ Submitted, ⧗ Awaiting Compliance (you are here), ○ Awaiting Privacy, ○ Awaiting Owner
- Message: "Your request has been submitted. Compliance officer will review within 24 hours."

---

### Journey 2: Compliance Officer Approves

**Step 1: Receive Notification**
- Email: "You have a new PHI access request pending your approval"
- Slack: "@compliance-officer: Request #12345 from Jane Doe needs review"

**Step 2: Navigate to Queue**
- URL: `/violet/admin/phi_access_requests`
- Sees pending requests sorted by SLA urgency
- Request #12345 at top with "SLA: 22h remaining" chip

**Step 3: Review Request**
- Clicks request card
- Modal/detail view opens
- Reads justification, checks risk level (medium), verifies requester role
- Thinks: "Justification is clear and meets minimum necessary standard"

**Step 4: Approve**
- Types note: "Justification meets HIPAA minimum necessary standard"
- Clicks "Approve" button
- Optimistic UI: button disables, spinner shows, timeline updates immediately

**Backend Flow:**
```
1. PHIAccessRequestsController#approve_step
2. ApprovalEngine.advance(step_id: step_001, decision: :approved, actor: compliance_officer, note: "...")
   3. Validate compliance_officer can approve this step ✓
   4. Update step status: pending → approved
   5. Record approver_id, acted_at, note
   6. AuditLogger.log("approval_step.approved")
   7. Check if more steps remain: YES (privacy, owner)
   8. Update request status: awaiting_compliance → awaiting_privacy
   9. Notify privacy officer (email + Slack)
10. Turbo Stream broadcast updates
11. Return success
```

**What compliance officer sees:**
- Toast notification: "Request approved"
- Request card removed from their queue (no longer pending them)
- If they had detail view open: timeline updates to show their approval

**What requester sees (if subscribed via Turbo Stream):**
- Timeline updates: ✓ Submitted, ✓ Approved by Compliance, ⧗ Awaiting Privacy (new step)

---

### Journey 3: Privacy Officer Approves, Then System Owner Approves

**(Same flow as Journey 2, but for privacy officer, then system owner)**

After system owner approves (final step):

**Backend Flow:**
```
1. ApprovalEngine.advance(step_id: step_003, decision: :approved, actor: system_owner, note: "...")
   2. Update step status: pending → approved
   3. AuditLogger.log("approval_step.approved")
   4. Check if more steps remain: NO (all approved!)
   5. Update request status: awaiting_owner → approved
   6. AuditLogger.log("request.approved")
   7. Enqueue ProvisionerJob.perform_later(request.id)
8. Turbo Stream broadcast updates
9. Return success
```

**ProvisionerJob executes:**
```
1. Load request from DB
2. Transition status: approved → provisioning
3. Call Provisioner.provision(request)
   4. POST to IAM API with payload
   5. IAM returns success: { id: "grant_789", status: "active" }
6. Transition status: provisioning → active
7. AuditLogger.log("access.provisioned", { grant_id: "grant_789" })
8. Email requester: "Your PHI access has been granted and is now active"
```

**What requester sees:**
- Email: "Your PHI access request has been approved and access is now active."
- Detail view updates: Status badge changes to "Active"
- Shows: "Access expires on 2025-11-18 at 11:59 PM"

---

### Journey 4: SLA Breach and Escalation

**Scenario:** Compliance officer is on vacation, doesn't approve within 24 hours

**Hourly cron job runs:**
```
1. SlaNudger.check_and_notify
2. Find all pending requests
3. For request #12345:
   - Hours waiting: 26h
   - Policy SLA: 24h
   - Policy escalation: 48h
4. Hours waiting (26) > SLA (24) → send reminder
5. Email compliance officer: "Reminder: Request #12345 has been pending 26 hours"
```

**48 hours later, still no action:**
```
1. SlaNudger.check_and_notify
2. Hours waiting: 50h
3. Hours waiting (50) > escalation (48) → escalate
4. Find compliance officer's manager (compliance director)
5. Email compliance director: "SLA breach: Request #12345 pending 50h, needs immediate attention"
6. Update request: escalated = true
7. Dashboard shows red "SLA Breach" badge
```

**What compliance director sees:**
- Email with escalation notice
- Logs in, sees request #12345 with red "SLA BREACH" badge
- Can approve on behalf of compliance officer (delegation rules)

---

## Testing Strategy

### Test Coverage by Layer

#### Data Plane (Model Tests)
**File:** `test/models/violet/security/phi_access_request_test.rb`

**What we test:**
- Validations (presence, length, format)
- Associations (has_many :approval_steps)
- Scopes (e.g., `PHIAccessRequest.pending`)
- State transitions (can move from submitted → approved, but not submitted → active)
- Business rules (can't approve if expired)

**Example:**
```ruby
test "cannot approve request if approved_until is in the past" do
  request = phi_access_requests(:expired)
  assert request.approved_until < Time.current

  assert_raises(Violet::InvalidStateError) do
    request.approve!
  end
end
```

---

#### Control Plane (Service Tests)
**File:** `test/services/violet/workflow/approval_engine_test.rb`

**What we test:**
- Happy path: submit → approve all steps → provision
- Rejection path: approve some steps → reject → awaiting rework
- Edge cases: duplicate submit, approve out of order, approve after expiration
- Audit logging: every action creates audit entry

**Example:**
```ruby
test "submit creates request with correct approval chain" do
  actor = users(:jane)

  request = ApprovalEngine.submit(
    request_attrs: {
      system_id: "emr_prod",
      justification: "Need access for billing",
      duration_days: 7
    },
    actor: actor
  )

  assert_equal "submitted", request.status
  assert_equal "medium", request.risk_level
  assert_equal 3, request.approval_steps.count

  steps = request.approval_steps.order(:position)
  assert_equal "compliance_officer", steps[0].role
  assert_equal "data_privacy_officer", steps[1].role
  assert_equal "system_owner", steps[2].role
end

test "approving all steps triggers provisioning" do
  request = phi_access_requests(:with_all_steps_pending)

  # Approve step 1
  ApprovalEngine.advance(
    step_id: request.approval_steps.first.id,
    decision: :approved,
    actor: users(:compliance_officer),
    note: "LGTM"
  )

  assert_equal "awaiting_privacy", request.reload.status

  # Approve step 2
  ApprovalEngine.advance(
    step_id: request.approval_steps.second.id,
    decision: :approved,
    actor: users(:privacy_officer),
    note: "Approved"
  )

  assert_equal "awaiting_owner", request.reload.status

  # Approve step 3 (final)
  assert_enqueued_with(job: ProvisionerJob) do
    ApprovalEngine.advance(
      step_id: request.approval_steps.third.id,
      decision: :approved,
      actor: users(:system_owner),
      note: "Granted"
    )
  end

  assert_equal "approved", request.reload.status
end
```

---

#### Management Plane (Integration Tests)
**File:** `test/integration/violet_admin_phi_access_requests_flow_test.rb`

**What we test:**
- End-to-end user flows with browser simulation
- Full request → approve → provision cycle
- UI interactions (form submission, button clicks, Turbo Stream updates)
- Authorization (users can only approve appropriate steps)

**Example:**
```ruby
test "requester can submit request and see it in queue" do
  sign_in users(:jane)

  # Navigate to new request form
  get new_violet_admin_phi_access_request_path
  assert_response :success

  # Fill out form
  post violet_admin_phi_access_requests_path, params: {
    phi_access_request: {
      system_id: "emr_prod",
      justification: "Need access for patient billing dispute",
      duration_days: 7
    }
  }

  assert_redirected_to violet_admin_phi_access_request_path(PHIAccessRequest.last)
  follow_redirect!

  assert_select "h1", text: /Request #/
  assert_select ".status-badge", text: "Awaiting Compliance Approval"

  # Check audit log
  request = PHIAccessRequest.last
  assert_equal 1, request.audit_entries.count
  assert_equal "request.submitted", request.audit_entries.last.action
end

test "compliance officer can approve from queue" do
  request = phi_access_requests(:awaiting_compliance)
  sign_in users(:compliance_officer)

  # View queue
  get violet_admin_phi_access_requests_path
  assert_response :success
  assert_select ".request-card", count: 1

  # Approve
  post approve_step_violet_admin_phi_access_request_path(request), params: {
    note: "Justification meets HIPAA standard"
  }

  assert_redirected_to violet_admin_phi_access_requests_path

  # Verify state change
  assert_equal "awaiting_privacy", request.reload.status
  assert_equal "approved", request.approval_steps.first.status
end
```

---

#### Background Jobs (Job Tests)
**File:** `test/jobs/violet/integrations/provisioner_job_test.rb`

**What we test:**
- Successful provisioning updates request status
- Failed provisioning retries with backoff
- Permanent failures alert ops team
- Audit entries created for all outcomes

**Example:**
```ruby
test "successful provisioning transitions request to active" do
  request = phi_access_requests(:approved)

  # Stub external API
  stub_request(:post, "https://iam.example.com/access_grants")
    .to_return(status: 200, body: { id: "grant_123", status: "active" }.to_json)

  perform_enqueued_jobs do
    ProvisionerJob.perform_later(request.id)
  end

  assert_equal "active", request.reload.status
  assert_equal "grant_123", request.external_grant_id

  # Check audit log
  audit_entry = request.audit_entries.find_by(action: "access.provisioned")
  assert_not_nil audit_entry
  assert_equal "grant_123", audit_entry.payload["grant_id"]
end

test "failed provisioning retries and eventually fails" do
  request = phi_access_requests(:approved)

  # Stub external API to fail
  stub_request(:post, "https://iam.example.com/access_grants")
    .to_return(status: 500, body: "Internal Server Error")

  perform_enqueued_jobs do
    ProvisionerJob.perform_later(request.id)
  end

  assert_equal "provisioning_failed", request.reload.status

  # Check retry attempts (3 total)
  audit_entries = request.audit_entries.where(action: "access.provisioning_failed")
  assert_equal 3, audit_entries.count
end
```

---

## Extending This Pattern

### Adding a New Approval Workflow

Let's say you want to add **Budget Override Approvals** for finance. Here's how to extend the pattern:

#### 1. Define Business Requirements
```
Job: When a project manager needs to exceed their allocated budget, they can request an override, have it approved by finance and executive, so that critical projects aren't blocked by budget constraints.

Actors:
- Requester: Project manager
- Approver 1: Finance controller
- Approver 2: CFO (if override > $50K)
- Auditor: Internal audit team

States: draft → submitted → awaiting_finance → awaiting_cfo (if needed) → approved → active → expired
```

#### 2. Create Data Models
```ruby
# app/models/violet/finance/budget_override_request.rb
class Violet::Finance::BudgetOverrideRequest < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :project
  has_many :approval_steps, class_name: "Violet::Finance::BudgetOverrideApprovalStep"
  has_many :audit_entries, as: :auditable, class_name: "Violet::Audit::Entry"

  enum status: {
    draft: 0,
    submitted: 1,
    awaiting_finance: 2,
    awaiting_cfo: 3,
    approved: 4,
    active: 5,
    expired: 6,
    denied: 7
  }

  validates :project_id, :amount, :justification, presence: true
  validates :amount, numericality: { greater_than: 0 }
end

# app/models/violet/finance/budget_override_policy.rb
class Violet::Finance::BudgetOverridePolicy < ApplicationRecord
  validates :cfo_threshold, numericality: { greater_than: 0 }
end
```

#### 3. Build Control Plane Services
```ruby
# app/services/violet/workflow/budget_override_engine.rb
class Violet::Workflow::BudgetOverrideEngine
  def self.submit(request_attrs:, actor:)
    request = Violet::Finance::BudgetOverrideRequest.new(request_attrs)
    request.requester = actor

    policy = Violet::Finance::BudgetOverridePolicy.first

    # Build approval chain based on amount
    request.approval_steps.build(position: 0, role: "finance_controller")

    if request.amount > policy.cfo_threshold
      request.approval_steps.build(position: 1, role: "cfo")
    end

    request.save!
    request.update!(status: :submitted)

    Violet::Audit::Logger.log(request, actor, "request.submitted", request.attributes)

    request
  end

  # Similar advance, reject methods...
end
```

#### 4. Create Management Plane UI
```ruby
# app/controllers/violet/admin/budget_override_requests_controller.rb
class Violet::Admin::BudgetOverrideRequestsController < Violet::Admin::BaseController
  def index
    @requests = Violet::Finance::BudgetOverrideRequest
      .awaiting_approval_by(current_user)
      .includes(:requester, :project)
  end

  def show
    @request = Violet::Finance::BudgetOverrideRequest.find(params[:id])
  end

  # Similar approve_step, reject_step methods...
end
```

#### 5. Add Routes
```ruby
namespace :violet do
  namespace :admin do
    resources :budget_override_requests do
      member do
        post :approve_step
        post :reject_step
      end
    end
  end
end
```

#### 6. Write Tests
- Model tests for validations, associations, state transitions
- Service tests for approval engine logic
- Integration tests for end-to-end flows
- Job tests if external systems involved

**Key Point:** You've now replicated the PHI Access pattern for a completely different domain (finance instead of healthcare) by following the same three-plane architecture.

---

## Conclusion

This reference implementation shows how:
1. **Business requirements** (HIPAA compliance, approval workflows) translate to **technical architecture** (three planes)
2. **Domain knowledge** (regulatory obligations, policy rules) encodes into **code** (models, services, policies)
3. **User journeys** (request → approve → provision) flow through **layers** (UI → control → data)
4. **Testing strategy** validates **business logic** at all levels

**Next Steps:**
- Review actual code in `app/models/violet/security/`, `app/services/violet/workflow/`, `app/controllers/violet/admin/`
- Run test suite: `bundle exec rails test`
- Experiment with creating a new approval workflow using this pattern
- Refer to `BUSINESS_USER_GUIDE.md` for scoping your own features

---

**Questions or feedback?** Open an issue or submit a PR with improvements to this reference guide.
