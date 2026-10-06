import { HydratedDocument } from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'

export type UserDocument = HydratedDocument<User>

@Schema({ timestamps: true })
export class User {
    @Prop({ required: true, unique: true })
    email: string;

    @Prop({ required: true })
    password: string;

    @Prop({ required: true, enum: ["PATIENT", "CARE_GIVER", "PHARMACIST", "ADMIN"] })
    role: string;

    @Prop({ required: true })
    fullName: string;

    @Prop({ required: true })
    phone: string

    @Prop({})
    avatar_url: string;
}

export const UserSchema = SchemaFactory.createForClass(User)