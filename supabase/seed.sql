-- Gene - Nov, 03, 2026: Seed data for Universal Booking Platform (Dental, Medical, and Stays)

-- 1. Sample Admin Profile
INSERT INTO public.profiles (id, email, full_name, role, phone)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'admin@bookit.dev', 'Dr. Alexander Vance', 'business_owner', '+1 (555) 234-5678'),
    ('00000000-0000-0000-0000-000000000002', 'retreat@bookit.dev', 'Elena Rostova', 'business_owner', '+1 (555) 987-6543'),
    ('00000000-0000-0000-0000-000000000003', 'client@bookit.dev', 'Michael Chen', 'client', '+1 (555) 345-6789')
ON CONFLICT (id) DO NOTHING;

-- 2. Sample Businesses
/*
-- Gene - Nov, 03, 2026: Original sample businesses without template_id and ui_config
INSERT INTO public.businesses (id, owner_id, name, slug, category, booking_model, description, address, city, latitude, longitude, contact_phone, contact_email, rating_avg, rating_count, banner_url, settings)
VALUES 
    (
        '11111111-1111-1111-1111-111111111111',
        '00000000-0000-0000-0000-000000000001',
        'Apex Dental & Orthodontic Care',
        'apex-dental-orthodontic',
        'dental',
        'slot_based',
        'Leading dental healthcare clinic providing gentle cosmetic dentistry, precision orthodontics, and restorative oral care in a state-of-the-art facility.',
        '742 Evergreen Medical Suites, Suite 300',
        'San Francisco',
        37.7749,
        -122.4194,
        '+1 (555) 456-7890',
        'contact@apexdental.com',
        4.92,
        48,
        'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=1200&q=80',
        '{
            "slot_interval_minutes": 30,
            "buffer_minutes": 10,
            "requires_approval": false,
            "working_hours": {
                "monday": {"open": "09:00", "close": "18:00", "is_open": true},
                "tuesday": {"open": "09:00", "close": "18:00", "is_open": true},
                "wednesday": {"open": "09:00", "close": "18:00", "is_open": true},
                "thursday": {"open": "09:00", "close": "18:00", "is_open": true},
                "friday": {"open": "09:00", "close": "17:00", "is_open": true},
                "saturday": {"open": "10:00", "close": "15:00", "is_open": true},
                "sunday": {"open": "00:00", "close": "00:00", "is_open": false}
            }
        }'::jsonb
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        '00000000-0000-0000-0000-000000000002',
        'Serenity Post-Op Recovery & Wellness Suites',
        'serenity-wellness-suites',
        'recovery_stay',
        'date_range',
        'Luxury post-operative recovery retreat offering 24/7 nursing supervision, personalized rehabilitation therapy, and nutritious dietary plans.',
        '1200 Coastal Bay Road',
        'Monterey',
        36.6002,
        -121.8947,
        '+1 (555) 321-9876',
        'reservations@serenitystay.com',
        4.85,
        24,
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80',
        '{
            "checkin_time": "14:00",
            "checkout_time": "11:00",
            "min_days": 2,
            "max_days": 30,
            "requires_approval": true
        }'::jsonb
    ),
    (
        '33333333-3333-3333-3333-333333333333',
        '00000000-0000-0000-0000-000000000001',
        'Lumina Aesthetic & Dermatology Center',
        'lumina-dermatology',
        'medical',
        'slot_based',
        'Board-certified dermatologists specializing in medical skin health, clinical laser therapy, and advanced anti-aging procedures.',
        '88 Sutter St, Floor 4',
        'San Francisco',
        37.7891,
        -122.4014,
        '+1 (555) 789-0123',
        'hello@luminaderm.com',
        4.78,
        36,
        'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=1200&q=80',
        '{
            "slot_interval_minutes": 45,
            "buffer_minutes": 15,
            "requires_approval": false,
            "working_hours": {
                "monday": {"open": "08:30", "close": "17:30", "is_open": true},
                "tuesday": {"open": "08:30", "close": "17:30", "is_open": true},
                "wednesday": {"open": "08:30", "close": "17:30", "is_open": true},
                "thursday": {"open": "08:30", "close": "17:30", "is_open": true},
                "friday": {"open": "08:30", "close": "16:00", "is_open": true},
                "saturday": {"open": "00:00", "close": "00:00", "is_open": false},
                "sunday": {"open": "00:00", "close": "00:00", "is_open": false}
            }
        }'::jsonb
    )
ON CONFLICT (id) DO NOTHING;
*/

-- Gene - Nov, 04, 2026: Seed businesses linked with template_id and dynamic ui_config snapshots
INSERT INTO public.businesses (
    id, owner_id, template_id, name, slug, category, booking_model,
    description, address, city, latitude, longitude,
    contact_phone, contact_email, rating_avg, rating_count, banner_url,
    settings, ui_config
)
VALUES 
    (
        '11111111-1111-1111-1111-111111111111',
        '00000000-0000-0000-0000-000000000001',
        't0000001-0000-0000-0000-000000000001',
        'Apex Dental & Orthodontic Care',
        'apex-dental-orthodontic',
        'dental',
        'slot_based',
        'Leading dental healthcare clinic providing gentle cosmetic dentistry, precision orthodontics, and restorative oral care in a state-of-the-art facility.',
        '742 Evergreen Medical Suites, Suite 300',
        'San Francisco',
        37.7749,
        -122.4194,
        '+1 (555) 456-7890',
        'contact@apexdental.com',
        4.92,
        48,
        'https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=1200&q=80',
        '{
            "slot_interval_minutes": 30,
            "buffer_minutes": 10,
            "requires_approval": false,
            "working_hours": {
                "monday": {"open": "09:00", "close": "18:00", "is_open": true},
                "tuesday": {"open": "09:00", "close": "18:00", "is_open": true},
                "wednesday": {"open": "09:00", "close": "18:00", "is_open": true},
                "thursday": {"open": "09:00", "close": "18:00", "is_open": true},
                "friday": {"open": "09:00", "close": "17:00", "is_open": true},
                "saturday": {"open": "10:00", "close": "15:00", "is_open": true},
                "sunday": {"open": "00:00", "close": "00:00", "is_open": false}
            }
        }'::jsonb,
        '{
            "resource_type": "person",
            "resource_label": "Dentist / Specialist",
            "service_label": "Dental Treatment",
            "show_staff_selection": true,
            "intake_fields": [
                {"id": "dental_insurance", "label": "Do you have dental insurance?", "type": "boolean", "required": false},
                {"id": "insurance_carrier", "label": "Insurance Provider / Member ID", "type": "text", "placeholder": "e.g. Delta Dental / Cigna", "required": false},
                {"id": "anesthesia_allergies", "label": "Allergies to local anesthesia, latex, or antibiotics?", "type": "text", "placeholder": "None or specify", "required": false},
                {"id": "chief_complaint", "label": "Primary reason for visit / symptoms", "type": "textarea", "placeholder": "Checkup, tooth sensitivity, toothache...", "required": true}
            ]
        }'::jsonb
    ),
    (
        '22222222-2222-2222-2222-222222222222',
        '00000000-0000-0000-0000-000000000002',
        't0000001-0000-0000-0000-000000000003',
        'Serenity Post-Op Recovery & Wellness Suites',
        'serenity-wellness-suites',
        'recovery_stay',
        'date_range',
        'Luxury post-operative recovery retreat offering 24/7 nursing supervision, personalized rehabilitation therapy, and nutritious dietary plans.',
        '1200 Coastal Bay Road',
        'Monterey',
        36.6002,
        -121.8947,
        '+1 (555) 321-9876',
        'reservations@serenitystay.com',
        4.85,
        24,
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=1200&q=80',
        '{
            "checkin_time": "14:00",
            "checkout_time": "11:00",
            "min_days": 2,
            "max_days": 30,
            "requires_approval": true
        }'::jsonb,
        '{
            "resource_type": "facility",
            "resource_label": "Care Suite / Room",
            "service_label": "Recovery Tier",
            "show_staff_selection": false,
            "intake_fields": [
                {"id": "surgery_type", "label": "Surgical procedure type & hospital", "type": "text", "placeholder": "e.g. Orthopedic knee replacement at UCSF", "required": true},
                {"id": "surgery_date", "label": "Surgery discharge date", "type": "text", "placeholder": "MM/DD/YYYY", "required": true},
                {"id": "mobility_level", "label": "Assistance needed (Wheelchair, Walker, Bedbound)", "type": "text", "placeholder": "Describe mobility needs", "required": true},
                {"id": "dietary_restrictions", "label": "Nutritional restrictions / allergies", "type": "text", "placeholder": "e.g. Low sodium, Diabetic, Gluten-free", "required": false}
            ]
        }'::jsonb
    ),
    (
        '33333333-3333-3333-3333-333333333333',
        '00000000-0000-0000-0000-000000000001',
        't0000001-0000-0000-0000-000000000002',
        'Lumina Aesthetic & Dermatology Center',
        'lumina-dermatology',
        'medical',
        'slot_based',
        'Board-certified dermatologists specializing in medical skin health, clinical laser therapy, and advanced anti-aging procedures.',
        '88 Sutter St, Floor 4',
        'San Francisco',
        37.7891,
        -122.4014,
        '+1 (555) 789-0123',
        'hello@luminaderm.com',
        4.78,
        36,
        'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=1200&q=80',
        '{
            "slot_interval_minutes": 45,
            "buffer_minutes": 15,
            "requires_approval": false,
            "working_hours": {
                "monday": {"open": "08:30", "close": "17:30", "is_open": true},
                "tuesday": {"open": "08:30", "close": "17:30", "is_open": true},
                "wednesday": {"open": "08:30", "close": "17:30", "is_open": true},
                "thursday": {"open": "08:30", "close": "17:30", "is_open": true},
                "friday": {"open": "08:30", "close": "16:00", "is_open": true},
                "saturday": {"open": "00:00", "close": "00:00", "is_open": false},
                "sunday": {"open": "00:00", "close": "00:00", "is_open": false}
            }
        }'::jsonb,
        '{
            "resource_type": "person",
            "resource_label": "Physician / Doctor",
            "service_label": "Consultation / Procedure",
            "show_staff_selection": true,
            "intake_fields": [
                {"id": "medical_history", "label": "Relevant past medical conditions or surgeries", "type": "textarea", "placeholder": "None or list conditions", "required": false},
                {"id": "current_medications", "label": "Current daily medications / dosages", "type": "text", "placeholder": "e.g. Lisinopril 10mg", "required": false},
                {"id": "referral_doctor", "label": "Referring Doctor (if applicable)", "type": "text", "placeholder": "Doctor name or clinic", "required": false}
            ]
        }'::jsonb
    )
ON CONFLICT (id) DO NOTHING;

-- 3. Staff / Doctors for Apex Dental
INSERT INTO public.business_staff (id, business_id, name, specialty, bio, avatar_url)
VALUES 
    (
        '44444444-4444-4444-4444-444444444441',
        '11111111-1111-1111-1111-111111111111',
        'Dr. Alexander Vance, DDS',
        'Orthodontics & Smile Design',
        'Over 14 years specializing in clear aligners, Invisalign, and pediatric orthodontic care.',
        'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=400&q=80'
    ),
    (
        '44444444-4444-4444-4444-444444444442',
        '11111111-1111-1111-1111-111111111111',
        'Dr. Sophia Martinez, DMD',
        'Periodontics & Implants',
        'Harvard Dental alumnus with expertise in micro-surgical implantology and restorative therapy.',
        'https://images.unsplash.com/photo-1594824813637-b9560f1ad922?auto=format&fit=crop&w=400&q=80'
    ),
    (
        '44444444-4444-4444-4444-444444444443',
        '11111111-1111-1111-1111-111111111111',
        'Sarah Lin, RDH',
        'Lead Dental Hygienist',
        'Gentle preventative dental cleaning, scaling, and deep root planing specialist.',
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=400&q=80'
    )
ON CONFLICT (id) DO NOTHING;

-- 4. Services for Apex Dental
INSERT INTO public.services (id, business_id, name, description, duration_minutes, price, currency)
VALUES 
    (
        '55555555-5555-5555-5555-555555555551',
        '11111111-1111-1111-1111-111111111111',
        'Comprehensive Dental Exam & Cleaning',
        'Full digital panoramic X-ray, gum health evaluation, gentle scaling, and high-shine polish.',
        45,
        120.00,
        'USD'
    ),
    (
        '55555555-5555-5555-5555-555555555552',
        '11111111-1111-1111-1111-111111111111',
        'Laser Teeth Whitening (Zoom!)',
        'In-office accelerated teeth whitening achieving up to 8 shades brighter in a single 60-minute session.',
        60,
        350.00,
        'USD'
    ),
    (
        '55555555-5555-5555-5555-555555555553',
        '11111111-1111-1111-1111-111111111111',
        'Orthodontic & Invisalign Consultation',
        '3D intraoral iTero scan, digital bite simulation, and custom orthodontic treatment plan.',
        30,
        75.00,
        'USD'
    ),
    (
        '55555555-5555-5555-5555-555555555554',
        '11111111-1111-1111-1111-111111111111',
        'Root Canal Therapy & Restoration',
        'Painless endodontic treatment utilizing rotary files and biological sealing.',
        90,
        550.00,
        'USD'
    )
ON CONFLICT (id) DO NOTHING;

-- 5. Services for Serenity Wellness (Date-Range Model)
INSERT INTO public.services (id, business_id, name, description, duration_minutes, price, currency)
VALUES 
    (
        '66666666-6666-6666-6666-666666666661',
        '22222222-2222-2222-2222-222222222222',
        'Private Recovery Suite (Per Night)',
        'Private terrace suite, continuous post-op nursing care, meals prepared by in-house nutritionist, and hyperbaric recovery session access.',
        1440,
        450.00,
        'USD'
    )
ON CONFLICT (id) DO NOTHING;
