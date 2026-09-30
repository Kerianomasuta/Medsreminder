import { Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { User, UserDocument } from "./schema/user.schema.js";
import { Model } from "mongoose";

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
}