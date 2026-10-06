import { Inject, Injectable } from "@nestjs/common";
import { ClientProxy } from "@nestjs/microservices";

@Injectable()
export class UserService {
    constructor(
        @Inject('USER_SERVICE')
        private readonly userClient: ClientProxy,
    ) {}
    getDetailPatient(patientId: string) {
        return this.userClient.send({ cmd: 'handle_get_patient_detail' }, { patientId })
    }
}