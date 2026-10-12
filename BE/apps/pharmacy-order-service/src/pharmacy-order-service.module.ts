import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersModule } from './orders/orders.module.js';
import { PharmaciesModule } from './pharmacies/pharmacies.module.js';
import { AddPharmacyGeohash1791510000000 } from './migrations/1791510000000-add-pharmacy-geohash.js';
import { RemovePharmacyActive1791520000000 } from './migrations/1791520000000-remove-pharmacy-active.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: 'apps/pharmacy-order-service/.env',
    }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        url: config.getOrThrow<string>('PHARMACY_DATABASE_URL'),
        schema: config.get<string>('PHARMACY_DB_SCHEMA', 'pharmacy'),
        autoLoadEntities: true,
        synchronize: false,
        migrations: [
          AddPharmacyGeohash1791510000000,
          RemovePharmacyActive1791520000000,
        ],
        migrationsRun: true,
        migrationsTableName: 'pharmacy_migrations',
        ssl: { rejectUnauthorized: false },
      }),
    }),
    PharmaciesModule,
    OrdersModule,
  ],
})
export class PharmacyOrderServiceModule {}
