-- Replace courier tracking with the shipper's name and phone.
-- Run this once in the Supabase SQL editor.

ALTER TABLE pharmacy.orders
  ADD COLUMN IF NOT EXISTS shipper_name varchar(100),
  ADD COLUMN IF NOT EXISTS shipper_phone varchar(15);

ALTER TABLE pharmacy.orders
  DROP COLUMN IF EXISTS shipping_carrier,
  DROP COLUMN IF EXISTS tracking_code_or_link;
