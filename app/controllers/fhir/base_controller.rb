# Base controller for FHIR API endpoints
# Handles common FHIR operations, authentication, and error handling

module Fhir
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_api_request
    before_action :set_fhir_headers
    
    rescue_from ActiveRecord::RecordNotFound, with: :resource_not_found
    rescue_from ActionController::ParameterMissing, with: :bad_request
    rescue_from Fhir::Validator::ValidationError, with: :validation_error
    
    protected
    
    def authenticate_api_request
      # Use Violet Rails' existing API authentication
      # Or implement custom FHIR authentication
      # For now, allow unauthenticated access (add auth in production)
      true
    end
    
    def set_fhir_headers
      response.headers['Content-Type'] = 'application/fhir+json; charset=utf-8'
    end
    
    def render_fhir(data, status: :ok)
      render json: data, status: status
    end
    
    def render_operation_outcome(errors, status: :unprocessable_entity)
      render json: Fhir::Serializer.operation_outcome(errors), status: status
    end
    
    def resource_not_found(exception)
      resource_type = controller_name.classify
      id = params[:id]
      render json: Fhir::Serializer.not_found_outcome(resource_type, id), status: :not_found
    end
    
    def bad_request(exception)
      render_operation_outcome([exception.message], status: :bad_request)
    end
    
    def validation_error(exception)
      render_operation_outcome([exception.message], status: :unprocessable_entity)
    end
    
    # Get the API Namespace for this resource type
    def api_namespace
      @api_namespace ||= ApiNamespace.find_by!(slug: namespace_slug)
    end
    
    def namespace_slug
      # Override in subclasses
      raise NotImplementedError
    end
    
    # Apply FHIR search parameters
    def apply_search_params(scope)
      scope = apply_id_search(scope) if params[:_id].present?
      scope = apply_last_updated_search(scope) if params[:_lastUpdated].present?
      scope = apply_resource_specific_search(scope)
      scope
    end
    
    def apply_id_search(scope)
      ids = params[:_id].split(',')
      scope.where(id: ids)
    end
    
    def apply_last_updated_search(scope)
      # Parse date parameter (can be >, <, >=, <=, or exact)
      date_param = params[:_lastUpdated]
      
      if date_param.start_with?('ge')
        scope.where('updated_at >= ?', parse_date(date_param[2..-1]))
      elsif date_param.start_with?('le')
        scope.where('updated_at <= ?', parse_date(date_param[2..-1]))
      elsif date_param.start_with?('gt')
        scope.where('updated_at > ?', parse_date(date_param[2..-1]))
      elsif date_param.start_with?('lt')
        scope.where('updated_at < ?', parse_date(date_param[2..-1]))
      else
        date = parse_date(date_param)
        scope.where(updated_at: date.beginning_of_day..date.end_of_day)
      end
    end
    
    def apply_resource_specific_search(scope)
      # Override in subclasses for resource-specific search
      scope
    end
    
    def parse_date(date_string)
      Date.parse(date_string)
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid date format: #{date_string}"
    end
    
    # Pagination
    def paginate(scope)
      page = params[:page]&.to_i || 1
      per_page = params[:_count]&.to_i || 20
      per_page = [per_page, 100].min # Max 100 per page
      
      scope.page(page).per(per_page)
    end
  end
end
