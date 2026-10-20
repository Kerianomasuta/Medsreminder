import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { ErrorHandling } from '@lib/error-handling';
import { Model, Types } from 'mongoose';
import { buildAdminUserFilter, isAdminRole, toAdminUser, type AdminUserRecord } from './admin-users.js';
import { PatientCaregiverLink, PatientCaregiverLinkDocument } from './schema/patient-caregiver-link.schema.js';
import { User, UserDocument } from './schema/user.schema.js';

const PUBLIC_FIELDS = 'email fullName phone role avatar_url isPremium premiumExpiresAt isActive createdAt updatedAt';
const PHONE = /^0[235789][0-9]{8}$/;

type UpdateInput = {
  actorUserId?: string;
  userId?: string;
  fullName?: string;
  phone?: string;
  role?: string;
  isActive?: boolean;
};

@Injectable()
export class AdminUsersService {
  constructor(
    @InjectModel(User.name)
    private readonly users: Model<UserDocument>,
    @InjectModel(PatientCaregiverLink.name)
    private readonly links: Model<PatientCaregiverLinkDocument>,
  ) {}

  async summary() {
    const now = new Date();
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const [grouped, total, premium, inactive, registeredLast7Days, activeLinks, inactiveLinks] = await Promise.all([
      this.users.aggregate<{ _id: string; count: number }>([
        { $group: { _id: '$role', count: { $sum: 1 } } },
      ]),
      this.users.countDocuments(),
      this.users.countDocuments({
        isPremium: true,
        $or: [
          { premiumExpiresAt: { $exists: false } },
          { premiumExpiresAt: null },
          { premiumExpiresAt: { $gt: now } },
        ],
      }),
      this.users.countDocuments({ isActive: false }),
      this.users.countDocuments({ createdAt: { $gte: weekAgo } }),
      this.links.countDocuments({ status: 'ACTIVE' }),
      this.links.countDocuments({ status: 'INACTIVE' }),
    ]);
    const byRole = { PATIENT: 0, CARE_GIVER: 0, PHARMACIST: 0, ADMIN: 0 };
    for (const row of grouped) {
      if (row._id in byRole) {
        byRole[row._id as keyof typeof byRole] = row.count;
      }
    }
    return {
      users: {
        total,
        patient: byRole.PATIENT,
        caregiver: byRole.CARE_GIVER,
        pharmacist: byRole.PHARMACIST,
        admin: byRole.ADMIN,
        premium,
        inactive,
        registeredLast7Days,
      },
      links: { active: activeLinks, inactive: inactiveLinks },
    };
  }

  async list(input: { role?: string; q?: string; isActive?: boolean; page?: number; limit?: number }) {
    if (input.role && !isAdminRole(input.role)) {
      throw ErrorHandling.BadRequest('Role is not supported');
    }
    const page = Math.max(1, Math.floor(input.page ?? 1));
    const limit = Math.min(50, Math.max(1, Math.floor(input.limit ?? 20)));
    const filter = buildAdminUserFilter({ role: input.role, q: input.q, isActive: input.isActive });
    const [total, rows] = await Promise.all([
      this.users.countDocuments(filter),
      this.users
        .find(filter)
        .select(PUBLIC_FIELDS)
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean(),
    ]);
    return { page, limit, total, users: rows.map((row) => toAdminUser(row)) };
  }

  async detail(userId?: string) {
    const user = await this.requireUser(userId);
    return { user: toAdminUser(user), links: await this.linksFor(user) };
  }

  async update(input: UpdateInput) {
    const userId = this.requireObjectId(input.userId);
    const changes = this.changes(input);
    if (Object.keys(changes).length === 0) {
      throw ErrorHandling.BadRequest('No account fields to update');
    }
    if (input.actorUserId === userId && (changes.role !== undefined || changes.isActive === false)) {
      throw ErrorHandling.BadRequest('An admin cannot lock or change the role of their own account');
    }
    if (changes.phone) {
      const taken = await this.users.exists({ phone: changes.phone, _id: { $ne: userId } });
      if (taken) {
        throw ErrorHandling.Conflict('This phone number is already used');
      }
    }
    const updated = await this.users
      .findByIdAndUpdate(userId, changes, { new: true })
      .select(PUBLIC_FIELDS)
      .lean();
    if (!updated) {
      throw ErrorHandling.NotFound('User not found');
    }
    return { user: toAdminUser(updated) };
  }

  private changes(input: UpdateInput) {
    const changes: { fullName?: string; phone?: string; role?: string; isActive?: boolean } = {};
    if (input.fullName !== undefined) {
      const fullName = input.fullName.trim();
      if (fullName.length < 2 || fullName.length > 80) {
        throw ErrorHandling.BadRequest('Full name must be 2 to 80 characters');
      }
      changes.fullName = fullName;
    }
    if (input.phone !== undefined) {
      if (!PHONE.test(input.phone)) {
        throw ErrorHandling.BadRequest('Please provide a Vietnam phone number');
      }
      changes.phone = input.phone;
    }
    if (input.role !== undefined) {
      if (!isAdminRole(input.role)) {
        throw ErrorHandling.BadRequest('Role is not supported');
      }
      changes.role = input.role;
    }
    if (input.isActive !== undefined) {
      if (typeof input.isActive !== 'boolean') {
        throw ErrorHandling.BadRequest('isActive must be true or false');
      }
      changes.isActive = input.isActive;
    }
    return changes;
  }

  private async requireUser(userId?: string) {
    const id = this.requireObjectId(userId);
    const user = await this.users.findById(id).select(PUBLIC_FIELDS).lean();
    if (!user) {
      throw ErrorHandling.NotFound('User not found');
    }
    return user;
  }

  private requireObjectId(userId?: string) {
    if (!userId || !Types.ObjectId.isValid(userId)) {
      throw ErrorHandling.BadRequest('User id is invalid');
    }
    return userId;
  }

  private async linksFor(user: AdminUserRecord) {
    const role = String(user.role ?? '');
    if (role !== 'PATIENT' && role !== 'CARE_GIVER') {
      return [];
    }
    const ownField = role === 'PATIENT' ? 'patient' : 'caregiver';
    const otherField = role === 'PATIENT' ? 'caregiver' : 'patient';
    const rows = await this.links
      .find({ [ownField]: user._id })
      .populate(otherField, 'fullName email role')
      .sort({ linkedAt: -1 })
      .lean();
    return rows.map((row) => {
      const linked = row[otherField];
      const account = linked && typeof linked === 'object' && '_id' in linked
        ? linked as { _id: unknown; fullName?: string; email?: string; role?: string }
        : null;
      return {
        id: String(row._id),
        status: String(row.status ?? ''),
        linkedAt: row.linkedAt ?? null,
        user: account
          ? {
              id: String(account._id),
              fullName: account.fullName ?? '',
              email: account.email ?? '',
              role: account.role ?? '',
            }
          : null,
      };
    });
  }
}
