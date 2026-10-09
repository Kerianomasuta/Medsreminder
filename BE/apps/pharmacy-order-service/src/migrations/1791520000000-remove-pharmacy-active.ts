import type { MigrationInterface, QueryRunner } from 'typeorm';

export class RemovePharmacyActive1791520000000 implements MigrationInterface {
  name = 'RemovePharmacyActive1791520000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE pharmacy.pharmacies DROP COLUMN IF EXISTS is_active',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE pharmacy.pharmacies ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true',
    );
  }
}
