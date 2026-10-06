import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { User, UserSchema } from "./schema/user.schema.js";
import { UserService } from "./user.service.js";
import { UserController } from "./user.controller.js";

@Module({
    imports:[
        MongooseModule.forFeature([
            { name: User.name, schema: UserSchema}
        ])
    ],
    controllers: [UserController],
    providers: [UserService],
    exports: [UserService]
})
export class UserModule {}