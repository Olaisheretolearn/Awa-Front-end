import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'payments_screen.dart';
import 'payment_page.dart';
import 'shared_bottom_nav.dart';
import '../api/client.dart';
import '../api/messages_api.dart';
import '../api/model_message.dart';
import '../api/auth_api.dart';
import '../api/model.dart';
import '../api/room_api.dart';
import '../utils/url_utils.dart';
import 'package:flutter/services.dart';
import '../api/bills_api.dart';
import '../api/bills_models.dart';
import '../state/currency_store.dart';
import '../widgets/exit_app_guard.dart';

const _currencyFallback = ['Noto Sans Symbols 2', 'Noto Sans', 'Roboto'];

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  int _selectedTabIndex = 0;
  Set<String> _expandedBills = <String>{};
  late final ApiClient _api;
  late final BillsApi _billsApi;

  String get _cur => CurrencyStore.symbol.value;
  String _fmt(num v) => '$_cur${v.toStringAsFixed(2)}';
  late final VoidCallback _currencyListener;

  Map<String, String> _nameOf = {};

  List<BillResponse> _bills = [];
  bool _loadingBills = false;
  double _youreOwed = 0.0;

  String? _roomId, _userId;
  bool _bootLoading = true;

  @override
  void initState() {
    super.initState();
    _api = ApiClient.dev();
    _billsApi = BillsApi(_api);

    _currencyListener = () {
      if (!mounted) return;
      setState(() {});
    };
    CurrencyStore.symbol.addListener(_currencyListener);

    () async {
      final me = await AuthApi(_api).getMe();
      final myRoom = await RoomApi(_api).getMyRoom();
      setState(() {
        _userId = me.id;
        _roomId = myRoom.room?.id;
        _nameOf = {for (final m in myRoom.members) m.id: m.firstName};
        _bootLoading = false;
      });
      if (_roomId != null) _load();
    }();
  }

  @override
  void dispose() {
    CurrencyStore.symbol.removeListener(_currencyListener);
    super.dispose();
  }

// Month helper stays the same
  String _mon(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];

// Bills where *I* still owe money
  List<BillResponse> get _waitingForMe {
    final uid = _userId;
    if (uid == null) return const [];
    return _bills
        .where((b) =>
            b.shares.any((s) => s.userId == uid && s.status != 'CONFIRMED'))
        .toList();
  }

  List<BillResponse> get _toReview {
    final uid = _userId;
    if (uid == null) return const [];
    // bills I created that have at least one share marked as paid
    return _bills
        .where((b) =>
            b.paidByUserId == uid &&
            b.shares.any((s) => s.status == 'MARKED_PAID'))
        .toList();
  }

  Future<void> _notifyPayment(BillResponse bill) async {
    if (_roomId == null || _userId == null) return;
    try {
      await _billsApi.markSharePaid(_roomId!, bill.id, _userId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment notification sent ✅')),
      );
      await _load(); // refresh lists for both tabs
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn’t notify: $e')),
      );
    }
  }

  Future<void> _confirmShare(
      BillResponse bill, String debtorUserId, bool confirm) async {
    if (_roomId == null || _userId == null) return;
    try {
      await _billsApi.confirmShare(
        roomId: _roomId!,
        billId: bill.id,
        creatorUserId: _userId!,
        debtorUserId: debtorUserId,
        confirm: confirm,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                confirm ? 'Payment confirmed ✅' : 'Marked as not received')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn’t update: $e')),
      );
    }
  }

void _showDebtorActionsSheet(BillResponse bill) {
  final myShare = _myShareOn(bill);
  final alreadyNotified =
      myShare?.status == 'MARKED_PAID' || myShare?.status == 'CONFIRMED';

  showModalBottomSheet(
    context: context,
    useSafeArea: true,            
    isScrollControlled: true,     
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bill.name,
              style: const TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          if (bill.description.isNotEmpty)
            const SizedBox(height: 4),
          if (bill.description.isNotEmpty)
            Text(bill.description,
                style: const TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 14,
                    color: Color(0xFF666666))),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: alreadyNotified ? null : () => _notifyPayment(bill),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(alreadyNotified ? 'Already notified' : 'Notify payment'),
            ),
          ),
        ],
      ),
    ),
  );
}



  BillShare? _myShareOn(BillResponse b) {
    final uid = _userId;
    if (uid == null) return null;
    final i = b.shares.indexWhere((s) => s.userId == uid);
    return i == -1 ? null : b.shares[i];
  }

  Future<void> _load() async {
    if (_roomId == null) return;
    setState(() => _loadingBills = true);

    try {
      final bs = await _billsApi.listByRoom(_roomId!);

      // Compute how much *you* are owed across bills you created
      double owed = 0.0;
      for (final b in bs) {
        if (b.paidByUserId == _userId) {
          if (b.shares.isNotEmpty) {
            owed += b.shares
                .where((s) => s.status != 'CONFIRMED')
                .fold(0.0, (sum, s) => sum + s.amount);
          } else {
            //  amount already equals collect-from-others total
            owed += b.amount;
          }
        }
      }

      setState(() {
        _bills = bs;
        _youreOwed = owed;
        _loadingBills = false;
      });
    } catch (_) {
      setState(() => _loadingBills = false);
    }
  }

  @override
  Widget build(BuildContext context) {
      return ExitAppGuard(
    rootOnly: true, // prompt only if this page is at the root
    child: Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tab Bar
            _buildTabBar(),

            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: _selectedTabIndex == 0
                    ? _buildOverviewContent()
                    : _selectedTabIndex == 1
                        ? _buildContractsContent()
                        : _buildReviewContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_roomId == null || _userId == null)
            ? null // disable until ids are loaded
            : () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentPage(
                      selectedItems: const ['New Expense'],
                      roomId: _roomId!,
                      userId: _userId!,
                    ),
                  ),
                );
                if (created == true) _load(); // refresh bills list
              },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: AppColors.white, size: 32),
      ),
      bottomNavigationBar: const SharedBottomNav(currentIndex: 2),
    ),
  );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Image.asset(
            'assets/images/money.png',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Bills',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          Stack(
            children: [
              Image.asset('assets/images/money.png', width: 20, height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0
                      ? AppColors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Overview',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedTabIndex == 0
                          ? AppColors.white
                          : AppColors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1
                      ? AppColors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Contracts',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedTabIndex == 1
                          ? AppColors.white
                          : AppColors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 2;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 2
                      ? AppColors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Review',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedTabIndex == 2
                          ? AppColors.white
                          : AppColors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent() {
    if (_loadingBills) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = _waitingForMe;
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Nothing to pay right now",
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final b = items[i];
        final my = _myShareOn(b)!; // safe by filter
        final d = b.dueDate.toLocal();
        final date = '${_mon(d.month)}\n${d.day.toString().padLeft(2, '0')}';

        return InkWell(
          onTap: () => _showDebtorActionsSheet(b),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      date,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.name,
                          style: const TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        if (b.description.isNotEmpty)
                          Text(
                            b.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppFonts.darkerGrotesque,
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmt(my.amount),
                        style: const TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontFamilyFallback: _currencyFallback,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const Text(
                        'You owe',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Color(0xFF666666)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContractsContent() {
    return _buildBillsList(
      _bills.where((b) => b.isContract).toList(),
    );
  }

  Widget _buildBillsList(List<BillResponse> bills) {
    if (_loadingBills) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ));
    }
    if (bills.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nothing here yet',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      itemBuilder: (_, i) {
        final b = bills[i];
        final dt = b.dueDate;
        final dateStr =
            '${_mon(dt.month)}\n${dt.day.toString().padLeft(2, '0')}';
        final amount = _fmt(b.amount);
        final whoPaid =
            (b.paidByUserId == _userId) ? 'You paid' : 'Someone else paid';
        return _buildBillItem(
          id: b.id,
          date: dateStr,
          title: b.name,
          subtitle:
              b.description.isEmpty ? 'due ${dt.toLocal()}' : b.description,
          amount: amount,
          amountSubtitle: whoPaid,
          hasReceipt: false,
        );
      },
    );
  }

  Widget _buildReviewContent() {
    if (_loadingBills) {
      return const Center(child: CircularProgressIndicator());
    }
    final billsNeedingReview = _toReview;
    if (billsNeedingReview.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No payments to review yet',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
        ),
      );
    }

    final items = <({BillResponse bill, BillShare share})>[];
    for (final b in billsNeedingReview) {
      for (final s in b.shares.where((x) => x.status == 'MARKED_PAID')) {
        items.add((bill: b, share: s));
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final bill = items[i].bill;
        final share = items[i].share;
        final debtorName = _nameOf[share.userId] ?? 'Roommate';
        final dt = bill.dueDate.toLocal();
        final dateStr =
            '${_mon(dt.month)}\n${dt.day.toString().padLeft(2, '0')}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      dateStr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confirm payment',
                          style: TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          'from $debtorName • ${bill.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _fmt(share.amount),
                    style: const TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontFamilyFallback: _currencyFallback,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmShare(bill, share.userId, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmShare(bill, share.userId, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          fontFamily: AppFonts.darkerGrotesque,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillItem({
    required String id,
    required String date,
    required String title,
    required String subtitle,
    required String amount,
    required String amountSubtitle,
    required bool hasReceipt,
  }) {
    bool isExpanded = _expandedBills.contains(id);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedBills.remove(id);
                    } else {
                      _expandedBills.add(id);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        child: Text(
                          date,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppFonts.darkerGrotesque,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontFamily: AppFonts.darkerGrotesque,
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            if (hasReceipt)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Receipt attached',
                                    style: TextStyle(
                                      fontFamily: AppFonts.darkerGrotesque,
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amount,
                            style: const TextStyle(
                              fontFamily: AppFonts.darkerGrotesque,
                              fontFamilyFallback:
                                  _currencyFallback, 
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            amountSubtitle,
                            style: const TextStyle(
                              fontFamily: AppFonts.darkerGrotesque,
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF666666),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) _buildBillDropdown(id, title),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillDropdown(String billId, String billTitle) {
    return Container(
      margin: const EdgeInsets.only(left: 62, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Has this person paid you this invoice?',
            style: const TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bill Actions',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _expandedBills.remove(billId);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Marked as paid! 💰")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Mark as paid',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _expandedBills.remove(billId);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bill skipped 📝')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Maybe',
                  style: TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBillItem({
    required String date,
    required String title,
    required String subtitle,
    required String amount,
    required VoidCallback onYes,
    required VoidCallback onNo,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                child: Text(
                  date,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: AppFonts.darkerGrotesque,
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontFamily: AppFonts.darkerGrotesque,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onYes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Yes',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onNo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'No',
                    style: TextStyle(
                      fontFamily: AppFonts.darkerGrotesque,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractItem({
    required String title,
    required String subtitle,
    required String amount,
    required String icon,
    required String nextDue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Text(
                  nextDue,
                  style: const TextStyle(
                    fontFamily: AppFonts.darkerGrotesque,
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF666666),
            size: 16,
          ),
        ],
      ),
    );
  }
}
