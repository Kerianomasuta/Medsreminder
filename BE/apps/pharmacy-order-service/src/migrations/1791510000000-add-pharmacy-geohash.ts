import type { MigrationInterface, QueryRunner } from 'typeorm';
import { encodeGeohash } from '../pharmacies/geohash.js';

export class AddPharmacyGeohash1791510000000 implements MigrationInterface {
  name = 'AddPharmacyGeohash1791510000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE pharmacy.pharmacies ADD COLUMN IF NOT EXISTS geohash varchar(12)',
    );
    const rows = (await queryRunner.query(
      'SELECT id, latitude, longitude FROM pharmacy.pharmacies WHERE geohash IS NULL',
    )) as Array<{ id: string; latitude: number; longitude: number }>;
    for (const row of rows) {
      await queryRunner.query(
        'UPDATE pharmacy.pharmacies SET geohash = $1 WHERE id = $2',
        [encodeGeohash(Number(row.latitude), Number(row.longitude)), row.id],
      );
    }
    await queryRunner.query(
      'ALTER TABLE pharmacy.pharmacies ALTER COLUMN geohash SET NOT NULL',
    );
    await queryRunner.query(
      'CREATE INDEX IF NOT EXISTS pharmacies_geohash_pattern_idx ON pharmacy.pharmacies (geohash varchar_pattern_ops)',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'DROP INDEX IF EXISTS pharmacy.pharmacies_geohash_pattern_idx',
    );
    await queryRunner.query(
      'ALTER TABLE pharmacy.pharmacies DROP COLUMN IF EXISTS geohash',
    );
  }
}
