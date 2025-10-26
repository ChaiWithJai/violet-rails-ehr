# FHIR Resource Serialization Service
# Converts between Violet Rails API Resources and FHIR JSON

module Fhir
  class Serializer
    # Convert API Resource to FHIR JSON
    def self.to_fhir(api_resource)
      {
        resourceType: api_resource.properties['resourceType'],
        id: api_resource.id.to_s,
        meta: {
          versionId: api_resource.updated_at.to_i.to_s,
          lastUpdated: api_resource.updated_at.iso8601
        }
      }.merge(api_resource.properties.except('resourceType'))
    end
    
    # Convert collection to FHIR Bundle
    def self.to_bundle(api_resources, resource_type, request_url, total_count: nil)
      {
        resourceType: 'Bundle',
        type: 'searchset',
        total: total_count || api_resources.size,
        link: build_bundle_links(request_url),
        entry: api_resources.map { |resource|
          {
            fullUrl: "#{base_url}/fhir/#{resource_type}/#{resource.id}",
            resource: to_fhir(resource),
            search: {
              mode: 'match'
            }
          }
        }
      }
    end
    
    # Build FHIR OperationOutcome for errors
    def self.operation_outcome(errors, severity: 'error', code: 'invalid')
      errors = [errors] unless errors.is_a?(Array)
      
      {
        resourceType: 'OperationOutcome',
        issue: errors.map { |error|
          {
            severity: severity,
            code: code,
            diagnostics: error.to_s
          }
        }
      }
    end
    
    # Build FHIR OperationOutcome for not found
    def self.not_found_outcome(resource_type, id)
      {
        resourceType: 'OperationOutcome',
        issue: [{
          severity: 'error',
          code: 'not-found',
          diagnostics: "#{resource_type} with id #{id} not found"
        }]
      }
    end
    
    # Build FHIR CapabilityStatement
    def self.capability_statement
      {
        resourceType: 'CapabilityStatement',
        status: 'active',
        date: Time.current.iso8601,
        kind: 'instance',
        software: {
          name: 'Violet Rails EHR',
          version: '1.0.0'
        },
        implementation: {
          description: 'Violet Rails + FSF Health EHR Boilerplate',
          url: base_url
        },
        fhirVersion: '4.0.1',
        format: ['json'],
        rest: [{
          mode: 'server',
          resource: supported_resources
        }]
      }
    end
    
    private
    
    def self.base_url
      # Get from Rails config or environment
      ENV['FHIR_BASE_URL'] || 'http://localhost:3000'
    end
    
    def self.build_bundle_links(request_url)
      [
        {
          relation: 'self',
          url: request_url
        }
      ]
    end
    
    def self.supported_resources
      [
        build_resource_capability('Patient'),
        build_resource_capability('Observation'),
        build_resource_capability('Practitioner'),
        build_resource_capability('Organization'),
        build_resource_capability('Encounter'),
        build_resource_capability('Device'),
        build_resource_capability('Condition'),
        build_resource_capability('CarePlan')
      ]
    end
    
    def self.build_resource_capability(resource_type)
      {
        type: resource_type,
        interaction: [
          { code: 'read' },
          { code: 'create' },
          { code: 'update' },
          { code: 'delete' },
          { code: 'search-type' }
        ],
        searchParam: common_search_params(resource_type)
      }
    end
    
    def self.common_search_params(resource_type)
      params = [
        { name: '_id', type: 'token', documentation: 'Logical id of the resource' },
        { name: '_lastUpdated', type: 'date', documentation: 'Last updated date' }
      ]
      
      # Add resource-specific search params
      case resource_type
      when 'Patient'
        params += [
          { name: 'name', type: 'string', documentation: 'Patient name' },
          { name: 'birthdate', type: 'date', documentation: 'Birth date' },
          { name: 'gender', type: 'token', documentation: 'Gender' },
          { name: 'identifier', type: 'token', documentation: 'Patient identifier' }
        ]
      when 'Observation'
        params += [
          { name: 'subject', type: 'reference', documentation: 'Patient reference' },
          { name: 'code', type: 'token', documentation: 'Observation code' },
          { name: 'date', type: 'date', documentation: 'Observation date' },
          { name: 'category', type: 'token', documentation: 'Observation category' }
        ]
      end
      
      params
    end
  end
end
