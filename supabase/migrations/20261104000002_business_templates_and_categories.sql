-- Gene - Nov, 04, 2026: Business categories and templates for automated setup and dynamic booking UI
-- Implements two-tier normalized schema: business_categories -> business_templates -> businesses (snapshot)

-- 1. Create Business Categories Table
CREATE TABLE IF NOT EXISTS public.business_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    icon TEXT NOT NULL DEFAULT 'category',
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Create Business Templates Table
CREATE TABLE IF NOT EXISTS public.business_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES public.business_categories(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    description TEXT,
    icon TEXT NOT NULL DEFAULT 'business',
    booking_model TEXT NOT NULL CHECK (booking_model IN ('slot_based', 'date_range', 'daily')),
    default_settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    ui_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    starter_services JSONB NOT NULL DEFAULT '[]'::jsonb,
    starter_staff_roles JSONB NOT NULL DEFAULT '[]'::jsonb,
    display_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Extend Businesses Table
ALTER TABLE public.businesses
ADD COLUMN IF NOT EXISTS template_id UUID REFERENCES public.business_templates(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS ui_config JSONB NOT NULL DEFAULT '{
    "resource_type": "person",
    "resource_label": "Specialist",
    "service_label": "Service",
    "show_staff_selection": true,
    "intake_fields": []
}'::jsonb;

-- 4. Enable RLS on Categories and Templates
ALTER TABLE public.business_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_templates ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies: Everyone can read active categories and templates
CREATE POLICY "Public read access for active categories"
ON public.business_categories FOR SELECT
USING (is_active = true);

CREATE POLICY "Public read access for active templates"
ON public.business_templates FOR SELECT
USING (is_active = true);

-- Allow admins/owners full management
CREATE POLICY "Admins full access to categories"
ON public.business_categories FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
);

CREATE POLICY "Admins full access to templates"
ON public.business_templates FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
    )
);

-- 6. Indexes
CREATE INDEX IF NOT EXISTS idx_business_templates_category ON public.business_templates(category_id);
CREATE INDEX IF NOT EXISTS idx_business_templates_slug ON public.business_templates(slug);
CREATE INDEX IF NOT EXISTS idx_businesses_template ON public.businesses(template_id);

-- 7. Seed Data: 6 Sweet Spot Categories
INSERT INTO public.business_categories (id, name, slug, description, icon, display_order)
VALUES 
    (
        'c0000001-0000-0000-0000-000000000001',
        'Healthcare & Clinics',
        'healthcare-clinics',
        'Dental practices, medical specialists, physical therapy, and clinical care.',
        'medical_services_rounded',
        1
    ),
    (
        'c0000002-0000-0000-0000-000000000002',
        'Wellness & Therapy',
        'wellness-therapy',
        'Mental health counseling, specialized post-op recovery retreats, and nutrition.',
        'spa_rounded',
        2
    ),
    (
        'c0000003-0000-0000-0000-000000000003',
        'Beauty & Personal Care',
        'beauty-personal-care',
        'Hair salons, barbershops, esthetics, medical spas, and nail care.',
        'content_cut_rounded',
        3
    ),
    (
        'c0000004-0000-0000-0000-000000000004',
        'Fitness & Coaching',
        'fitness-coaching',
        '1-on-1 personal training, golf/tennis instruction, and specialized private coaching.',
        'fitness_center_rounded',
        4
    ),
    (
        'c0000005-0000-0000-0000-000000000005',
        'Professional Consulting',
        'professional-consulting',
        'Legal counsel, certified tax/accounting, financial advising, and architecture review.',
        'gavel_rounded',
        5
    ),
    (
        'c0000006-0000-0000-0000-000000000006',
        'Studios & Space Rentals',
        'studios-space-rentals',
        'Photography cycloramas, podcast/audio booths, and private production suites.',
        'meeting_room_rounded',
        6
    )
ON CONFLICT (id) DO NOTHING;

-- 8. Seed Data: Templates for Each Category

-- Template 1: Dental Clinic
INSERT INTO public.business_templates (
    id, category_id, name, slug, description, icon, booking_model,
    default_settings, ui_config, starter_services, starter_staff_roles, display_order
) VALUES 
-- Gene - Nov, 04, 2026: Changed template IDs from non-hex 't0000001' to valid UUID hex 'b0000001'
(
    'b0000001-0000-0000-0000-000000000001',
    'c0000001-0000-0000-0000-000000000001',
    'Dental Care Clinic',
    'dental-clinic',
    'Perfect for general dentists, orthodontists, periodontists, and oral surgeons.',
    'medical_information_rounded',
    'slot_based',
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
    }'::jsonb,
    '[
        {"name": "Comprehensive Exam & Digital X-Ray", "description": "Full mouth exam, digital radiography, and preventive gum scoring.", "duration_minutes": 45, "price": 120.00, "payment_policy": "deposit_required", "deposit_amount": 30.00},
        {"name": "Preventive Teeth Cleaning (Prophylaxis)", "description": "Ultrasonic scaling, stain removal, and fluoride polish.", "duration_minutes": 45, "price": 95.00, "payment_policy": "pay_at_venue"},
        {"name": "In-Office Teeth Whitening", "description": "Professional 60-minute accelerated light-activated whitening treatment.", "duration_minutes": 60, "price": 350.00, "payment_policy": "deposit_required", "deposit_amount": 50.00},
        {"name": "Orthodontic & Invisalign Consultation", "description": "3D intraoral digital scan and smile simulation.", "duration_minutes": 30, "price": 50.00, "payment_policy": "full_upfront"}
    ]'::jsonb,
    '["General Dentist", "Lead Orthodontist", "Dental Hygienist", "Oral Surgeon"]'::jsonb,
    1
),
-- Template 2: Medical Practice / Specialist
(
    'b0000001-0000-0000-0000-000000000002',
    'c0000001-0000-0000-0000-000000000001',
    'Medical Specialist & Dermatology',
    'medical-dermatology',
    'Ideal for dermatologists, pediatricians, cardiologists, and outpatient clinical consultations.',
    'health_and_safety_rounded',
    'slot_based',
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
    }'::jsonb,
    '[
        {"name": "New Patient Clinical Consultation", "description": "Comprehensive physical evaluation and diagnostics review.", "duration_minutes": 45, "price": 180.00, "payment_policy": "deposit_required", "deposit_amount": 50.00},
        {"name": "Targeted Follow-up & Treatment Review", "description": "Ongoing care monitoring and prescription adjustment.", "duration_minutes": 30, "price": 95.00, "payment_policy": "pay_at_venue"},
        {"name": "Clinical Skin Check & Biopsy Review", "description": "Full-body dermatoscope inspection of moles and lesions.", "duration_minutes": 45, "price": 220.00, "payment_policy": "deposit_required", "deposit_amount": 50.00}
    ]'::jsonb,
    '["Board Certified Dermatologist", "Attending Physician", "Clinical Nurse Specialist"]'::jsonb,
    2
),
-- Template 3: Post-Op Recovery Care Retreat (Specialized Clinical Stays)
(
    'b0000001-0000-0000-0000-000000000003',
    'c0000002-0000-0000-0000-000000000002',
    'Post-Op Recovery & Wellness Suites',
    'recovery-suites',
    'Specialized multi-day post-operative clinical suites with nursing supervision and rehabilitation support.',
    'hotel_rounded',
    'date_range',
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
    }'::jsonb,
    '[
        {"name": "Private Clinical Recovery Suite (Per Night)", "description": "Private suite with 24/7 dedicated RN monitoring, physical therapy access, and chef-curated meals.", "duration_minutes": 1440, "price": 450.00, "payment_policy": "deposit_required", "deposit_amount": 100.00},
        {"name": "Executive Care Suite & Companion Bed (Per Night)", "description": "Expanded double suite accommodating patient and accompanying family member.", "duration_minutes": 1440, "price": 650.00, "payment_policy": "deposit_required", "deposit_amount": 150.00}
    ]'::jsonb,
    '["Lead Registered Nurse (RN)", "Physical Therapist", "Nutritional Coordinator"]'::jsonb,
    3
),
-- Template 4: Mental Health & Counseling
(
    'b0000001-0000-0000-0000-000000000004',
    'c0000002-0000-0000-0000-000000000002',
    'Mental Health & Therapy Practice',
    'mental-health-therapy',
    'Designed for licensed psychologists, counselors, psychotherapists, and family therapists.',
    'psychology_rounded',
    'slot_based',
    '{
        "slot_interval_minutes": 50,
        "buffer_minutes": 10,
        "requires_approval": false,
        "working_hours": {
            "monday": {"open": "09:00", "close": "19:00", "is_open": true},
            "tuesday": {"open": "09:00", "close": "19:00", "is_open": true},
            "wednesday": {"open": "09:00", "close": "19:00", "is_open": true},
            "thursday": {"open": "09:00", "close": "19:00", "is_open": true},
            "friday": {"open": "09:00", "close": "17:00", "is_open": true},
            "saturday": {"open": "10:00", "close": "14:00", "is_open": true},
            "sunday": {"open": "00:00", "close": "00:00", "is_open": false}
        }
    }'::jsonb,
    '{
        "resource_type": "person",
        "resource_label": "Therapist / Counselor",
        "service_label": "Session Type",
        "show_staff_selection": true,
        "intake_fields": [
            {"id": "preferred_format", "label": "Session Format", "type": "text", "placeholder": "In-Person or Secure Video Call", "required": true},
            {"id": "prior_therapy", "label": "Have you worked with a counselor before?", "type": "boolean", "required": false},
            {"id": "primary_goals", "label": "What are your primary goals for therapy?", "type": "textarea", "placeholder": "Anxiety management, life transition, relationship...", "required": true}
        ]
    }'::jsonb,
    '[
        {"name": "Individual Psychotherapy Session (50 min)", "description": "Confidential one-on-one evidence-based therapy session.", "duration_minutes": 50, "price": 160.00, "payment_policy": "full_upfront"},
        {"name": "Couples & Family Counseling (75 min)", "description": "Systemic counseling focusing on communication and relationship dynamics.", "duration_minutes": 75, "price": 230.00, "payment_policy": "full_upfront"},
        {"name": "Initial Consultation & Intake Assessment (60 min)", "description": "Diagnostic evaluation and personalized treatment roadmap design.", "duration_minutes": 60, "price": 190.00, "payment_policy": "full_upfront"}
    ]'::jsonb,
    '["Licensed Clinical Psychologist (PsyD)", "Licensed Marriage & Family Therapist (LMFT)", "Clinical Social Worker (LCSW)"]'::jsonb,
    4
),
-- Template 5: Hair Salon & Barbershop
(
    'b0000001-0000-0000-0000-000000000005',
    'c0000003-0000-0000-0000-000000000003',
    'Hair Salon & Barbershop',
    'hair-salon-barber',
    'Built for hair stylists, barbers, colorists, and grooming studios.',
    'brush_rounded',
    'slot_based',
    '{
        "slot_interval_minutes": 45,
        "buffer_minutes": 10,
        "requires_approval": false,
        "working_hours": {
            "monday": {"open": "00:00", "close": "00:00", "is_open": false},
            "tuesday": {"open": "10:00", "close": "20:00", "is_open": true},
            "wednesday": {"open": "10:00", "close": "20:00", "is_open": true},
            "thursday": {"open": "10:00", "close": "20:00", "is_open": true},
            "friday": {"open": "10:00", "close": "20:00", "is_open": true},
            "saturday": {"open": "09:00", "close": "18:00", "is_open": true},
            "sunday": {"open": "10:00", "close": "17:00", "is_open": true}
        }
    }'::jsonb,
    '{
        "resource_type": "person",
        "resource_label": "Stylist / Barber",
        "service_label": "Service",
        "show_staff_selection": true,
        "intake_fields": [
            {"id": "hair_length", "label": "Current Hair Length (Short / Medium / Long)", "type": "text", "placeholder": "e.g. Medium (past shoulders)", "required": false},
            {"id": "color_history", "label": "Recent color or chemical treatments in last 6 months?", "type": "text", "placeholder": "e.g. Bleach blonde 2 months ago, none", "required": false}
        ]
    }'::jsonb,
    '[
        {"name": "Precision Haircut & Blowout", "description": "Customized hair architecture, clarifying wash, and signature blowout.", "duration_minutes": 60, "price": 85.00, "payment_policy": "pay_at_venue"},
        {"name": "Full Balayage & Gloss Toner", "description": "Hand-painted sun-kissed lightening with custom gloss finish.", "duration_minutes": 150, "price": 260.00, "payment_policy": "deposit_required", "deposit_amount": 50.00},
        {"name": "Classic Gentleman Barber Cut & Hot Towel Shave", "description": "Scissor-over-comb fade, straight-razor neck shave, and eucalyptus towel.", "duration_minutes": 45, "price": 55.00, "payment_policy": "pay_at_venue"}
    ]'::jsonb,
    '["Master Stylist", "Color Specialist", "Senior Barber"]'::jsonb,
    5
),
-- Template 6: Luxury Day Spa & Esthetics
(
    'b0000001-0000-0000-0000-000000000006',
    'c0000003-0000-0000-0000-000000000003',
    'Luxury Day Spa & Esthetics',
    'day-spa-esthetics',
    'Tailored for day spas, massage therapists, estheticians, and holistic bodywork centers.',
    'self_improvement_rounded',
    'slot_based',
    '{
        "slot_interval_minutes": 60,
        "buffer_minutes": 15,
        "requires_approval": false,
        "working_hours": {
            "monday": {"open": "10:00", "close": "19:00", "is_open": true},
            "tuesday": {"open": "10:00", "close": "19:00", "is_open": true},
            "wednesday": {"open": "10:00", "close": "19:00", "is_open": true},
            "thursday": {"open": "10:00", "close": "19:00", "is_open": true},
            "friday": {"open": "10:00", "close": "20:00", "is_open": true},
            "saturday": {"open": "09:00", "close": "19:00", "is_open": true},
            "sunday": {"open": "10:00", "close": "18:00", "is_open": true}
        }
    }'::jsonb,
    '{
        "resource_type": "person",
        "resource_label": "Therapist / Esthetician",
        "service_label": "Spa Treatment",
        "show_staff_selection": true,
        "intake_fields": [
            {"id": "massage_pressure", "label": "Preferred Pressure (Light / Medium / Firm / Deep)", "type": "text", "placeholder": "Medium to Deep", "required": false},
            {"id": "skin_allergies", "label": "Skin allergies or essential oil sensitivities", "type": "text", "placeholder": "None or list allergies", "required": false}
        ]
    }'::jsonb,
    '[
        {"name": "Deep Tissue Therapeutic Massage (60 min)", "description": "Targeted myofascial release relieving chronic tension and muscle knots.", "duration_minutes": 60, "price": 130.00, "payment_policy": "deposit_required", "deposit_amount": 30.00},
        {"name": "Organic Botanical Hydrating Facial", "description": "Double cleanse, enzymatic exfoliation, custom serum infusion, and cryo-globe massage.", "duration_minutes": 60, "price": 145.00, "payment_policy": "deposit_required", "deposit_amount": 30.00},
        {"name": "Aromatherapy Signature Package (90 min)", "description": "Full-body customized essential oil massage with heated stone spine alignment.", "duration_minutes": 90, "price": 195.00, "payment_policy": "deposit_required", "deposit_amount": 50.00}
    ]'::jsonb,
    '["Licensed Massage Therapist", "Master Esthetician", "Aromatherapy Specialist"]'::jsonb,
    6
),
-- Template 7: Fitness Coaching & Personal Training
(
    'b0000001-0000-0000-0000-000000000007',
    'c0000004-0000-0000-0000-000000000004',
    'Personal Training & Fitness Studio',
    'personal-training',
    'For private fitness trainers, sports performance coaches, and boutique studios.',
    'sports_gymnastics_rounded',
    'slot_based',
    '{
        "slot_interval_minutes": 60,
        "buffer_minutes": 10,
        "requires_approval": false,
        "working_hours": {
            "monday": {"open": "06:00", "close": "20:00", "is_open": true},
            "tuesday": {"open": "06:00", "close": "20:00", "is_open": true},
            "wednesday": {"open": "06:00", "close": "20:00", "is_open": true},
            "thursday": {"open": "06:00", "close": "20:00", "is_open": true},
            "friday": {"open": "06:00", "close": "19:00", "is_open": true},
            "saturday": {"open": "07:00", "close": "14:00", "is_open": true},
            "sunday": {"open": "08:00", "close": "12:00", "is_open": true}
        }
    }'::jsonb,
    '{
        "resource_type": "person",
        "resource_label": "Coach / Trainer",
        "service_label": "Training Program",
        "show_staff_selection": true,
        "intake_fields": [
            {"id": "fitness_goal", "label": "Primary Fitness Goal (Strength, Fat Loss, Endurance)", "type": "text", "placeholder": "e.g. Strength building & functional mobility", "required": true},
            {"id": "injuries", "label": "Any joint injuries or physical limitations?", "type": "textarea", "placeholder": "Lower back tightness, shoulder impingement...", "required": false}
        ]
    }'::jsonb,
    '[
        {"name": "1-on-1 Functional Strength Session (60 min)", "description": "Personalized biomechanics assessment, progressive overload, and movement coaching.", "duration_minutes": 60, "price": 95.00, "payment_policy": "full_upfront"},
        {"name": "Athletic Movement & Speed Assessment", "description": "Kinematic movement screen identifying kinetic imbalances and power output.", "duration_minutes": 60, "price": 120.00, "payment_policy": "full_upfront"}
    ]'::jsonb,
    '["Certified Strength & Conditioning Specialist (CSCS)", "Performance Coach", "Kinesiologist"]'::jsonb,
    7
),
-- Template 8: Professional Legal & Consulting
(
    'b0000001-0000-0000-0000-000000000008',
    'c0000005-0000-0000-0000-000000000005',
    'Legal & Financial Advisory',
    'legal-financial-advisory',
    'Built for attorneys, CPA tax advisors, financial planners, and corporate consultants.',
    'balance_rounded',
    'slot_based',
    '{
        "slot_interval_minutes": 60,
        "buffer_minutes": 15,
        "requires_approval": true,
        "working_hours": {
            "monday": {"open": "09:00", "close": "17:00", "is_open": true},
            "tuesday": {"open": "09:00", "close": "17:00", "is_open": true},
            "wednesday": {"open": "09:00", "close": "17:00", "is_open": true},
            "thursday": {"open": "09:00", "close": "17:00", "is_open": true},
            "friday": {"open": "09:00", "close": "16:00", "is_open": true},
            "saturday": {"open": "00:00", "close": "00:00", "is_open": false},
            "sunday": {"open": "00:00", "close": "00:00", "is_open": false}
        }
    }'::jsonb,
    '{
        "resource_type": "person",
        "resource_label": "Consultant / Attorney",
        "service_label": "Advisory Engagement",
        "show_staff_selection": true,
        "intake_fields": [
            {"id": "legal_matter", "label": "Matter Type (Contract, Corporate, IP, Estate, Tax)", "type": "text", "placeholder": "e.g. Commercial Contract Review", "required": true},
            {"id": "opposing_party", "label": "Adverse / Opposing Party Name (for Conflict Check)", "type": "text", "placeholder": "Party or company name", "required": true},
            {"id": "brief_summary", "label": "Brief overview of question or matter", "type": "textarea", "placeholder": "Summarize key issues...", "required": true}
        ]
    }'::jsonb,
    '[
        {"name": "Initial Legal Strategy Consultation (60 min)", "description": "Structured legal risk analysis, issue spotting, and engagement roadmap.", "duration_minutes": 60, "price": 350.00, "payment_policy": "full_upfront"},
        {"name": "CPA Tax Planning & Entity Structure Review", "description": "Tax mitigation optimization for business owners and high earners.", "duration_minutes": 60, "price": 275.00, "payment_policy": "full_upfront"}
    ]'::jsonb,
    '["Managing Partner / Attorney", "Senior Tax CPA", "Corporate Counsel"]'::jsonb,
    8
),
-- Template 9: Photography & Podcast Studio
(
    'b0000001-0000-0000-0000-000000000009',
    'c0000006-0000-0000-0000-000000000006',
    'Photography & Podcast Studio',
    'photo-podcast-studio',
    'Designed for rentable production spaces, white cycloramas, and broadcast-ready podcast rooms.',
    'camera_indoor_rounded',
    'slot_based',
    '{
        "slot_interval_minutes": 60,
        "buffer_minutes": 30,
        "requires_approval": false,
        "working_hours": {
            "monday": {"open": "08:00", "close": "22:00", "is_open": true},
            "tuesday": {"open": "08:00", "close": "22:00", "is_open": true},
            "wednesday": {"open": "08:00", "close": "22:00", "is_open": true},
            "thursday": {"open": "08:00", "close": "22:00", "is_open": true},
            "friday": {"open": "08:00", "close": "23:00", "is_open": true},
            "saturday": {"open": "08:00", "close": "23:00", "is_open": true},
            "sunday": {"open": "09:00", "close": "21:00", "is_open": true}
        }
    }'::jsonb,
    '{
        "resource_type": "facility",
        "resource_label": "Studio Bay / Room",
        "service_label": "Space Rental",
        "show_staff_selection": true,
        "intake_fields": [
            {"id": "crew_size", "label": "Estimated Crew / Cast Size", "type": "text", "placeholder": "e.g. 5 people", "required": true},
            {"id": "equipment_needs", "label": "Special equipment requested (Strobes, Microphones, C-Stands)", "type": "text", "placeholder": "e.g. 4x Shure SM7B, Aputure 600d", "required": false},
            {"id": "production_type", "label": "Production Type (Fashion, Interview, Commercial)", "type": "text", "placeholder": "e.g. Video podcast recording", "required": true}
        ]
    }'::jsonb,
    '[
        {"name": "Soundproof 4-Mic Podcast Suite (Per Hour)", "description": "Equipped with Shure SM7B mics, Rodecaster Pro II, Blackmagic 4K cameras, and studio headphones.", "duration_minutes": 60, "price": 95.00, "payment_policy": "deposit_required", "deposit_amount": 30.00},
        {"name": "White Cyclorama Photo & Video Bay (Per Hour)", "description": "Corner infinity cove cyclorama with pre-rigged RGB ceiling grid and 200A power distribution.", "duration_minutes": 60, "price": 140.00, "payment_policy": "deposit_required", "deposit_amount": 50.00}
    ]'::jsonb,
    '["Studio A (Cyclorama Cove)", "Studio B (Podcast Suite)", "Sound Stage C"]'::jsonb,
    9
)
ON CONFLICT (id) DO NOTHING;
