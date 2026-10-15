import { Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';
import { toRpcHttpException } from '../rpc-http-exception.js';
import { ListAdminLogsQueryDto, ListAdminPrescriptionsQueryDto } from './dto/list-admin-medication.query.js';
import { ListAdminOrdersQueryDto, ListAdminPharmaciesQueryDto } from './dto/list-admin-pharmacy.query.js';
import { ListAdminPaymentsQueryDto } from './dto/list-admin-payments.query.js';
import { ListAdminUsersQueryDto } from './dto/list-admin-users.query.js';
import { UpdateAdminUserDto } from './dto/update-admin-user.dto.js';

@Injectable()
export class AdminService {
  constructor(
    @Inject('USER_SERVICE')
    private readonly users: ClientProxy,
    @Inject('MEDICATION_SERVICE')
    private readonly medication: ClientProxy,
    @Inject('PHARMACY_ORDER_SERVICE')
    private readonly pharmacyOrders: ClientProxy,
  ) {}

  summary() {
    return this.send(this.users, 'admin_dashboard_summary', {}, 'User service is unavailable');
  }

  list(query: ListAdminUsersQueryDto) {
    return this.send(this.users, 'admin_list_users', query, 'User service is unavailable');
  }

  detail(userId: string) {
    return this.send(this.users, 'admin_get_user', { userId }, 'User service is unavailable');
  }

  update(actorUserId: string, userId: string, body: UpdateAdminUserDto) {
    return this.send(this.users, 'admin_update_user', { actorUserId, userId, ...body }, 'User service is unavailable');
  }

  medicationSummary() {
    return this.send(this.medication, 'admin_medication_summary', {}, 'Medication service is unavailable');
  }

  listPrescriptions(query: ListAdminPrescriptionsQueryDto) {
    return this.send(this.medication, 'admin_list_prescriptions', query, 'Medication service is unavailable');
  }

  prescription(id: string) {
    return this.send(this.medication, 'admin_get_prescription', { id }, 'Medication service is unavailable');
  }

  listLogs(query: ListAdminLogsQueryDto) {
    return this.send(this.medication, 'admin_list_medication_logs', query, 'Medication service is unavailable');
  }

  pharmacySummary() {
    return this.send(this.pharmacyOrders, 'admin_pharmacy_summary', {}, 'Pharmacy service is unavailable');
  }

  listPharmacies(query: ListAdminPharmaciesQueryDto) {
    return this.send(this.pharmacyOrders, 'admin_list_pharmacies', query, 'Pharmacy service is unavailable');
  }

  pharmacy(id: string) {
    return this.send(this.pharmacyOrders, 'admin_get_pharmacy', { id }, 'Pharmacy service is unavailable');
  }

  listOrders(query: ListAdminOrdersQueryDto) {
    return this.send(this.pharmacyOrders, 'admin_list_orders', query, 'Pharmacy service is unavailable');
  }

  order(id: string) {
    return this.send(this.pharmacyOrders, 'admin_get_order', { id }, 'Pharmacy service is unavailable');
  }

  paymentSummary() {
    return this.send(this.users, 'admin_payment_summary', {}, 'User service is unavailable');
  }

  listPayments(query: ListAdminPaymentsQueryDto) {
    return this.send(this.users, 'admin_list_payments', query, 'User service is unavailable');
  }

  payment(paymentId: string) {
    return this.send(this.users, 'admin_get_payment', { paymentId }, 'User service is unavailable');
  }

  private send<T>(client: ClientProxy, cmd: string, payload: unknown, unavailableMessage: string) {
    return lastValueFrom(client.send<T>({ cmd }, payload)).catch((error: unknown) => {
      throw toRpcHttpException(error, unavailableMessage);
    });
  }
}
