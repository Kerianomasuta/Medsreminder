import { Inject, Injectable } from "@nestjs/common";
import { ClientProxy } from "@nestjs/microservices";
import { LoginDto } from "./dto/login.dto.js";

@Injectable()
export class AuthService {
    constructor(
        @Inject('USER_SERVICE')
        private readonly userClient: ClientProxy,
    ) {}

    login(
        loginDto: LoginDto
    ) {
        return this.userClient.send({ cmd: 'handle_user_login' }, loginDto)
    }
}