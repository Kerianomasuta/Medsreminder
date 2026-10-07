import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { HydratedDocument, Types } from "mongoose";
import { User } from "./user.schema.js";

export type PatientCaregiverLinkDocument = HydratedDocument<PatientCaregiverLink>

@Schema({ timestamps: { createdAt: 'linkedAt', updatedAt: 'updatedAt' } })
export class PatientCaregiverLink {
    @Prop({
        type: Types.ObjectId, 
        ref: 'User', 
        required: true, 
        index: true,
    })
    patient: User | Types.ObjectId;

    @Prop({
        type: Types.ObjectId,
        ref: "User",
        required: true,
        index: true,
    })
    caregiver: User | Types.ObjectId

    @Prop({
        type: String,
        enum: ['ACTIVE', 'INACTIVE'],
        default: 'ACTIVE'
    })
    status: String;

    linkedAt: Date;
}

export const PatientCaregiverLinkSchema = SchemaFactory.createForClass(PatientCaregiverLink)

PatientCaregiverLinkSchema.index({ patient: 1, caregiver: 1}, { unique: true });
