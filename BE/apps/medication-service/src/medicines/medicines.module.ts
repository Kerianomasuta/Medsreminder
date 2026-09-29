import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Medicine } from './schema/medicine.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Medicine])],
  exports: [TypeOrmModule],
})
export class MedicinesModule {}
