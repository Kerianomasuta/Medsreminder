import { IsEmail, IsNotEmpty, MinLength } from "class-validator";

export class LoginDto {
    @IsEmail({
        allow_utf8_local_part: false,
        require_tld: true,
    })
    email: string;

    @IsNotEmpty({ message: 'Please fill the password field!'})
    @MinLength(8, { message: 'Password has at least 8 characters '})
    password: string
}