# FHIR Patient Resource Controller
# Implements FHIR R4 Patient CRUD operations

module Fhir
  class PatientsController < BaseController
    # GET /fhir/Patient
    def index
      resources = api_namespace.api_resources
      resources = apply_search_params(resources)
      resources = paginate(resources)
      
      bundle = Fhir::Serializer.to_bundle(
        resources,
        'Patient',
        request.original_url,
        total_count: resources.total_count
      )
      
      render_fhir(bundle)
    end
    
    # GET /fhir/Patient/:id
    def show
      resource = api_namespace.api_resources.find(params[:id])
      render_fhir(Fhir::Serializer.to_fhir(resource))
    end
    
    # POST /fhir/Patient
    def create
      # Validate FHIR resource
      validation = Fhir::Validator.validate_patient(patient_params)
      
      unless validation[:valid]
        return render json: validation[:operation_outcome], status: :unprocessable_entity
      end
      
      # Create API Resource
      resource = api_namespace.api_resources.create!(
        properties: patient_params.to_h
      )
      
      render_fhir(Fhir::Serializer.to_fhir(resource), status: :created)
    end
    
    # PUT /fhir/Patient/:id
    def update
      resource = api_namespace.api_resources.find(params[:id])
      
      # Validate FHIR resource
      validation = Fhir::Validator.validate_patient(patient_params)
      
      unless validation[:valid]
        return render json: validation[:operation_outcome], status: :unprocessable_entity
      end
      
      # Update API Resource
      resource.update!(properties: patient_params.to_h)
      
      render_fhir(Fhir::Serializer.to_fhir(resource))
    end
    
    # DELETE /fhir/Patient/:id
    def destroy
      resource = api_namespace.api_resources.find(params[:id])
      resource.destroy!
      
      head :no_content
    end
    
    private
    
    def namespace_slug
      'fhir-patient'
    end
    
    def patient_params
      params.require(:patient).permit!
    end
    
    def apply_resource_specific_search(scope)
      scope = apply_name_search(scope) if params[:name].present?
      scope = apply_birthdate_search(scope) if params[:birthdate].present?
      scope = apply_gender_search(scope) if params[:gender].present?
      scope = apply_identifier_search(scope) if params[:identifier].present?
      scope
    end
    
    def apply_name_search(scope)
      name = params[:name]
      # Search in JSONB properties
      scope.where("properties->>'name' ILIKE ?", "%#{name}%")
    end
    
    def apply_birthdate_search(scope)
      birthdate = parse_date(params[:birthdate])
      scope.where("properties->>'birthDate' = ?", birthdate.to_s)
    end
    
    def apply_gender_search(scope)
      scope.where("properties->>'gender' = ?", params[:gender])
    end
    
    def apply_identifier_search(scope)
      # Search in identifier array
      identifier = params[:identifier]
      scope.where("properties @> ?", { identifier: [{ value: identifier }] }.to_json)
    end
  end
end
