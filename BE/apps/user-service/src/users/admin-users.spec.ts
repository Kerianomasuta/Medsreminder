import { describe, expect, it } from 'vitest';
import { buildAdminUserFilter, toAdminUser } from './admin-users.js';

describe('toAdminUser', () => {
  it('hides the password and treats a missing active flag as active', () => {
    const user = toAdminUser({
      _id: '507f1f77bcf86cd799439011',
      email: 'a@example.com',
      fullName: 'Nguyen Van A',
      phone: '0912345678',
      role: 'PATIENT',
      isPremium: true,
      password: 'secret',
      fcmToken: 'token',
    } as never);

    expect(user).toEqual({
      id: '507f1f77bcf86cd799439011',
      email: 'a@example.com',
      fullName: 'Nguyen Van A',
      phone: '0912345678',
      role: 'PATIENT',
      avatarUrl: null,
      isPremium: true,
      premiumExpiresAt: null,
      isActive: true,
      createdAt: null,
      updatedAt: null,
    });
    expect(user).not.toHaveProperty('password');
    expect(user).not.toHaveProperty('fcmToken');
  });
});

describe('buildAdminUserFilter', () => {
  it('searches name, email, and phone without treating the query as a regex', () => {
    expect(buildAdminUserFilter({ role: 'CARE_GIVER', q: 'a+b', isActive: false })).toEqual({
      role: 'CARE_GIVER',
      isActive: false,
      $or: [
        { email: { $regex: 'a\\+b', $options: 'i' } },
        { fullName: { $regex: 'a\\+b', $options: 'i' } },
        { phone: { $regex: 'a\\+b', $options: 'i' } },
      ],
    });
  });
});
