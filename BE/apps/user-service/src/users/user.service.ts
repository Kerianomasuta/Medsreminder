import { Inject, Injectable } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { User, UserDocument } from "./schema/user.schema.js";
import { Model } from "mongoose";
import { ErrorHandling } from "@lib/error-handling";
import { PatientCaregiverLink, PatientCaregiverLinkDocument } from "./schema/patient-caregiver-link.schema.js";
import { Redis } from "ioredis";
import * as crypto from 'crypto'
import { ConfigService } from "@nestjs/config";

const INVITATION_TTL = 15 * 60 * 1000

@Injectable()
export class UserService {
    constructor(
        @InjectModel(User.name)
        private userModel: Model<UserDocument>,
        
        @InjectModel(PatientCaregiverLink.name)
        private linkModel: Model<PatientCaregiverLinkDocument>,

        @Inject('REDIS_CLIENT')
        private readonly redisClient: Redis,

        private readonly configService: ConfigService
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

    async handleCreateLinkInvitation(input: {
        patientId: string
    }) {
        const patient = await this.userModel.findById(input.patientId)
                                            .select("_id")
                                            .exec()
        if (!patient) {
            throw ErrorHandling.AuthenticationFailed(`Fake token detected!`)
        }

        try {
            const patientActiveKey = `patient_active_qr:${input.patientId}`;
            const existingActiveQr = await this.redisClient.get(patientActiveKey)
            if (existingActiveQr) {
                const existingLink = 
                `${this.configService.get<string>(`FRONTEND_INVITATION_URL`)}/invitation?invitationUUID=${existingActiveQr}`;

                return {
                    status: 200,
                    data: {
                        invitationLink: existingLink
                    }
                }
            }

            const invitationUUID = crypto.randomUUID()

            const invitationKey = `invitation_session:${invitationUUID}`;

            const invitationLink = `${this.configService.get<string>(`FRONTEND_INVITATION_URL`)}/invitation?invitationUUID=${invitationUUID}`

            await this.redisClient.set(
                invitationKey,
                input.patientId,
                'EX',
                INVITATION_TTL,
            );

            await this.redisClient.set(
                patientActiveKey,
                invitationUUID,
                "EX",
                INVITATION_TTL,
            )

            return {
                status: 201,
                data: {
                    invitationLink,
                }
            }
        } catch (error: any) {
            console.log("[Create Invitation Error] - Cannot push invitation to redis: ", error?.message || error);
            throw ErrorHandling.ServiceUnavailableError(`Cannot create invitation link! Please try again later!`)
        }
    }

    async handleVerifyInvitation(input: {
        invitationUUID: string,
        caregiverId: string,
    }) {
        const caregiver = await this.userModel.exists({ _id: input.caregiverId })
        if (!caregiver) {
            throw ErrorHandling.NotFound(`cannot found user from this token!`)
        }

        const invitationKey = `invitation_session:${input.invitationUUID}`
        
        let patientId;
        try {
            patientId = await this.redisClient.get(invitationKey);
        } catch (error: any) {
            console.log(`[Verify Invitation Error] - Cannot verify invitation from redis: ${error?.message || error}`);
            if (error.status === 400) {
                throw ErrorHandling.BadRequest(`This invitation is expired or invalid!`);
            }
            throw ErrorHandling.ServiceUnavailableError(`Cannot verify invitation! Please try again later!`);
        }

        if (!patientId) {
            throw ErrorHandling.BadRequest(`This invitation is expired or invalid!`);
        }

        try {
            const existingLink = await this.linkModel.findOne({
                patient: patientId,
                caregiver: input.caregiverId,
            })

            const patientActiveKey = `patient_active_qr:${patientId}`

            if (existingLink && existingLink.status === 'ACTIVE') {
                await Promise.all([
                    this.redisClient.del(invitationKey),
                    this.redisClient.del(patientActiveKey),
                ])
                

                throw ErrorHandling.Conflict(`You already linked with this patient!`)
            }

            const updatedLink = await this.linkModel.findOneAndUpdate(
                { patient: patientId, caregiver: input.caregiverId },
                { $set: { status: 'ACTIVE' } },
                { upsert: true, new: true },
            );

            await Promise.all([
                    this.redisClient.del(invitationKey),
                    this.redisClient.del(patientActiveKey),
                ])

            return updatedLink;
        } catch (error: any) {
            console.log(`[Verify Invitation Error] - Cannot save link to db: ${error?.message || error}`);
            if (error.status === 409 || error.name === 'ConflictError') throw error
            throw ErrorHandling.ServiceUnavailableError(`Cannot verify invitation! Please try again later!`);
        }
    }

    async handleGetLinkedInformations(input: {
        userId: string,
        role: string,
    }) {
        try {
            if (input.role === "CARE_GIVER") {
                const links = await this.linkModel.find({
                    caregiver: input.userId,
                    status: 'ACTIVE',
                }).populate('patient', 'fullName').exec();

                return links.map(link => ({
                    linkId: link._id,
                    linkedAt: link.linkedAt,
                    patienInfo: link.patient
                }))
            }

            else if (input.role === "PATIENT") {
                const links = await this.linkModel.find({
                    patient: input.userId,
                    status: 'ACTIVE',
                }).populate('caregiver', 'fullName').exec();

                return links.map(link => ({
                    linkId: link._id,
                    linkedAt: link.linkedAt,
                    caregiverInfo: link.caregiver
                }))
            }

            throw ErrorHandling.Forbidden(`You do not have permission to access this!`)
        } catch (error: any) {
            console.error(`[Get Linked Info Error]:`, error?.message || error);

            if (error.status === 403) {
                throw Error
            }

            throw ErrorHandling.ServiceUnavailableError(`Cannot get linked information at the moment.`);
        }
    }
}