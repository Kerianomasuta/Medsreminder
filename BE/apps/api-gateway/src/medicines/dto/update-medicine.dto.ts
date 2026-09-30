import { PartialType } from '@nestjs/swagger';
import { CreateMedicineDto } from './create-medicine.dto.js';

export class UpdateMedicineDto extends PartialType(CreateMedicineDto) {}
