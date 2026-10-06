import { IsEmail, IsEnum, IsNotEmpty, Matches, MaxLength, MinLength } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class RegisterDto {
    @ApiProperty({
        example: 'user@example.com',
        description: 'Account email address',
    })
    @IsNotEmpty({ message: 'Email is required!' })
    @IsEmail({
        allow_utf8_local_part: false,
        require_tld: true,
    }, { message: 'Please provide the right email format!'})
    email: string;

    @ApiProperty({
        example: 'password123',
        minLength: 8,
        description: 'Account password',
    })
    @IsNotEmpty({ message: 'Password is required!' })
    @MinLength(8, { message: `Password has at least 8 characters!`})
    password: string;

    @ApiProperty({
        example: 'PATIENT',
        enum: ['PATIENT', 'CARE_GIVER', 'PHARMACIST'],
        description: 'Role assigned to the new account',
    })
    @IsNotEmpty({ message: 'Role is required!' })
    @IsEnum(["PATIENT", "CARE_GIVER", "PHARMACIST"])
    role: string;

    @ApiProperty({
        example: 'Nguyen Van A',
        minLength: 2,
        maxLength: 30,
        description: 'Full name of the account holder',
    })
    @IsNotEmpty({ message: "full name is required!" })
    @MinLength(2, { message: "fullName has at least 2 chareacters!" })
    @MaxLength(30, { message: "full name has maximum 30 characters!" })
    fullName: string;

    @ApiProperty({
        example: '0912345678',
        description: 'Vietnamese phone number',
    })
    @IsNotEmpty({ message: 'phone is required!' })
    @Matches(/^0[235789][0-9]{8}$/, {
        message: 'please provide Vietnam phone number'
    })
    phone: string
}