# Whoop Integration External API Client
# Syncs Whoop wearable data to FHIR Observations
# 
# To use: Create an External API Client in Violet Rails admin with this model definition

class WhoopSync
  WHOOP_API_BASE = 'https://api.whoop.com/v1'
  
  # LOINC codes for common metrics
  LOINC_HEART_RATE = '8867-4'
  LOINC_HRV = '80404-7'
  LOINC_RESPIRATORY_RATE = '9279-1'
  
  def initialize(parameters)
    @external_api_client = parameters[:external_api_client]
    @metadata = @external_api_client.get_metadata
    
    # Get API Namespaces
    @patient_namespace = ApiNamespace.find_by(slug: 'fhir-patient')
    @observation_namespace = ApiNamespace.find_by(slug: 'fhir-observation')
    @device_namespace = ApiNamespace.find_by(slug: 'fhir-device')
    
    # OAuth tokens stored in metadata
    @access_token = @metadata[:access_token]
    @refresh_token = @metadata[:refresh_token]
    @patient_id = @metadata[:patient_id] # FHIR Patient ID to link observations
  end
  
  def start
    # Refresh token if needed
    refresh_access_token_if_needed
    
    # Sync different data types
    sync_recovery_data
    sync_sleep_data
    sync_workout_data
    sync_cycle_data
    
    log_success
  rescue => e
    log_error(e)
    raise
  end
  
  def log
    Rails.logger.info "[WhoopSync] Sync completed for patient #{@patient_id}"
    true
  end
  
  private
  
  def sync_recovery_data
    # Get recovery data from last 7 days
    start_date = 7.days.ago.to_date
    end_date = Date.today
    
    response = whoop_api_get("/recovery", {
      start: start_date.iso8601,
      end: end_date.iso8601
    })
    
    return unless response['records']
    
    response['records'].each do |recovery|
      create_recovery_observations(recovery)
    end
  end
  
  def create_recovery_observations(recovery)
    timestamp = recovery['created_at']
    score = recovery['score']
    
    # Recovery Score (custom code)
    create_observation(
      code: { system: 'http://whoop.com/fhir/CodeSystem', code: 'recovery-score' },
      value: score['recovery_score'],
      unit: 'score',
      effective_datetime: timestamp,
      category: 'vital-signs'
    )
    
    # HRV (LOINC)
    if score['hrv_rmssd_milli']
      create_observation(
        code: { system: 'http://loinc.org', code: LOINC_HRV },
        value: score['hrv_rmssd_milli'],
        unit: 'ms',
        effective_datetime: timestamp,
        category: 'vital-signs'
      )
    end
    
    # Resting Heart Rate (LOINC)
    if score['resting_heart_rate']
      create_observation(
        code: { system: 'http://loinc.org', code: LOINC_HEART_RATE },
        value: score['resting_heart_rate'],
        unit: 'bpm',
        effective_datetime: timestamp,
        category: 'vital-signs'
      )
    end
    
    # Respiratory Rate (LOINC)
    if score['spo2_percentage']
      create_observation(
        code: { system: 'http://loinc.org', code: LOINC_RESPIRATORY_RATE },
        value: score['respiratory_rate'],
        unit: '/min',
        effective_datetime: timestamp,
        category: 'vital-signs'
      )
    end
  end
  
  def sync_sleep_data
    start_date = 7.days.ago.to_date
    end_date = Date.today
    
    response = whoop_api_get("/sleep", {
      start: start_date.iso8601,
      end: end_date.iso8601
    })
    
    return unless response['records']
    
    response['records'].each do |sleep|
      create_sleep_observations(sleep)
    end
  end
  
  def create_sleep_observations(sleep)
    timestamp = sleep['end']
    
    # Total sleep duration
    create_observation(
      code: { system: 'http://whoop.com/fhir/CodeSystem', code: 'sleep-duration' },
      value: sleep['score']['total_in_bed_time_milli'] / 1000.0 / 60.0, # Convert to minutes
      unit: 'min',
      effective_datetime: timestamp,
      category: 'activity'
    )
    
    # Sleep quality score
    if sleep['score']['sleep_performance_percentage']
      create_observation(
        code: { system: 'http://whoop.com/fhir/CodeSystem', code: 'sleep-quality' },
        value: sleep['score']['sleep_performance_percentage'],
        unit: '%',
        effective_datetime: timestamp,
        category: 'activity'
      )
    end
  end
  
  def sync_workout_data
    start_date = 7.days.ago.to_date
    end_date = Date.today
    
    response = whoop_api_get("/workout", {
      start: start_date.iso8601,
      end: end_date.iso8601
    })
    
    return unless response['records']
    
    response['records'].each do |workout|
      create_workout_observations(workout)
    end
  end
  
  def create_workout_observations(workout)
    timestamp = workout['end']
    
    # Strain score
    create_observation(
      code: { system: 'http://whoop.com/fhir/CodeSystem', code: 'strain-score' },
      value: workout['score']['strain'],
      unit: 'score',
      effective_datetime: timestamp,
      category: 'activity'
    )
    
    # Average heart rate during workout
    if workout['score']['average_heart_rate']
      create_observation(
        code: { system: 'http://loinc.org', code: LOINC_HEART_RATE },
        value: workout['score']['average_heart_rate'],
        unit: 'bpm',
        effective_datetime: timestamp,
        category: 'vital-signs'
      )
    end
  end
  
  def sync_cycle_data
    start_date = 7.days.ago.to_date
    end_date = Date.today
    
    response = whoop_api_get("/cycle", {
      start: start_date.iso8601,
      end: end_date.iso8601
    })
    
    return unless response['records']
    
    response['records'].each do |cycle|
      create_cycle_observations(cycle)
    end
  end
  
  def create_cycle_observations(cycle)
    timestamp = cycle['end']
    
    # Day strain
    if cycle['score']['strain']
      create_observation(
        code: { system: 'http://whoop.com/fhir/CodeSystem', code: 'day-strain' },
        value: cycle['score']['strain'],
        unit: 'score',
        effective_datetime: timestamp,
        category: 'activity'
      )
    end
  end
  
  def create_observation(code:, value:, unit:, effective_datetime:, category:)
    # Check if observation already exists (idempotency)
    existing = @observation_namespace.api_resources.where(
      "properties->>'effectiveDateTime' = ? AND properties->'code'->>'code' = ?",
      effective_datetime,
      code[:code]
    ).first
    
    return if existing
    
    # Get or create Whoop device
    device = get_or_create_whoop_device
    
    # Create FHIR Observation
    observation_data = {
      resourceType: 'Observation',
      status: 'final',
      category: [{
        coding: [{
          system: 'http://terminology.hl7.org/CodeSystem/observation-category',
          code: category
        }]
      }],
      code: {
        coding: [code]
      },
      subject: {
        reference: "Patient/#{@patient_id}"
      },
      effectiveDateTime: effective_datetime,
      issued: Time.current.iso8601,
      valueQuantity: {
        value: value,
        unit: unit
      },
      device: {
        reference: "Device/#{device.id}"
      }
    }
    
    @observation_namespace.api_resources.create!(
      properties: observation_data
    )
  end
  
  def get_or_create_whoop_device
    # Find existing Whoop device or create one
    device = @device_namespace.api_resources.where(
      "properties->>'manufacturer' = ?", 'WHOOP, Inc.'
    ).first
    
    return device if device
    
    # Create Whoop device
    device_data = {
      resourceType: 'Device',
      identifier: [{
        system: 'http://whoop.com/devices',
        value: 'whoop-4.0'
      }],
      status: 'active',
      manufacturer: 'WHOOP, Inc.',
      deviceName: [{
        name: 'WHOOP 4.0',
        type: 'user-friendly-name'
      }],
      modelNumber: '4.0',
      type: {
        coding: [{
          system: 'http://snomed.info/sct',
          code: '706767009',
          display: 'Wearable fitness tracker'
        }]
      }
    }
    
    @device_namespace.api_resources.create!(
      properties: device_data
    )
  end
  
  def whoop_api_get(path, params = {})
    response = HTTParty.get(
      "#{WHOOP_API_BASE}#{path}",
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type' => 'application/json'
      },
      query: params
    )
    
    if response.code == 401
      # Token expired, refresh and retry
      refresh_access_token
      return whoop_api_get(path, params)
    end
    
    raise "Whoop API error: #{response.code} - #{response.body}" unless response.success?
    
    JSON.parse(response.body)
  end
  
  def refresh_access_token_if_needed
    # Check if token is about to expire (stored in metadata)
    expires_at = @metadata[:token_expires_at]
    return unless expires_at.nil? || Time.parse(expires_at) < 1.hour.from_now
    
    refresh_access_token
  end
  
  def refresh_access_token
    response = HTTParty.post(
      "#{WHOOP_API_BASE}/oauth/token",
      body: {
        grant_type: 'refresh_token',
        refresh_token: @refresh_token,
        client_id: ENV['WHOOP_CLIENT_ID'],
        client_secret: ENV['WHOOP_CLIENT_SECRET']
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    
    raise "Token refresh failed: #{response.body}" unless response.success?
    
    data = JSON.parse(response.body)
    
    # Update metadata with new tokens
    @access_token = data['access_token']
    @refresh_token = data['refresh_token'] if data['refresh_token']
    
    @external_api_client.set_metadata(
      @metadata.merge(
        access_token: @access_token,
        refresh_token: @refresh_token,
        token_expires_at: (Time.current + data['expires_in'].seconds).iso8601
      )
    )
  end
  
  def log_success
    @external_api_client.update(
      status: ExternalApiClient::STATUSES[:success],
      error_message: nil
    )
  end
  
  def log_error(error)
    @external_api_client.update(
      status: ExternalApiClient::STATUSES[:failed],
      error_message: error.message,
      error_metadata: {
        backtrace: error.backtrace.first(10)
      }
    )
  end
end

# Return the class (required by Violet Rails)
WhoopSync
