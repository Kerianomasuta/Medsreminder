-- Submitted orders copy the prescription line. They no longer require a pharmacy medicine or a price.
-- Run this once in the Supabase SQL editor.

ALTER TABLE pharmacy.order_items
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS unit text,
  ADD COLUMN IF NOT EXISTS image_url text;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'pharmacy'
      AND table_name = 'order_items'
      AND column_name = 'prescription_item_id'
  ) THEN
    UPDATE pharmacy.order_items AS item
    SET
      name = line.name,
      unit = line.unit::text,
      image_url = line.image_url
    FROM medication.prescription_items AS line
    WHERE item.prescription_item_id = line.id
      AND item.name IS NULL;
  END IF;
END $$;

UPDATE pharmacy.order_items
SET
  name = COALESCE(name, 'Unknown'),
  unit = COALESCE(unit, 'VIEN')
WHERE name IS NULL OR unit IS NULL;

ALTER TABLE pharmacy.order_items
  ALTER COLUMN name SET NOT NULL,
  ALTER COLUMN unit SET NOT NULL,
  ALTER COLUMN medicine_id DROP NOT NULL,
  ALTER COLUMN unit_price DROP NOT NULL;
