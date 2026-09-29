import { Injectable } from "@nestjs/common";
import { ErrorHandling } from "@lib/error-handling";
import { UserService } from "../users/user.service.js";
import * as bcrypt from 'bcrypt'
import { TokenService } from "../token/token.service.js";
@Injectable()
export class AuthService {
    constructor(
        private readonly userService: UserService,
        private readonly tokenService: TokenService,
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

        const { accessToken, refreshToken, deviceId } = await this.tokenService.generateToken({
            fullName: existingUser.fullName,
            deviceId: '',
            role: existingUser.role,
            userId: existingUser?._id.toString(),
        })

        await this.tokenService.saveRefreshToken({
            refreshToken: refreshToken,
            deviceId: deviceId,
            userId: existingUser?._id.toString()
        });

        return {
            status: 200,
            data: {
                accessToken: accessToken,
                refreshToken: refreshToken,
            }
        }
    }
}