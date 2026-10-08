import { IsEmail, IsEnum, IsNotEmpty, IsNumber, IsString, Matches, Max, MaxLength, Min, MinLength, ValidateIf } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

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

    @ApiPropertyOptional({
        example: 'Nhà thuốc An Khang',
        description: 'Pharmacy name. Required when role is PHARMACIST. This is the shop name, not the account holder name.',
    })
    @ValidateIf((dto: RegisterDto) => dto.role === 'PHARMACIST')
    @IsString()
    @IsNotEmpty({ message: 'pharmacyName is required for a pharmacist' })
    @MaxLength(150)
    pharmacyName?: string;

    @ApiPropertyOptional({
        example: '123 Lê Lợi, Quận 1, TP.HCM',
        description: 'Street address from the phone GPS. Required when role is PHARMACIST. This becomes the pharmacy address.',
    })
    @ValidateIf((dto: RegisterDto) => dto.role === 'PHARMACIST')
    @IsString()
    @IsNotEmpty({ message: 'addressText is required for a pharmacist' })
    @MaxLength(2000)
    addressText?: string;

    @ApiPropertyOptional({
        example: 10.7769,
        description: 'GPS latitude. Required when role is PHARMACIST.',
    })
    @ValidateIf((dto: RegisterDto) => dto.role === 'PHARMACIST')
    @IsNumber()
    @Min(-90)
    @Max(90)
    latitude?: number;

    @ApiPropertyOptional({
        example: 106.7009,
        description: 'GPS longitude. Required when role is PHARMACIST.',
    })
    @ValidateIf((dto: RegisterDto) => dto.role === 'PHARMACIST')
    @IsNumber()
    @Min(-180)
    @Max(180)
    longitude?: number;
}