const ROLES = ['PATIENT', 'CARE_GIVER', 'PHARMACIST', 'ADMIN'] as const;

export type AdminRole = (typeof ROLES)[number];

export type AdminUserRecord = {
  _id?: unknown;
  email?: unknown;
  fullName?: unknown;
  phone?: unknown;
  role?: unknown;
  avatar_url?: unknown;
  isPremium?: unknown;
  premiumExpiresAt?: unknown;
  isActive?: unknown;
  createdAt?: unknown;
  updatedAt?: unknown;
};

export function toAdminUser(row: AdminUserRecord) {
  return {
    id: String(row._id ?? ''),
    email: text(row.email),
    fullName: text(row.fullName),
    phone: text(row.phone),
    role: text(row.role),
    avatarUrl: text(row.avatar_url) || null,
    isPremium: row.isPremium === true,
    premiumExpiresAt: row.premiumExpiresAt ?? null,
    isActive: row.isActive !== false,
    createdAt: row.createdAt ?? null,
    updatedAt: row.updatedAt ?? null,
  };
}

export function buildAdminUserFilter(input: { role?: string; q?: string; isActive?: boolean }) {
  const filter: Record<string, unknown> = {};
  if (input.role) {
    filter.role = input.role;
  }
  if (input.isActive === true) {
    filter.isActive = { $ne: false };
  }
  if (input.isActive === false) {
    filter.isActive = false;
  }
  const query = input.q?.trim();
  if (query) {
    const pattern = escapeRegex(query).slice(0, 80);
    filter.$or = [
      { email: { $regex: pattern, $options: 'i' } },
      { fullName: { $regex: pattern, $options: 'i' } },
      { phone: { $regex: pattern, $options: 'i' } },
    ];
  }
  return filter;
}

export function isAdminRole(value: string): value is AdminRole {
  return ROLES.includes(value as AdminRole);
}

function text(value: unknown) {
  return typeof value === 'string' ? value : '';
}

function escapeRegex(value: string) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
