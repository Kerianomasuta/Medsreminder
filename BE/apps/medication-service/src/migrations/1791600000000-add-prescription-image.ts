import type { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPrescriptionImage1791600000000 implements MigrationInterface {
  name = 'AddPrescriptionImage1791600000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE medication.prescriptions
      ADD COLUMN IF NOT EXISTS image_data bytea,
      ADD COLUMN IF NOT EXISTS image_content_type varchar(100)
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE medication.prescriptions
      DROP COLUMN IF EXISTS image_data,
      DROP COLUMN IF EXISTS image_content_type
    `);
  }
}
