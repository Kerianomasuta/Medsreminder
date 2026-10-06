import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { User, UserDocument } from "./schema/user.schema.js";
import { Model } from "mongoose";
import { ErrorHandling } from "@lib/error-handling";

@Injectable()
export class UserService {
    constructor(
        @InjectModel(User.name)
        private userModel: Model<UserDocument>
    ) {}

    async findByEmail(email: string): Promise<UserDocument | null> {
        return this.userModel.findOne({ email }).exec();
    }
    async findById(userId: string): Promise<UserDocument | null> {
        return this.userModel.findOne({ _id: userId }).select("-password").exec();
    }

    async createNewUser(input: {
        email: string,
        password: string,
        fullName: string,
        role: string,
        phone: string,
    }) {
        return this.userModel.create(input);
    }

    async handleGetPatientDetail(input: {
        patientId: string
    }) {
        const patient = await this.userModel.findById(input.patientId)
                                            .select("-password -__v")
                                            .exec();
        if (!patient) {
            throw ErrorHandling.BadRequest(`Patient not found!`)
        }
        if (String(patient.role) !== "PATIENT") {
            throw ErrorHandling.Forbidden('You can only access to patient ID!')
        }

        return {
            status: 200,
            data: {
                patient
            }
        }
    }
}