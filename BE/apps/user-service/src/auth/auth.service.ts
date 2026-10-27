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
        if (existingUser.isActive === false) {
            throw ErrorHandling.Forbidden('This account is locked')
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
                user: {
                    id: existingUser._id.toString(),
                    email: existingUser.email,
                    fullName: existingUser.fullName,
                    role: existingUser.role,
                },
            }
        }
    }

    async handleUserLogout(logoutData: any) {
        const { userId, deviceId } = logoutData

        const existingUser = await this.userService.findById(userId);
        if (!existingUser) {
            throw ErrorHandling.Unauthorized(`[Fake token detected!] This user is not exist in the system!`)
        }

        await this.tokenService.removeRefreshToken({
            userId: userId,
            deviceId: deviceId
        });

        return {
            status: 200,
            message: 'Refresh token has been removed!'
        }
    }

    async handleUserRefreshToken(refreshTokenData: any) {
        const { oldRefreshToken } = refreshTokenData

        const { userId, deviceId } = await this.tokenService.verifyRefreshToken({ refreshToken: oldRefreshToken })

        await this.tokenService.removeRefreshToken({
            userId: userId,
            deviceId: deviceId,
        })

        const existingUser = await this.userService.findById(userId)
        if (!existingUser) {
            throw ErrorHandling.Unauthorized(`This user from refresh token is not exist in the system!`)
        }
        if (existingUser.isActive === false) {
            throw ErrorHandling.Forbidden('This account is locked')
        }

        const { accessToken, refreshToken } = await this.tokenService.generateToken({
            deviceId: deviceId,
            userId: userId,
            role: existingUser?.role.toString(),
            fullName: existingUser?.fullName.toString(),
        })

        await this.tokenService.saveRefreshToken({
            refreshToken: refreshToken,
            deviceId: deviceId,
            userId: userId,
        })

        return {
            status: 200,
            data: {
                accessToken: accessToken,
                refreshToken: refreshToken,
                user: {
                    id: existingUser._id.toString(),
                    email: existingUser.email,
                    fullName: existingUser.fullName,
                    role: existingUser.role,
                },
            }
        }
    }

    async handleUserRegister(registerData: any) {
        const {
            email,
            password,
            role,
            fullName,
            phone
        } = registerData;

        const normalizedEmail = email.trim().toLowerCase();
        const normalizedPhone = String(phone ?? '').trim();

        const existingUser = await this.userService.findByEmail(normalizedEmail);
        if (existingUser) {
            throw ErrorHandling.Conflict('This email is already used');
        }

        const existingPhone = await this.userService.findByPhone(normalizedPhone);
        if (existingPhone) {
            throw ErrorHandling.Conflict('This phone number is already used');
        }

        const hashedPassword = await bcrypt.hashSync(password, 12);

        let newUser;
        try {
            newUser = await this.userService.createNewUser({
                email: normalizedEmail,
                password: hashedPassword,
                role: role,
                fullName: fullName,
                phone: normalizedPhone,
            });
        } catch (error) {
            const duplicate = duplicateField(error);
            if (duplicate === 'phone') {
                throw ErrorHandling.Conflict('This phone number is already used');
            }
            if (duplicate === 'email') {
                throw ErrorHandling.Conflict('This email is already used');
            }
            throw error;
        }

        if (!newUser) {
            throw ErrorHandling.InternalServerError(`cannot create new User!`)
        }

        return {
            status: 201,
            data: {
                newUser,
            }
        }
    }
}

function duplicateField(error: unknown) {
    if (!error || typeof error !== 'object' || !('code' in error)) {
        return null;
    }
    if (error.code !== 11000) {
        return null;
    }
    const keyPattern = 'keyPattern' in error && error.keyPattern && typeof error.keyPattern === 'object'
        ? error.keyPattern as Record<string, unknown>
        : {};
    if (keyPattern.phone) {
        return 'phone';
    }
    if (keyPattern.email) {
        return 'email';
    }
    return null;
}
