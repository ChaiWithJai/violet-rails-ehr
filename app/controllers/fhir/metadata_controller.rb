# FHIR Metadata Controller
# Returns CapabilityStatement describing server capabilities

module Fhir
  class MetadataController < BaseController
    skip_before_action :authenticate_api_request
    
    # GET /fhir/metadata
    # GET /fhir
    def show
      render_fhir(Fhir::Serializer.capability_statement)
    end
    
    private
    
    def namespace_slug
      nil # Not needed for metadata endpoint
    end
  end
end
