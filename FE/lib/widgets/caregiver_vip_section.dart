import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/billing_api.dart';
import 'pressable.dart';

class CaregiverVipSection extends StatefulWidget {
  const CaregiverVipSection({super.key, this.billingApi});

  final BillingApi? billingApi;

  @override
  State<CaregiverVipSection> createState() => _CaregiverVipSectionState();
}

class _CaregiverVipSectionState extends State<CaregiverVipSection> {
  late final BillingApi _billingApi = widget.billingApi ?? BillingApi();

  bool _loading = true;
  UserVipProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadVipProfile();
  }

  Future<void> _loadVipProfile() async {
    setState(() {
      _loading = true;
    });
    try {
      final profile = await _billingApi.getUserVipProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openUpgradeModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VipUpgradeModal(
        billingApi: _billingApi,
        onSuccess: _loadVipProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isVip = _profile?.isPremium == true;

    if (isVip) {
      final expiry = _profile?.premiumExpiresAt;
      final expiryStr = expiry != null
          ? '${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}'
          : 'Không thời hạn';

      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1E5C), Color(0xFF5B3AA8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B3AA8).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFFD700),
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Thành viên VIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFFFFD700),
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hạn sử dụng đến: $expiryStr',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Pressable(
              onTap: _openUpgradeModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Gia hạn',
                  style: TextStyle(
                    color: Color(0xFF241549),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tài khoản chưa nâng cấp VIP
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF142247), Color(0xFF28488E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF28488E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFFD700),
                  size: 26,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nâng cấp MedsReminder VIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mở khóa AI quét đơn thuốc & Xuất báo cáo PDF',
                      style: TextStyle(
                        color: Color(0xFFBDCEFF),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chỉ từ 39.200 đ / tháng',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Pressable(
                onTap: _openUpgradeModal,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem gói cước',
                        style: TextStyle(
                          color: Color(0xFF0F1A3A),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF0F1A3A),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VipUpgradeModal extends StatefulWidget {
  const _VipUpgradeModal({
    required this.billingApi,
    required this.onSuccess,
  });

  final BillingApi billingApi;
  final VoidCallback onSuccess;

  @override
  State<_VipUpgradeModal> createState() => _VipUpgradeModalState();
}

class _VipUpgradeModalState extends State<_VipUpgradeModal> {
  bool _loading = true;
  String? _error;

  bool _isPaymentEnabled = false;
  List<BillingPlan> _plans = [];
  String _selectedPlan = 'MONTH';

  bool _creatingLink = false;
  PaymentLinkResult? _paymentLinkResult;

  bool _simulatingWebhook = false;

  @override
  void initState() {
    super.initState();
    _fetchBillingData();
  }

  Future<void> _fetchBillingData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 1. GET /api/v1/billing/config
      final config = await widget.billingApi.getConfig();
      // 2. GET /api/v1/billing/plans
      final plans = await widget.billingApi.getPlans();

      if (mounted) {
        setState(() {
          _isPaymentEnabled = config.isPaymentEnabled;
          _plans = plans;
          if (_plans.isNotEmpty) {
            _selectedPlan = _plans.first.plan;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // 3. POST /api/v1/billing/create-payment-link
  Future<void> _handleCreatePaymentLink() async {
    setState(() {
      _creatingLink = true;
      _error = null;
    });
    try {
      final result = await widget.billingApi.createPaymentLink(_selectedPlan);
      if (mounted) {
        setState(() {
          _paymentLinkResult = result;
          _creatingLink = false;
        });
      }
      // Tự động mở link PayOS
      final uri = Uri.tryParse(result.checkoutUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _creatingLink = false;
        });
      }
    }
  }

  // 4. POST /api/v1/billing/payos-webhook (Kích hoạt / Kiểm tra Webhook thử nghiệm)
  Future<void> _handleTestPayosWebhook() async {
    if (_paymentLinkResult == null) return;
    setState(() => _simulatingWebhook = true);
    try {
      final selectedPlanObj = _plans.firstWhere(
        (p) => p.plan == _selectedPlan,
        orElse: () => BillingPlan(plan: _selectedPlan, amount: 49000, label: ''),
      );
      final payload = {
        'code': '00',
        'desc': 'success',
        'success': true,
        'data': {
          'orderCode': _paymentLinkResult!.orderCode,
          'amount': selectedPlanObj.amount,
          'description': 'MedsReminder VIP $_selectedPlan',
          'accountNumber': 'PAYOS_TEST',
          'reference': 'REF_${DateTime.now().millisecondsSinceEpoch}',
          'transactionDateTime': DateTime.now().toIso8601String(),
        },
        'signature': 'test_signature',
      };

      await widget.billingApi.confirmPayosWebhook(payload);
      widget.onSuccess();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu kích hoạt Webhook! Đang làm mới...'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi Webhook: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _simulatingWebhook = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F8FF),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: _loading
              ? const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2D6EC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFD4AF37),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gói VIP MedsReminder',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Mở khóa toàn bộ đặc quyền chăm sóc sức khỏe',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      if (!_isPaymentEnabled) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2E8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFBB96)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.build_rounded,
                                  color: Color(0xFFFA541C)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tính năng thanh toán đang trong chế độ bảo trì hoặc xét duyệt. Vui lòng quay lại sau!',
                                  style: TextStyle(
                                    color: Color(0xFFD4380D),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        // Danh sách đặc quyền
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Column(
                            children: [
                              _FeatureLine(
                                icon: Icons.camera_alt_rounded,
                                title: 'AI Quét đơn thuốc bằng hình ảnh',
                                subtitle: 'Tự động nhận diện đơn thuốc giấy',
                              ),
                              Divider(height: 16),
                              _FeatureLine(
                                icon: Icons.picture_as_pdf_rounded,
                                title: 'Xuất báo cáo tuân thủ PDF',
                                subtitle: 'Biểu đồ chi tiết gửi cho bác sĩ',
                              ),
                              Divider(height: 16),
                              _FeatureLine(
                                icon: Icons.notification_important_rounded,
                                title: 'Cảnh báo người thân tức thì',
                                subtitle: 'Báo động khi bệnh nhân quên cữ',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Danh sách các gói (GET /plans)
                        const Text(
                          'Chọn gói dịch vụ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._plans.map((plan) {
                          final isSelected = _selectedPlan == plan.plan;
                          final isYear = plan.plan == 'YEAR';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => setState(() => _selectedPlan = plan.plan),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEEF2FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : const Color(0xFFE5E7EB),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF4F46E5)
                                              : const Color(0xFF9CA3AF),
                                          width: isSelected ? 6.5 : 2,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                plan.label,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if (isYear) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFDC2626),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Text(
                                                    'TIẾT KIỆM 20%',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_formatCurrency(plan.amount)} đ',
                                            style: const TextStyle(
                                              color: Color(0xFF4F46E5),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Nút tạo link thanh toán (POST /create-payment-link)
                        FilledButton(
                          onPressed: _creatingLink ? null : _handleCreatePaymentLink,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _creatingLink
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.payment_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tạo link thanh toán PayOS',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        // Khối hiển thị khi đã có link PayOS
                        if (_paymentLinkResult != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF16A34A)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Đơn hàng #${_paymentLinkResult!.orderCode} đã tạo!',
                                      style: const TextStyle(
                                        color: Color(0xFF166534),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    final uri = Uri.tryParse(
                                        _paymentLinkResult!.checkoutUrl);
                                    if (uri != null) {
                                      launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_browser_rounded),
                                  label: const Text('Mở lại trang thanh toán PayOS'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () {
                                          widget.onSuccess();
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(Icons.refresh_rounded),
                                        label: const Text('Kiểm tra VIP'),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: _simulatingWebhook
                                            ? null
                                            : _handleTestPayosWebhook,
                                        icon: const Icon(Icons.webhook_rounded),
                                        label: const Text('Test Webhook'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
