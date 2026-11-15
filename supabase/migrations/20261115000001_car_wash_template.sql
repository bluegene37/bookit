-- Gene - Nov, 15, 2026: Seed Automotive & Detailing category plus Auto Detailing and Express & Full-Service Car Wash templates

INSERT INTO public.business_categories (id, name, slug, description, icon, display_order, is_active)
VALUES (
    'c0000007-0000-0000-0000-000000000007',
    'Automotive & Detailing',
    'automotive-detailing',
    'Car wash, ceramic coatings, interior steam sanitization, and mobile detailing fleets.',
    'local_car_wash_rounded',
    7,
    true
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    slug = EXCLUDED.slug,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    display_order = EXCLUDED.display_order,
    is_active = EXCLUDED.is_active;

INSERT INTO public.business_templates (
    id, category_id, name, slug, description, icon, booking_model,
    default_settings, ui_config, starter_services, starter_staff_roles, display_order, is_active
)
VALUES
(
    'b0000001-0000-0000-0000-000000000010',
    'c0000007-0000-0000-0000-000000000007',
    'Auto Detailing & Car Wash',
    'auto-detailing-car-wash',
    'Hand foam washes, interior steam extraction, 1-step machine polish, and multi-year ceramic paint coatings.',
    'local_car_wash_rounded',
    'slot_based',
    '{
        "slot_interval_minutes": 30,
        "buffer_minutes": 10,
        "requires_approval": false,
        "deposit_percent": 25.0,
        "cancellation_window_hours": 24,
        "advance_booking_days": 30,
        "min_notice_hours": 2,
        "working_hours": {
            "monday": {"open": "08:00", "close": "18:00", "is_open": true},
            "tuesday": {"open": "08:00", "close": "18:00", "is_open": true},
            "wednesday": {"open": "08:00", "close": "18:00", "is_open": true},
            "thursday": {"open": "08:00", "close": "18:00", "is_open": true},
            "friday": {"open": "08:00", "close": "18:00", "is_open": true},
            "saturday": {"open": "08:00", "close": "18:00", "is_open": true},
            "sunday": {"open": "09:00", "close": "16:00", "is_open": true}
        }
    }'::jsonb,
    '{
        "resource_type": "bay_and_technician",
        "resource_label": "Detailing Bay & Specialist",
        "service_label": "Auto Detailing Package",
        "show_staff_selection": true,
        "intake_fields": [
            {"id": "vehicle_type", "label": "Vehicle Size & Class", "type": "select", "required": true, "options": ["Sedan / Hatchback", "Mid-Size SUV / Crossover", "Full-Size SUV / Pickup Truck", "Minivan / Commercial Van"]},
            {"id": "vehicle_make_model_year", "label": "Vehicle Year, Make & Model", "type": "text", "required": true, "placeholder": "e.g. 2024 Porsche Macan, Chalk White"},
            {"id": "license_plate", "label": "License Plate # & State", "type": "text", "required": true, "placeholder": "e.g. 7XYZ123 (CA)"},
            {"id": "heavy_soiling_pet_hair", "label": "Excessive pet hair, interior mold, or heavy caked mud?", "type": "boolean", "required": true, "helper_text": "Additional manual steam extraction surcharge ($30-$50) may apply at intake inspection."},
            {"id": "ceramic_matte_paint", "label": "Vehicle has existing ceramic coating, matte paint, or protective vinyl wrap?", "type": "boolean", "required": false, "helper_text": "Ensures pH-neutral foam wash and contact-free drying towels."},
            {"id": "special_requests", "label": "Interior focus areas or special requests", "type": "textarea", "required": false, "placeholder": "Cup holder stains, engine bay wipe, child car seat sanitized..."}
        ]
    }'::jsonb,
    '[
        {"name": "Signature Hand Wash & Wheel Decon", "description": "Touchless pre-foam, 2-bucket hand wash, iron wheel decontamination, and tire dressing.", "duration_minutes": 45, "price": 55.00, "payment_policy": "pay_at_venue"},
        {"name": "Executive Interior Steam & Leather Care", "description": "Deep dry steam extraction, vents sanitized, leather conditioned, and carpet shampoo.", "duration_minutes": 90, "price": 165.00, "payment_policy": "deposit_required", "deposit_amount": 40.00},
        {"name": "Complete Diamond Detail (In & Out)", "description": "Full exterior clay bar decontamination, 1-month sealant, and intensive interior steam sanitize.", "duration_minutes": 150, "price": 280.00, "payment_policy": "deposit_required", "deposit_amount": 70.00},
        {"name": "1-Step Paint Correction & Machine Polish", "description": "Swirl mark and light scratch elimination restoring gloss and optical depth.", "duration_minutes": 180, "price": 380.00, "payment_policy": "deposit_required", "deposit_amount": 95.00},
        {"name": "3-Year Pro Ceramic Coating Package", "description": "Full paint decontamination, multi-stage prep, and 9H SiO2 ceramic liquid glass application.", "duration_minutes": 240, "price": 850.00, "payment_policy": "deposit_required", "deposit_amount": 200.00},
        {"name": "Engine Bay Steam Clean & Dressing", "description": "Safe low-moisture steam degreasing of plastics and hoses with satin UV protectant.", "duration_minutes": 45, "price": 75.00, "payment_policy": "pay_at_venue"},
        {"name": "Headlight Restoration & UV Sealant", "description": "Wet-sanding yellowed foggy polycarbonate headlights with clear ceramic cure.", "duration_minutes": 45, "price": 90.00, "payment_policy": "pay_at_venue"}
    ]'::jsonb,
    '["Bay 1: Master Certified Detailer & Paint Corrector", "Bay 2: Senior Interior Steam Specialist", "Bay 3: Ceramic Coating Technician"]'::jsonb,
    10,
    true
),
(
    'b0000001-0000-0000-0000-000000000011',
    'c0000007-0000-0000-0000-000000000007',
    'Express & Full-Service Car Wash',
    'express-car-wash',
    'High-throughput snow foam exterior washes, full inside-and-out vacuum packages, undercarriage mud flush, and hand wax bays.',
    'water_drop_rounded',
    'slot_based',
    '{
        "slot_interval_minutes": 15,
        "buffer_minutes": 5,
        "requires_approval": false,
        "deposit_percent": 0.0,
        "cancellation_window_hours": 2,
        "advance_booking_days": 14,
        "min_notice_hours": 0,
        "working_hours": {
            "monday": {"open": "07:00", "close": "20:00", "is_open": true},
            "tuesday": {"open": "07:00", "close": "20:00", "is_open": true},
            "wednesday": {"open": "07:00", "close": "20:00", "is_open": true},
            "thursday": {"open": "07:00", "close": "20:00", "is_open": true},
            "friday": {"open": "07:00", "close": "20:00", "is_open": true},
            "saturday": {"open": "07:00", "close": "20:00", "is_open": true},
            "sunday": {"open": "08:00", "close": "18:00", "is_open": true}
        }
    }'::jsonb,
    '{
        "resource_type": "wash_bay",
        "resource_label": "Wash Bay",
        "service_label": "Car Wash Package",
        "show_staff_selection": true,
        "intake_fields": [
            {"id": "vehicle_body_type", "label": "Vehicle Size & Body Type", "type": "select", "required": true, "options": ["Sedan / Coupe / Hatchback", "Compact SUV / Crossover", "Full-Size SUV / 3-Row / Pickup Truck", "Passenger Van / Lifted 4x4"]},
            {"id": "vehicle_plate_and_model", "label": "License Plate # & Vehicle Make / Color", "type": "text", "required": true, "placeholder": "e.g. ABC-1234 • Silver Toyota Hilux / White Civic"},
            {"id": "wash_addons", "label": "Optional Express Add-Ons (Select any)", "type": "multiselect", "required": false, "options": ["Undercarriage High-Pressure Mud & Salt Flush", "Hydrophobic Rain-Repellent Glass Coat", "Tire Gloss & Alloy Brake-Dust Brightener", "Pet Hair & Trunk Brush Extraction", "Antibacterial AC Vent Mist & Cabin Scent", "Child Car Seat Steam Sanitize"]},
            {"id": "roof_rack_clearance_check", "label": "Does vehicle exceed 7 ft height or carry unsecured roof-box / open pickup bed cargo?", "type": "boolean", "required": true, "blocking_condition": true, "blocking_message": "Vehicles over 7 ft clearance or carrying loose roof/bed cargo cannot enter standard wash bays safely. Please remove loose cargo or contact the wash bay crew for oversize hand-wash clearance.", "helper_text": "Toggle ON only if over 7 ft height or carrying loose exterior items."},
            {"id": "matte_wrap_or_ppf", "label": "Matte paint, vinyl wrap, PPF, or aftermarket antenna?", "type": "boolean", "required": false, "helper_text": "Crew will use pH-neutral snow foam and touch-safe microfiber drying."},
            {"id": "valuables_acknowledgment", "label": "Pre-Wash Valuables & Exterior Inspection Check", "type": "signature", "required": true, "disclaimer": "I confirm personal valuables have been secured or removed from the cabin/console and power windows/sunroof are fully closed prior to wash bay entry."}
        ]
    }'::jsonb,
    '[
        {"name": "Express Exterior Snow Foam & Dry", "description": "High-pressure pre-rinse, thick pH-neutral snow foam bath, spot-free RO rinse, and microfiber air-dry.", "duration_minutes": 20, "price": 18.00, "payment_policy": "pay_at_venue"},
        {"name": "Full-Service Inside & Out Car Wash", "description": "Exterior snow foam hand wash, full cabin & trunk vacuum, dash/console wipe, door jambs, and streak-free glass.", "duration_minutes": 35, "price": 32.00, "payment_policy": "pay_at_venue"},
        {"name": "SUV & Pickup Heavy Mud + Undercarriage Wash", "description": "High-pressure chassis & wheel-well mud flush, bug/tar removal, rubber mat scrub, and deep interior vacuum.", "duration_minutes": 45, "price": 45.00, "payment_policy": "pay_at_venue"},
        {"name": "Deluxe Carnauba Hand Wax & Tire Shine", "description": "Full inside-and-out wash plus warm Brazilian carnauba hand wax for wet-look gloss and UV paint protection.", "duration_minutes": 50, "price": 58.00, "payment_policy": "deposit_required", "deposit_amount": 15.00},
        {"name": "Rain-Shield Glass Coat & Alloy Wheel Decon", "description": "Iron brake-dust decontamination on rims, hydrophobic windshield polymer sealant, and satin tire dressing.", "duration_minutes": 40, "price": 48.00, "payment_policy": "pay_at_venue"},
        {"name": "VIP Wash + SiO2 Spray Ceramic Sealant", "description": "Touchless foam wash, clay-mitt decon, 3-month hydrophobic SiO2 ceramic spray coat, and full interior wipe-down.", "duration_minutes": 60, "price": 75.00, "payment_policy": "deposit_required", "deposit_amount": 20.00},
        {"name": "Cabin Seat Shampoo & Ozone Odor Reset", "description": "Fabric/carpet stain extraction, leather UV conditioning, and antibacterial AC ozone odor neutralizer.", "duration_minutes": 60, "price": 85.00, "payment_policy": "deposit_required", "deposit_amount": 20.00}
    ]'::jsonb,
    '["Wash Bay 1 (Express Snow Foam & Exterior)", "Wash Bay 2 (Full-Service Inside & Out)", "Wash Bay 3 (SUV / Pickup & Hand Wax Bay)"]'::jsonb,
    11,
    true
)
ON CONFLICT (id) DO UPDATE SET
    category_id = EXCLUDED.category_id,
    name = EXCLUDED.name,
    slug = EXCLUDED.slug,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    booking_model = EXCLUDED.booking_model,
    default_settings = EXCLUDED.default_settings,
    ui_config = EXCLUDED.ui_config,
    starter_services = EXCLUDED.starter_services,
    starter_staff_roles = EXCLUDED.starter_staff_roles,
    display_order = EXCLUDED.display_order,
    is_active = EXCLUDED.is_active;
