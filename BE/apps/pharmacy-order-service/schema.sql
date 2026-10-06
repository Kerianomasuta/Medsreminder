CREATE SCHEMA IF NOT EXISTS pharmacy;

DO $$
BEGIN
  CREATE TYPE pharmacy.order_status AS ENUM (
    'PENDING_REVIEW',
    'PREPARING',
    'READY_FOR_PICKUP',
    'ASSIGNED',
    'IN_TRANSIT',
    'DELIVERED',
    'CANCELLED'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DROP TABLE IF EXISTS pharmacy.order_items CASCADE;
DROP TABLE IF EXISTS pharmacy.orders CASCADE;
DROP TABLE IF EXISTS pharmacy.pharmacy_inventory CASCADE;
DROP TABLE IF EXISTS pharmacy.pharmacies CASCADE;

CREATE TABLE pharmacy.pharmacies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacist_id uuid NOT NULL,
  name text NOT NULL,
  phone text NOT NULL,
  address_text text NOT NULL,
  latitude numeric(9, 6) NOT NULL,
  longitude numeric(9, 6) NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE pharmacy.pharmacy_inventory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pharmacy_id uuid NOT NULL REFERENCES pharmacy.pharmacies (id) ON DELETE CASCADE,
  medicine_id uuid NOT NULL REFERENCES medication.medicines (id) ON DELETE RESTRICT,
  stock_quantity integer NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
  price_per_unit numeric(12, 2) NOT NULL CHECK (price_per_unit >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pharmacy_inventory_pharmacy_medicine_uidx UNIQUE (pharmacy_id, medicine_id)
);

CREATE TABLE pharmacy.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_code text NOT NULL UNIQUE,
  patient_id uuid NOT NULL,
  caregiver_id uuid NOT NULL,
  pharmacy_id uuid NOT NULL REFERENCES pharmacy.pharmacies (id) ON DELETE RESTRICT,
  shipper_id uuid,
  prescription_id uuid NOT NULL REFERENCES medication.prescriptions (id) ON DELETE RESTRICT,
  status pharmacy.order_status NOT NULL DEFAULT 'PENDING_REVIEW',
  total_amount numeric(12, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
  delivery_address text NOT NULL,
  delivery_lat numeric(9, 6),
  delivery_lng numeric(9, 6),
  recipient_phone text NOT NULL,
  otp_code varchar(4) CHECK (otp_code IS NULL OR otp_code ~ '^[0-9]{4}$'),
  pod_image_url text,
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS orders_pharmacy_status_idx
  ON pharmacy.orders (pharmacy_id, status);

CREATE INDEX IF NOT EXISTS orders_shipper_status_idx
  ON pharmacy.orders (shipper_id, status);

CREATE TABLE pharmacy.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES pharmacy.orders (id) ON DELETE CASCADE,
  medicine_id uuid NOT NULL REFERENCES medication.medicines (id) ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION pharmacy.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pharmacies_set_updated_at ON pharmacy.pharmacies;
CREATE TRIGGER pharmacies_set_updated_at
  BEFORE UPDATE ON pharmacy.pharmacies
  FOR EACH ROW EXECUTE FUNCTION pharmacy.set_updated_at();

DROP TRIGGER IF EXISTS pharmacy_inventory_set_updated_at ON pharmacy.pharmacy_inventory;
CREATE TRIGGER pharmacy_inventory_set_updated_at
  BEFORE UPDATE ON pharmacy.pharmacy_inventory
  FOR EACH ROW EXECUTE FUNCTION pharmacy.set_updated_at();

DROP TRIGGER IF EXISTS orders_set_updated_at ON pharmacy.orders;
CREATE TRIGGER orders_set_updated_at
  BEFORE UPDATE ON pharmacy.orders
  FOR EACH ROW EXECUTE FUNCTION pharmacy.set_updated_at();

DROP TRIGGER IF EXISTS order_items_set_updated_at ON pharmacy.order_items;
CREATE TRIGGER order_items_set_updated_at
  BEFORE UPDATE ON pharmacy.order_items
  FOR EACH ROW EXECUTE FUNCTION pharmacy.set_updated_at();

GRANT USAGE ON SCHEMA pharmacy TO postgres, service_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pharmacy TO postgres, service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA pharmacy TO postgres, service_role;
