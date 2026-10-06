import { Controller } from "@nestjs/common";
import { UserService } from "./user.service.js";
import { MessagePattern, Payload } from "@nestjs/microservices";
import { ErrorHandling } from "@lib/error-handling";

@Controller()
export class UserController {
    constructor(
        private readonly userService: UserService,
    ) {}

    @MessagePattern({ cmd: "handle_get_patient_detail" })
    async handleGetPatientDetail(@Payload() data: any) {
        return this.userService.handleGetPatientDetail(data);
    }
}