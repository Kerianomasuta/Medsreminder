import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import mongoose from 'mongoose';
import { UserSchema } from './../src/users/schema/user.schema.js';

// Integration test: write and read a real user document against a live MongoDB
// instance (provided as a CI service container). Uses the production UserSchema
// so schema defaults and the role enum are exercised end to end.
describe('User persistence (integration, MongoDB)', () => {
  const uri = process.env.MONGO_URI ?? 'mongodb://localhost:27017/meds_test';
  let conn: mongoose.Connection;

  beforeAll(async () => {
    conn = mongoose.createConnection(uri);
    await conn.asPromise();
  });

  afterAll(async () => {
    if (conn) {
      await conn.dropDatabase();
      await conn.close();
    }
  });

  it('writes and reads a user document with schema defaults applied', async () => {
    const User = conn.model('User', UserSchema);
    const email = `patient_${Date.now()}@test.vn`;

    await User.create({
      email,
      password: 'hashed-password',
      role: 'PATIENT',
      fullName: 'Nguyen Van A',
      phone: '0900000000',
    });

    const found = await User.findOne({ email }).lean();
    expect(found).toBeTruthy();
    expect(found?.role).toBe('PATIENT');
    expect(found?.isPremium).toBe(false); // default from schema
    expect(found?.isActive).toBe(true); // default from schema
  });
});
