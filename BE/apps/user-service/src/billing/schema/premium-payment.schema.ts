import { HydratedDocument } from 'mongoose';
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

export type PremiumPaymentDocument = HydratedDocument<PremiumPayment>;

@Schema({ timestamps: true, collection: 'premium_payments' })
export class PremiumPayment {
  @Prop({ required: true, index: true })
  userId: string;

  @Prop({ required: true, enum: ['MONTH', 'YEAR'] })
  plan: 'MONTH' | 'YEAR';

  @Prop({ required: true })
  amount: number;

  @Prop({ required: true, unique: true })
  txnRef: string;

  @Prop({ unique: true, sparse: true })
  orderCode?: number;

  @Prop({ required: true, enum: ['PENDING', 'PAID', 'FAILED'], default: 'PENDING' })
  status: 'PENDING' | 'PAID' | 'FAILED';

  @Prop()
  providerTransactionNo?: string;

  @Prop()
  paidAt?: Date;
}

export const PremiumPaymentSchema = SchemaFactory.createForClass(PremiumPayment);
