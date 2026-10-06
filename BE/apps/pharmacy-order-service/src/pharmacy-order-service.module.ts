import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
<<<<<<< HEAD
=======
import { InventoryModule } from './inventory/inventory.module.js';
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
import { OrdersModule } from './orders/orders.module.js';
import { PharmaciesModule } from './pharmacies/pharmacies.module.js';

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
        ssl: { rejectUnauthorized: false },
      }),
    }),
    PharmaciesModule,
<<<<<<< HEAD
=======
    InventoryModule,
>>>>>>> f8787549117cce75ddd3b4459fd77c4f0f0ad9cb
    OrdersModule,
  ],
})
export class PharmacyOrderServiceModule {}
