# FHIR Resource Validation Service
# Uses fhir_models gem for FHIR R4 validation

module Fhir
  class Validator
    class ValidationError < StandardError; end
    
    # Validate a FHIR Patient resource
    def self.validate_patient(data)
      validate_resource(FHIR::Patient, data)
    end
    
    # Validate a FHIR Observation resource
    def self.validate_observation(data)
      validate_resource(FHIR::Observation, data)
    end
    
    # Validate a FHIR Practitioner resource
    def self.validate_practitioner(data)
      validate_resource(FHIR::Practitioner, data)
    end
    
    # Validate a FHIR Organization resource
    def self.validate_organization(data)
      validate_resource(FHIR::Organization, data)
    end
    
    # Validate a FHIR Encounter resource
    def self.validate_encounter(data)
      validate_resource(FHIR::Encounter, data)
    end
    
    # Validate a FHIR Device resource
    def self.validate_device(data)
      validate_resource(FHIR::Device, data)
    end
    
    # Validate a FHIR Condition resource
    def self.validate_condition(data)
      validate_resource(FHIR::Condition, data)
    end
    
    # Validate a FHIR CarePlan resource
    def self.validate_care_plan(data)
      validate_resource(FHIR::CarePlan, data)
    end
    
    # Generic validation method
    def self.validate_resource(klass, data)
      # Convert to hash if needed
      data = data.deep_symbolize_keys if data.respond_to?(:deep_symbolize_keys)
      
      # Create FHIR resource instance
      resource = klass.new(data)
      
      # Validate
      if resource.valid?
        { valid: true, resource: resource }
      else
        { 
          valid: false, 
          errors: format_errors(resource),
          operation_outcome: build_operation_outcome(resource)
        }
      end
    rescue => e
      {
        valid: false,
        errors: [e.message],
        operation_outcome: build_error_operation_outcome(e)
      }
    end
    
    # Validate and raise if invalid
    def self.validate_resource!(klass, data)
      result = validate_resource(klass, data)
      raise ValidationError, result[:errors].join(', ') unless result[:valid]
      result[:resource]
    end
    
    private
    
    def self.format_errors(resource)
      # Extract validation errors from FHIR resource
      errors = []
      
      # Check for missing required fields
      resource.class::METADATA.each do |field, meta|
        if meta['required'] && resource.send(field).nil?
          errors << "#{field} is required"
        end
      end
      
      # Add any other validation errors
      if resource.respond_to?(:errors) && resource.errors.any?
        errors += resource.errors.full_messages
      end
      
      errors
    end
    
    def self.build_operation_outcome(resource)
      {
        resourceType: 'OperationOutcome',
        issue: format_errors(resource).map { |error|
          {
            severity: 'error',
            code: 'invalid',
            diagnostics: error
          }
        }
      }
    end
    
    def self.build_error_operation_outcome(exception)
      {
        resourceType: 'OperationOutcome',
        issue: [{
          severity: 'error',
          code: 'exception',
          diagnostics: exception.message,
          details: {
            text: exception.class.name
          }
        }]
      }
    end
  end
end
