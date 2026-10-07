-- Move medicine identity onto each prescription line.
-- medicines stays the pharmacy catalog. Run this once in the Supabase SQL editor.

ALTER TABLE medication.prescription_items
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS generic_name text,
  ADD COLUMN IF NOT EXISTS image_url text;

DO $$
DECLARE
  unit_type text;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'medication'
      AND table_name = 'prescription_items'
      AND column_name = 'unit'
  ) THEN
    SELECT format('%I.%I', n.nspname, t.typname)
    INTO unit_type
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace cn ON cn.oid = c.relnamespace
    JOIN pg_type t ON t.oid = a.atttypid
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE cn.nspname = 'medication'
      AND c.relname = 'medicines'
      AND a.attname = 'unit'
      AND a.attnum > 0
      AND NOT a.attisdropped;

    IF unit_type IS NULL THEN
      RAISE EXCEPTION 'Could not find the enum type of medication.medicines.unit';
    END IF;

    EXECUTE format('ALTER TABLE medication.prescription_items ADD COLUMN unit %s', unit_type);
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'medication'
      AND table_name = 'prescription_items'
      AND column_name = 'medicine_id'
  ) THEN
    UPDATE medication.prescription_items AS item
    SET
      name = medicine.name,
      generic_name = medicine.generic_name,
      unit = medicine.unit,
      image_url = medicine.image_url
    FROM medication.medicines AS medicine
    WHERE item.medicine_id = medicine.id
      AND item.name IS NULL;
  END IF;
END $$;

ALTER TABLE medication.prescription_items
  ALTER COLUMN name SET NOT NULL,
  ALTER COLUMN unit SET NOT NULL;

ALTER TABLE medication.prescription_items
  DROP COLUMN IF EXISTS medicine_id;
