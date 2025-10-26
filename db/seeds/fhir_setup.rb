# FHIR Setup Seed
# Creates FHIR API Namespaces and sample data

puts "🏥 Setting up FHIR EHR Boilerplate..."

# Create FHIR API Namespaces
puts "\n📋 Creating FHIR API Namespaces..."
FhirNamespaces.create_all!

# Create sample admin user if needed
unless User.exists?(email: 'admin@example.com')
  puts "\n👤 Creating admin user..."
  User.create!(
    email: 'admin@example.com',
    password: 'password',
    password_confirmation: 'password',
    confirmed_at: Time.current
  )
  puts "✓ Admin user created: admin@example.com / password"
end

# Create sample FHIR data
puts "\n🏥 Creating sample FHIR data..."

# Sample Patients
patient_namespace = ApiNamespace.find_by(slug: 'fhir-patient')
observation_namespace = ApiNamespace.find_by(slug: 'fhir-observation')
device_namespace = ApiNamespace.find_by(slug: 'fhir-device')

if patient_namespace
  3.times do |i|
    patient = patient_namespace.api_resources.create!(
      properties: {
        resourceType: 'Patient',
        identifier: [{
          system: 'http://hospital.example.org',
          value: "MRN-#{1000 + i}"
        }],
        name: [{
          use: 'official',
          family: ['Smith', 'Johnson', 'Williams'][i],
          given: [['John', 'Jane', 'Bob'][i]]
        }],
        gender: ['male', 'female', 'other'][i],
        birthDate: (30.years.ago + i.years).to_date.to_s,
        address: [{
          use: 'home',
          line: ["#{123 + i} Main St"],
          city: 'Springfield',
          state: 'IL',
          postalCode: '62701',
          country: 'USA'
        }],
        telecom: [{
          system: 'phone',
          value: "(555) 555-#{1000 + i}",
          use: 'mobile'
        }, {
          system: 'email',
          value: "patient#{i+1}@example.com",
          use: 'home'
        }],
        active: true
      }
    )
    
    puts "✓ Created patient: #{patient.properties['name'].first['given'].first} #{patient.properties['name'].first['family']}"
    
    # Create sample observations for this patient
    if observation_namespace && device_namespace
      # Create a sample device
      device = device_namespace.api_resources.first_or_create!(
        properties: {
          resourceType: 'Device',
          identifier: [{
            system: 'http://example.org/devices',
            value: 'DEVICE-001'
          }],
          status: 'active',
          manufacturer: 'Acme Medical Devices',
          deviceName: [{
            name: 'Acme Vital Signs Monitor',
            type: 'user-friendly-name'
          }],
          modelNumber: 'VSM-2000',
          type: {
            coding: [{
              system: 'http://snomed.info/sct',
              code: '258057004',
              display: 'Vital signs monitor'
            }]
          }
        }
      )
      
      # Create vital sign observations
      ['8867-4', '8480-6', '8462-4', '8310-5'].each_with_index do |loinc_code, idx|
        display_names = ['Heart rate', 'Systolic blood pressure', 'Diastolic blood pressure', 'Body temperature']
        units = ['bpm', 'mmHg', 'mmHg', 'Cel']
        values = [72 + idx, 120, 80, 36.5 + (idx * 0.1)]
        
        observation_namespace.api_resources.create!(
          properties: {
            resourceType: 'Observation',
            status: 'final',
            category: [{
              coding: [{
                system: 'http://terminology.hl7.org/CodeSystem/observation-category',
                code: 'vital-signs',
                display: 'Vital Signs'
              }]
            }],
            code: {
              coding: [{
                system: 'http://loinc.org',
                code: loinc_code,
                display: display_names[idx]
              }]
            },
            subject: {
              reference: "Patient/#{patient.id}"
            },
            effectiveDateTime: (Time.current - idx.hours).iso8601,
            issued: Time.current.iso8601,
            valueQuantity: {
              value: values[idx],
              unit: units[idx],
              system: 'http://unitsofmeasure.org',
              code: units[idx]
            },
            device: {
              reference: "Device/#{device.id}"
            }
          }
        )
      end
      
      puts "  ✓ Created #{4} observations for patient"
    end
  end
end

puts "\n✅ FHIR EHR setup complete!"
puts "\n📖 Next steps:"
puts "  1. Start the server: ./bin/dev"
puts "  2. Access FHIR API: http://localhost:3000/fhir/metadata"
puts "  3. Admin dashboard: http://localhost:3000/admin"
puts "  4. Login: admin@example.com / password"
puts "\n🔗 FHIR Endpoints:"
puts "  GET  /fhir/Patient"
puts "  GET  /fhir/Patient/:id"
puts "  POST /fhir/Patient"
puts "  GET  /fhir/Observation"
puts "  GET  /fhir/Observation?subject=Patient/:id"
