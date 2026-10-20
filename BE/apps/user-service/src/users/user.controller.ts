import { Controller } from "@nestjs/common";
import { AdminUsersService } from "./admin-users.service.js";
import { UserService } from "./user.service.js";
import { MessagePattern, Payload } from "@nestjs/microservices";

@Controller()
export class UserController {
    constructor(
        private readonly userService: UserService,
        private readonly adminUsersService: AdminUsersService,
    ) {}

    @MessagePattern({ cmd: 'admin_dashboard_summary' })
    adminSummary() {
        return this.adminUsersService.summary();
    }

    @MessagePattern({ cmd: 'admin_list_users' })
    adminListUsers(@Payload() data: { role?: string; q?: string; isActive?: boolean; page?: number; limit?: number }) {
        return this.adminUsersService.list(data ?? {});
    }

    @MessagePattern({ cmd: 'admin_get_user' })
    adminGetUser(@Payload() data: { userId?: string }) {
        return this.adminUsersService.detail(data?.userId);
    }

    @MessagePattern({ cmd: 'admin_update_user' })
    adminUpdateUser(@Payload() data: { actorUserId?: string; userId?: string; fullName?: string; phone?: string; role?: string; isActive?: boolean }) {
        return this.adminUsersService.update(data ?? {});
    }

    @MessagePattern({ cmd: "handle_get_patient_detail" })
    async handleGetPatientDetail(@Payload() data: any) {
        return this.userService.handleGetPatientDetail(data);
    }

    @MessagePattern({ cmd: "handle_create_link_invitation" })
    async handleCreateLinkInvitation(@Payload() data: any) {
        return this.userService.handleCreateLinkInvitation(data)
    }

    @MessagePattern({ cmd: "handle_verify_invitation" })
    async handleVerifyInvitation(@Payload() data: any) {
        const invitationLink = await this.userService.handleVerifyInvitation(data);

        return {
            status: 200,
            data: {
                invitationLink,
            }
        }
    }

    @MessagePattern({ cmd: "handle_get_premium" })
    handleGetPremium(@Payload() data: { userId?: string }) {
        return this.userService.getPremium(data?.userId ?? '');
    }

    @MessagePattern({ cmd: 'save_fcm_token' })
    saveFcmToken(@Payload() data: { userId?: string; token?: string }) {
        return this.userService.saveFcmToken(data);
    }

    @MessagePattern({ cmd: 'clear_fcm_token' })
    clearFcmToken(@Payload() data: { token?: string }) {
        return this.userService.clearFcmToken(data);
    }

    @MessagePattern({ cmd: 'list_patient_caregivers' })
    listPatientCaregivers(@Payload() data: { patientId?: string }) {
        return this.userService.listPatientCaregivers(data);
    }

    @MessagePattern({ cmd: "handle_get_linked_informations" })
    async handleGetLinkedInformations(@Payload() data: { userId: string, role: string }) {
        const linkedAccounts = await this.userService.handleGetLinkedInformations(data)

        return {
            status: 200,
            data: {
                linkedAccounts: linkedAccounts
            }
        }
    }
}