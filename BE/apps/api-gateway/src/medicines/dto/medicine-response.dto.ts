import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class MedicineResponseDto {
  @ApiProperty({ format: 'uuid', example: '8d8b6f3e-4c1a-4f0b-9c2d-123456789abc' })
  id: string;

  @ApiProperty({ example: 'Paracetamol' })
  name: string;

  @ApiPropertyOptional({ example: 'Acetaminophen', nullable: true })
  genericName: string | null;

  @ApiProperty({ enum: ['VIEN', 'GOI', 'CHAI'], example: 'VIEN' })
  unit: string;

  @ApiPropertyOptional({ example: 'Uống sau ăn', nullable: true })
  instructionNote: string | null;

  @ApiPropertyOptional({ example: 'https://example.com/paracetamol.png', nullable: true })
  imageUrl: string | null;

  @ApiProperty({ example: '2026-10-01T00:00:00.000Z' })
  createdAt: string;

  @ApiProperty({ example: '2026-10-01T00:00:00.000Z' })
  updatedAt: string;
}
