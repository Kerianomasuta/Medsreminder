import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MedicinesController } from './medicines.controller.js';
import { MedicinesService } from './medicines.service.js';
import { Medicine } from './schema/medicine.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Medicine])],
  controllers: [MedicinesController],
  providers: [MedicinesService],
  exports: [TypeOrmModule, MedicinesService],
})
export class MedicinesModule {}
