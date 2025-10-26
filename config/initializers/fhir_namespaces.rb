# FHIR R4 API Namespace Definitions
# This file creates the core FHIR resources as Violet Rails API Namespaces
# Run: rails db:seed:fhir to initialize

module FhirNamespaces
  # FHIR Patient Resource
  PATIENT = {
    name: 'FhirPatient',
    slug: 'fhir-patient',
    version: '1',
    properties: {
      # FHIR required fields
      resourceType: { type: 'string', default: 'Patient' },
      
      # Identifiers
      identifier: { type: 'array', description: 'Patient identifiers (MRN, SSN, etc.)' },
      
      # Demographics
      name: { type: 'array', required: true, description: 'Patient name(s)' },
      gender: { type: 'string', enum: ['male', 'female', 'other', 'unknown'] },
      birthDate: { type: 'date', required: true },
      
      # Contact
      telecom: { type: 'array', description: 'Phone, email, etc.' },
      address: { type: 'array' },
      
      # Status
      active: { type: 'boolean', default: true },
      deceased: { type: 'boolean', default: false },
      deceasedDateTime: { type: 'datetime' },
      
      # Relationships
      maritalStatus: { type: 'object' },
      contact: { type: 'array', description: 'Emergency contacts' },
      communication: { type: 'array', description: 'Languages' },
      generalPractitioner: { type: 'array', description: 'Primary care providers' },
      managingOrganization: { type: 'object' },
      
      # Extensions
      photo: { type: 'array' },
      link: { type: 'array', description: 'Links to other patient resources' }
    },
    associations: [
      { namespace: 'FhirObservation', type: 'has_many', foreign_key: 'subject_id' },
      { namespace: 'FhirEncounter', type: 'has_many', foreign_key: 'subject_id' },
      { namespace: 'FhirCondition', type: 'has_many', foreign_key: 'subject_id' }
    ]
  }.freeze
  
  # FHIR Observation Resource
  OBSERVATION = {
    name: 'FhirObservation',
    slug: 'fhir-observation',
    version: '1',
    properties: {
      resourceType: { type: 'string', default: 'Observation' },
      
      # Status
      status: { 
        type: 'string', 
        required: true,
        enum: ['registered', 'preliminary', 'final', 'amended', 'corrected', 'cancelled', 'entered-in-error', 'unknown']
      },
      
      # Category
      category: { type: 'array', description: 'vital-signs, laboratory, imaging, etc.' },
      
      # Code (what was observed)
      code: { type: 'object', required: true, description: 'LOINC, SNOMED CT, etc.' },
      
      # Subject (patient)
      subject: { type: 'object', required: true },
      subject_id: { type: 'string', description: 'Reference to FhirPatient' },
      
      # Context
      encounter: { type: 'object' },
      encounter_id: { type: 'string' },
      
      # Timing
      effectiveDateTime: { type: 'datetime' },
      effectivePeriod: { type: 'object' },
      issued: { type: 'datetime' },
      
      # Value
      valueQuantity: { type: 'object', description: 'Numeric value with unit' },
      valueCodeableConcept: { type: 'object' },
      valueString: { type: 'string' },
      valueBoolean: { type: 'boolean' },
      valueInteger: { type: 'integer' },
      valueRange: { type: 'object' },
      
      # Interpretation
      interpretation: { type: 'array' },
      note: { type: 'array' },
      
      # Reference ranges
      referenceRange: { type: 'array' },
      
      # Device
      device: { type: 'object' },
      device_id: { type: 'string' },
      
      # Performer
      performer: { type: 'array' }
    },
    associations: [
      { namespace: 'FhirPatient', type: 'belongs_to', foreign_key: 'subject_id' },
      { namespace: 'FhirEncounter', type: 'belongs_to', foreign_key: 'encounter_id' },
      { namespace: 'FhirDevice', type: 'belongs_to', foreign_key: 'device_id' }
    ]
  }.freeze
  
  # FHIR Practitioner Resource
  PRACTITIONER = {
    name: 'FhirPractitioner',
    slug: 'fhir-practitioner',
    version: '1',
    properties: {
      resourceType: { type: 'string', default: 'Practitioner' },
      
      identifier: { type: 'array', description: 'NPI, license numbers' },
      active: { type: 'boolean', default: true },
      name: { type: 'array', required: true },
      telecom: { type: 'array' },
      address: { type: 'array' },
      gender: { type: 'string', enum: ['male', 'female', 'other', 'unknown'] },
      birthDate: { type: 'date' },
      photo: { type: 'array' },
      qualification: { type: 'array', description: 'Certifications, degrees' },
      communication: { type: 'array' }
    }
  }.freeze
  
  # FHIR Organization Resource
  ORGANIZATION = {
    name: 'FhirOrganization',
    slug: 'fhir-organization',
    version: '1',
    properties: {
      resourceType: { type: 'string', default: 'Organization' },
      
      identifier: { type: 'array' },
      active: { type: 'boolean', default: true },
      type: { type: 'array', description: 'Hospital, clinic, pharmacy, etc.' },
      name: { type: 'string', required: true },
      alias: { type: 'array' },
      telecom: { type: 'array' },
      address: { type: 'array' },
      partOf: { type: 'object', description: 'Parent organization' },
      contact: { type: 'array' },
      endpoint: { type: 'array' }
    }
  }.freeze
  
  # FHIR Encounter Resource
  ENCOUNTER = {
    name: 'FhirEncounter',
    slug: 'fhir-encounter',
    version: '1',
    properties: {
      resourceType: { type: 'string', default: 'Encounter' },
      
      identifier: { type: 'array' },
      status: { 
        type: 'string', 
        required: true,
        enum: ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled']
      },
      class: { type: 'object', required: true, description: 'inpatient, outpatient, emergency' },
      type: { type: 'array' },
      priority: { type: 'object' },
      
      subject: { type: 'object', required: true },
      subject_id: { type: 'string' },
      
      participant: { type: 'array', description: 'Practitioners involved' },
      period: { type: 'object', description: 'Start and end time' },
      length: { type: 'object' },
      reasonCode: { type: 'array' },
      diagnosis: { type: 'array' },
      hospitalization: { type: 'object' },
      location: { type: 'array' }
    },
    associations: [
      { namespace: 'FhirPatient', type: 'belongs_to', foreign_key: 'subject_id' },
      { namespace: 'FhirObservation', type: 'has_many', foreign_key: 'encounter_id' }
    ]
  }.freeze
  
  # FHIR Device Resource (for wearables like Whoop)
  DEVICE = {
    name: 'FhirDevice',
    slug: 'fhir-device',
    version: '1',
    properties: {
      resourceType: { type: 'string', default: 'Device' },
      
      identifier: { type: 'array' },
      udiCarrier: { type: 'array' },
      status: { type: 'string', enum: ['active', 'inactive', 'entered-in-error', 'unknown'] },
      statusReason: { type: 'array' },
      distinctIdentifier: { type: 'string' },
      manufacturer: { type: 'string' },
      manufactureDate: { type: 'datetime' },
      expirationDate: { type: 'datetime' },
      lotNumber: { type: 'string' },
      serialNumber: { type: 'string' },
      deviceName: { type: 'array' },
      modelNumber: { type: 'string' },
      type: { type: 'object', description: 'Wearable, monitor, etc.' },
      version: { type: 'array' },
      patient: { type: 'object' },
      owner: { type: 'object' },
      contact: { type: 'array' },
      url: { type: 'string' },
      note: { type: 'array' }
    }
  }.freeze
  
  # FHIR Condition Resource
  CONDITION = {
    name: 'FhirCondition',
    slug: 'fhir-condition',
    version: '1',
    properties: {
      resourceType: { type: 'string', default: 'Condition' },
      
      identifier: { type: 'array' },
      clinicalStatus: { type: 'object', required: true },
      verificationStatus: { type: 'object' },
      category: { type: 'array' },
      severity: { type: 'object' },
      code: { type: 'object', description: 'ICD-10, SNOMED CT' },
      bodySite: { type: 'array' },
      
      subject: { type: 'object', required: true },
      subject_id: { type: 'string' },
      
      encounter: { type: 'object' },
      onsetDateTime: { type: 'datetime' },
      onsetPeriod: { type: 'object' },
      abatementDateTime: { type: 'datetime' },
      recordedDate: { type: 'datetime' },
      recorder: { type: 'object' },
      asserter: { type: 'object' },
      stage: { type: 'array' },
      evidence: { type: 'array' },
      note: { type: 'array' }
    },
    associations: [
      { namespace: 'FhirPatient', type: 'belongs_to', foreign_key: 'subject_id' }
    ]
  }.freeze
  
  # FHIR CarePlan Resource
  CARE_PLAN = {
    name: 'FhirCarePlan',
    slug: 'fhir-careplan',
    version: '1',
    properties: {
      resourceType: { type: 'string', default: 'CarePlan' },
      
      identifier: { type: 'array' },
      instantiatesCanonical: { type: 'array' },
      instantiatesUri: { type: 'array' },
      basedOn: { type: 'array' },
      replaces: { type: 'array' },
      partOf: { type: 'array' },
      status: { 
        type: 'string', 
        required: true,
        enum: ['draft', 'active', 'on-hold', 'revoked', 'completed', 'entered-in-error', 'unknown']
      },
      intent: { type: 'string', required: true },
      category: { type: 'array' },
      title: { type: 'string' },
      description: { type: 'string' },
      
      subject: { type: 'object', required: true },
      subject_id: { type: 'string' },
      
      encounter: { type: 'object' },
      period: { type: 'object' },
      created: { type: 'datetime' },
      author: { type: 'object' },
      contributor: { type: 'array' },
      careTeam: { type: 'array' },
      addresses: { type: 'array' },
      supportingInfo: { type: 'array' },
      goal: { type: 'array' },
      activity: { type: 'array' },
      note: { type: 'array' }
    },
    associations: [
      { namespace: 'FhirPatient', type: 'belongs_to', foreign_key: 'subject_id' }
    ]
  }.freeze
  
  # Helper method to create all namespaces
  def self.create_all!
    [PATIENT, OBSERVATION, PRACTITIONER, ORGANIZATION, ENCOUNTER, DEVICE, CONDITION, CARE_PLAN].each do |config|
      create_namespace(config)
    end
  end
  
  def self.create_namespace(config)
    namespace = ApiNamespace.find_or_initialize_by(slug: config[:slug])
    namespace.assign_attributes(
      name: config[:name],
      version: config[:version],
      properties: config[:properties],
      associations: config[:associations] || []
    )
    
    if namespace.save
      Rails.logger.info "✓ Created/Updated FHIR namespace: #{config[:name]}"
    else
      Rails.logger.error "✗ Failed to create namespace #{config[:name]}: #{namespace.errors.full_messages}"
    end
    
    namespace
  end
end
