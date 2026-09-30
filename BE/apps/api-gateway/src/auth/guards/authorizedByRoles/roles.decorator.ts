import { SetMetadata } from "@nestjs/common";

export const ROLES_KEY = 'roles'

export enum UserRole {
    PATIENT = 'PATIENT',
    CARE_GIVER = 'CARE_GIVER',
    PHARMACIST = 'PHARMACIST',
    DRUGSHIPPER = 'DRUGSHIPPER',
    ADMIN = 'ADMIN'
}

export const Role = (...roles: UserRole[]) =>
    SetMetadata(ROLES_KEY, roles)