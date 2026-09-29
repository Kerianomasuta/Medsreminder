import { IsEmail, IsNotEmpty, MinLength } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class LoginDto {
    @ApiProperty({
        example: 'user@example.com',
        description: 'Account email address',
    })
    @IsEmail({
        allow_utf8_local_part: false,
        require_tld: true,
    })
    email: string;

    @ApiProperty({
        example: 'password123',
        minLength: 8,
        description: 'Account password',
    })
    @IsNotEmpty({ message: 'Please fill the password field!'})
    @MinLength(8, { message: 'Password has at least 8 characters '})
    password: string
}