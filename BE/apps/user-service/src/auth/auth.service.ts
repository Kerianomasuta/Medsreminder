import { Injectable } from "@nestjs/common";
import { ErrorHandling } from "libs/error-handling/src/error-handling.js";
import { UserService } from "../users/user.service.js";
import * as bcrypt from 'bcrypt'
@Injectable()
export class AuthService {
    constructor(
        private readonly userService: UserService,
    ) {}

    async handleUserLogin(loginData: any) {
        const { email, password } = loginData;

        if (!email) {
            throw ErrorHandling.BadRequest(`Please provide email!`)
        }

        const normalizedEmail = email.trim().toLowerCase();

        const existingUser = await this.userService.findByEmail(normalizedEmail)

        if (!existingUser) {
            throw ErrorHandling.BadRequest('This user is not exist')
        }

        const isMatchedPassword = await bcrypt.compare(password, existingUser.password);

        if (!isMatchedPassword) {
            throw ErrorHandling.BadRequest(`Wrong password!`)
        }
    }
}