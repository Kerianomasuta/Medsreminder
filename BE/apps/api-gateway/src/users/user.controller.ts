import { BadRequestException, Controller, Get, Param, UseGuards } from "@nestjs/common";
import { UserService } from "./user.service.js";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guards.js";
import { Role, UserRole } from "../auth/guards/authorizedByRoles/roles.decorator.js";
import { lastValueFrom } from "rxjs";
import { ApiCookieAuth, ApiOperation, ApiParam, ApiResponse, ApiTags } from "@nestjs/swagger";

@Controller('api/v1/users')
@ApiTags('Users')
export class UserController {
    constructor(
        private readonly userService: UserService,
    ) {}

    @Get('patient-detail/:patientId')
    @UseGuards(JwtAuthGuard)
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
}