import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { DataSource } from 'typeorm';
import { Prescription } from './../src/prescriptions/schema/prescription.entity.js';
import { PrescriptionItem } from './../src/prescriptions/schema/prescription-item.entity.js';
import { ScheduleRule } from './../src/schedule-rules/schema/schedule-rule.entity.js';
import { MedicationLog } from './../src/medication-logs/schema/medication-log.entity.js';
import { MedicineUnit } from './../src/enums/medicine-unit.enum.js';

// Integration test: persist a prescription and its item against a live
// PostgreSQL instance (provided as a CI service container). A dedicated test
// DataSource with synchronize:true builds the schema from the real entities, so
// the entity mapping, enum type and the parent-child relation are all exercised.
describe('Prescription persistence (integration, PostgreSQL)', () => {
  const url =
    process.env.MEDICATION_DATABASE_URL ??
    'postgres://meds:meds@localhost:5432/meds_test';
  let ds: DataSource;

  beforeAll(async () => {
    // The entities live in the `medication` schema; create it first because
    // TypeORM synchronize does not create the schema itself.
    const bootstrap = new DataSource({ type: 'postgres', url });
    await bootstrap.initialize();
    await bootstrap.query('CREATE SCHEMA IF NOT EXISTS medication');
    await bootstrap.destroy();

    ds = new DataSource({
      type: 'postgres',
      url,
      schema: 'medication',
      entities: [Prescription, PrescriptionItem, ScheduleRule, MedicationLog],
      synchronize: true,
    });
    await ds.initialize();
  });

  afterAll(async () => {
    if (ds?.isInitialized) {
      await ds.query('DROP SCHEMA IF EXISTS medication CASCADE');
      await ds.destroy();
    }
  });

  it('writes a prescription with an item and reads it back with the relation', async () => {
    const prescriptions = ds.getRepository(Prescription);
    const items = ds.getRepository(PrescriptionItem);

    const saved = await prescriptions.save(
      prescriptions.create({
        patientId: '6711a0000000000000000a01',
        createdByCgId: '6711b0000000000000000b01',
        title: 'Integration test don',
        startDate: '2026-10-01',
      }),
    );

    await items.save(
      items.create({
        prescriptionId: saved.id,
        name: 'Metformin 500mg',
        unit: MedicineUnit.VIEN,
        dosagePerTime: '1',
        currentStock: '30',
      }),
    );

    const found = await prescriptions.findOne({
      where: { id: saved.id },
      relations: ['items'],
    });

    expect(found).toBeTruthy();
    expect(found?.items).toHaveLength(1);
    expect(found?.items[0].name).toBe('Metformin 500mg');
    expect(found?.items[0].unit).toBe(MedicineUnit.VIEN);
  });
});
