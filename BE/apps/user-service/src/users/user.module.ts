import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { User, UserSchema } from "./schema/user.schema.js";
import { UserService } from "./user.service.js";
import { UserController } from "./user.controller.js";
import { PatientCaregiverLink, PatientCaregiverLinkSchema } from "./schema/patient-caregiver-link.schema.js";

@Module({
    imports:[
        MongooseModule.forFeature([
            { name: User.name, schema: UserSchema },
            { name: PatientCaregiverLink.name, schema: PatientCaregiverLinkSchema }
        ])
    ],
    controllers: [UserController],
    providers: [UserService],
    exports: [UserService]
})
export class UserModule {}