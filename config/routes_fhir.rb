# FHIR R4 API Routes
# Add these to config/routes.rb

Rails.application.routes.draw do
  # FHIR R4 API
  namespace :fhir, defaults: { format: :json } do
    # Metadata endpoint (CapabilityStatement)
    get 'metadata', to: 'metadata#show'
    get '', to: 'metadata#show' # Root also returns metadata
    
    # Patient Resource
    resources :patients, only: [:index, :show, :create, :update, :destroy] do
      collection do
        get 'search', to: 'patients#index' # FHIR search
      end
    end
    
    # Observation Resource
    resources :observations, only: [:index, :show, :create, :update, :destroy]
    
    # Practitioner Resource
    resources :practitioners, only: [:index, :show, :create, :update, :destroy]
    
    # Organization Resource
    resources :organizations, only: [:index, :show, :create, :update, :destroy]
    
    # Encounter Resource
    resources :encounters, only: [:index, :show, :create, :update, :destroy]
    
    # Device Resource
    resources :devices, only: [:index, :show, :create, :update, :destroy]
    
    # Condition Resource
    resources :conditions, only: [:index, :show, :create, :update, :destroy]
    
    # CarePlan Resource
    resources :care_plans, only: [:index, :show, :create, :update, :destroy]
  end
end
