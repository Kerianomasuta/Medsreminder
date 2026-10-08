import { BadRequestException, Controller, Get, Param, Patch, Post, Req, UseGuards } from "@nestjs/common";
import { UserService } from "./user.service.js";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guards.js";
import { Role, UserRole } from "../auth/guards/authorizedByRoles/roles.decorator.js";
import { lastValueFrom } from "rxjs";
import { ApiCookieAuth, ApiOperation, ApiParam, ApiResponse, ApiTags } from "@nestjs/swagger";
import type { Request } from "express";
import { RolesGuard } from "../auth/guards/authorizedByRoles/roles.guard.js";

@Controller('api/v1/users')
@ApiTags('Users')
export class UserController {
    constructor(
        private readonly userService: UserService,
    ) {}

    @Get('patient-detail/:patientId')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Role(UserRole.ADMIN, UserRole.CARE_GIVER)
    @ApiOperation({ summary: 'Get patient details' })
    @ApiCookieAuth('accessToken')
    @ApiParam({
        name: 'patientId',
        description: 'MongoDB ObjectId of the patient',
        example: '6abbd74f1a65898500954ec6',
    })
    @ApiResponse({
        status: 200,
        description: 'Patient details retrieved successfully.',
        schema: {
            example: {
                status: 'success',
                data: {
                    _id: '6abbd74f1a65898500954ec6',
                    email: 'patient@example.com',
                    fullName: 'Nguyen Van A',
                    phone: '0912345678',
                    role: 'PATIENT',
                },
            },
        },
    })
    @ApiResponse({ status: 400, description: 'Invalid patient ID or patient not found.' })
    @ApiResponse({ status: 401, description: 'Access token is missing or invalid.' })
    @ApiResponse({ status: 403, description: 'Only administrators and caregivers can access patient details.' })
    async getDetailPatient(
        @Param('patientId') patientId: string,
    ) {
        if (!patientId) {
            throw new BadRequestException(`user id is required on the params!`)
        }

        const tcpResponse = await lastValueFrom(
            this.userService.getDetailPatient(patientId),
        )

        return {
            status: 'success',
            data: tcpResponse?.data?.patient
        }
    }

    @Post('create-link-invitation')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Role(
        UserRole.PATIENT,
    )
    @ApiOperation({ summary: 'Create a caregiver invitation code' })
    @ApiCookieAuth('accessToken')
    @ApiResponse({
        status: 201,
        description: 'Invitation code created successfully.',
        schema: {
            example: {
                status: 'success',
                message: 'Invitation has been created successfully!',
                data: {
                    invitationUUID: '550e8400-e29b-41d4-a716-446655440000',
                },
            },
        },
    })
    @ApiResponse({
        status: 200,
        description: 'An existing active invitation code was returned.',
    })
    @ApiResponse({ status: 401, description: 'Access token is missing or invalid.' })
    @ApiResponse({ status: 403, description: 'Only patients can create invitation codes.' })
    async createLinkInvitation(
        @Req() req: Request,
    ) {
        const { userId: patientId } = (req as any)?.user

        const tcpResponse = await lastValueFrom(
            this.userService.createLinkInvitation(patientId),
        )

        return {
            status: 'success',
            message: 'Invitation has been created successfully!',
            data: {
                invitationUUID: tcpResponse.data?.invitationUUID
            }
        }
    }

    @Patch('verify-invitation/:invitationUUID')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Role(
        UserRole.CARE_GIVER,
    )
    @ApiOperation({ summary: 'Verify an invitation and link a patient' })
    @ApiCookieAuth('accessToken')
    @ApiParam({
        name: 'invitationUUID',
        description: 'UUID invitation code shared by the patient.',
        example: '550e8400-e29b-41d4-a716-446655440000',
    })
    @ApiResponse({
        status: 200,
        description: 'Patient linked to caregiver successfully.',
        schema: {
            example: {
                status: 'success',
                message: 'Patient has been linked to Caregiver successfully!',
                data: {
                    linkInfo: {
                        _id: '6ac6470513a14fc6ee7cd163',
                        patient: '6abbd74f1a65898500954ec6',
                        caregiver: '6ac6470513a14fc6ee7cd163',
                        status: 'ACTIVE',
                    },
                },
            },
        },
    })
    @ApiResponse({ status: 400, description: 'Invitation is expired or invalid.' })
    @ApiResponse({ status: 401, description: 'Access token is missing or invalid.' })
    @ApiResponse({ status: 403, description: 'Only caregivers can verify invitations.' })
    @ApiResponse({ status: 409, description: 'Caregiver is already linked to this patient.' })
    async verifyInvitation(
        @Param(`invitationUUID`) invitationUUID: string,
        @Req() req: Request
    ) {
        const { userId: caregiverId } = (req as any)?.user;

        const payload = {
            invitationUUID: invitationUUID,
            caregiverId: caregiverId,
        }

        const tcpResponse = await lastValueFrom(
            this.userService.verifyInvitation(payload)
        )

        return {
            status: 'success',
            message: 'Patient has been linked to Caregiver successfully!',
            data: {
                linkInfo: tcpResponse?.data?.invitationLink
            }
        }
    }

    @Get('link-infomations')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Role(
        UserRole.CARE_GIVER,
        UserRole.PATIENT,
    )
    @ApiOperation({ summary: 'Get linked patient or caregiver accounts' })
    @ApiCookieAuth('accessToken')
    @ApiResponse({
        status: 200,
        description: 'Linked account information retrieved successfully.',
        schema: {
            example: {
                status: 'success',
                data: {
                    linkedAccounts: [
                        {
                            linkId: '6ac6470513a14fc6ee7cd163',
                            linkedAt: '2026-10-07T13:20:05.419Z',
                            patientInfo: {
                                _id: '6abbd74f1a65898500954ec6',
                                fullName: 'Nguyen Van A',
                            },
                        },
                    ],
                },
            },
        },
    })
    @ApiResponse({ status: 401, description: 'Access token is missing or invalid.' })
    @ApiResponse({ status: 403, description: 'User role is not allowed to view linked accounts.' })
    async getLinkedInformations(
        @Req() req: Request
    ) {
        const { userId, role } = (req as any)?.user

        const payload = {
            userId: userId,
            role: role
        }

        const tcpResponse = await lastValueFrom(
            this.userService.getLinkedInformations(payload)
        )

        return {
            status: 'success',
            data: {
                linkedAccounts: tcpResponse?.data?.linkedAccounts
            }
        }
    }
}
