import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../api/client.dart';
import '../api/room_api.dart';
import '../utils/url_utils.dart';
import '../api/bills_api.dart';
import '../api/bills_models.dart';
import '../widgets/currency_picker_bottom_sheet.dart';
import '../state/currency_store.dart';

const _currencyFallback = ['Noto Sans Symbols 2', 'Noto Sans', 'Roboto'];


class PaymentPage extends StatefulWidget {
  final List<String> selectedItems;
  final String roomId;
  final String userId;

  const PaymentPage({
    Key? key,
    required this.selectedItems,
    required this.roomId,
    required this.userId,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  TextEditingController _priceController = TextEditingController();
  double totalAmount = 0.0;
  bool hasPhoto = false;

  String get _cur => CurrencyStore.symbol.value;
  String _fmt(num v) => '$_cur${v.toStringAsFixed(2)}';
  String _sanitize(String s) => s.replaceAll(RegExp(r'[^\d.]'), '');

  late final ApiClient _client;
  late final RoomApi _roomApi;
  late final BillsApi _billsApi;
  List<Roommate> roommates = [];
  bool _loadingMembers = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isContract = false;

  late final VoidCallback _currencyListener;

  @override
  void initState() {
    super.initState();
    _client = ApiClient.dev();
    _roomApi = RoomApi(_client);
    _billsApi = BillsApi(_client);

    _priceController.text = '${CurrencyStore.symbol.value} 0.00';

    _currencyListener = () {
      if (!mounted) return;
      final n = _sanitize(_priceController.text);
      final next = '${CurrencyStore.symbol.value} ${n.isEmpty ? '0.00' : n}';
      _priceController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      setState(() {});
    };

    CurrencyStore.symbol.addListener(_currencyListener);

    // sensible defaults
    _titleController.text = widget.selectedItems.isNotEmpty
        ? widget.selectedItems.first
        : 'Shared Expense';
    _descController.text = widget.selectedItems.join(', ');

    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final ms = await _roomApi.getMembers(widget.roomId);
    setState(() {
      roommates = ms
          .map((m) => Roommate(
                id: m.id,
                name: m.firstName,
                avatar: m.avatarImageUrl ?? 'assets/images/avatar_1.png',
                isPayer: m.id == widget.userId,
              ))
          .toList();
      _loadingMembers = false;
    });
  }

  Future<void> _createInvoice() async {
    final text = _sanitize(_priceController.text);

    final price = double.tryParse(_sanitize(_priceController.text)) ?? 0.0;
    if (price <= 0 || roommates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount and load members')),
      );
      return;
    }

    _calculateSplit();

    final payer =
        roommates.firstWhere((r) => r.isPayer, orElse: () => roommates.first);
    final others = roommates.where((r) => !r.isPayer).map((r) => r.id).toList();

    final totalRoommates = roommates.length;
    final perHead = price / totalRoommates;
    final amountToCollect = perHead * others.length;

    final name = _titleController.text.trim().isEmpty
        ? 'Shared Expense'
        : _titleController.text.trim();

    final desc = _descController.text.trim().isEmpty
        ? widget.selectedItems.join(', ')
        : _descController.text.trim();

    final req = BillCreateReq(
      roomId: widget.roomId,
      name: name,
      description: desc,
      amount: amountToCollect,
      dueDate: DateTime.now().toUtc().add(const Duration(days: 7)),
      paidByUserId: widget.userId,
      splitAmongUserIds: others,
      isContract: _isContract,
    );

    try {
      await _billsApi.create(widget.roomId, req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invoice created and sent ✅")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create invoice: $e')),
      );
    }
  }

  ImageProvider _avatarProvider(String path) {
    if (path.startsWith('http') || path.startsWith('/')) {
      return NetworkImage(absoluteUrl(path));
    }
    return AssetImage(path);
  }

  // Mock roommates data - in real app, this would come from backend

  void _calculateSplit() {
    final text = _sanitize(_priceController.text);
    final price = double.tryParse(_sanitize(_priceController.text)) ?? 0.0;

    if (price == 0.0) {
      setState(() {
        totalAmount = 0.0;
        for (var roommate in roommates) {
          roommate.amount = 0.0;
        }
      });
      return;
    }

    setState(() {
      totalAmount = price;

      int totalRoommates = roommates.length;
      Roommate payer = roommates.firstWhere((r) => r.isPayer);
      int othersCount = totalRoommates - 1;

      double sharePerPerson = price / totalRoommates;

      for (var roommate in roommates) {
        if (roommate.isPayer) {
          // The payer "pays" the full amount, but is owed by others
          roommate.amount = price - sharePerPerson;
        } else {
          roommate.amount = sharePerPerson;
        }
      }
    });
  }

  void _updateRoommateAmount(int index, double newAmount) {
    setState(() {
      roommates[index].amount = newAmount;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Photo Permission Required'),
          content:
              Text('This app needs access to your photos to upload receipts.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInvoiceItems() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Invoice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFonts.darkerGrotesque,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.selectedItems.length}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppFonts.darkerGrotesque,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...widget.selectedItems
              .map((item) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          item,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: AppFonts.darkerGrotesque,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildPaidBySection() {
    Roommate payer = roommates.firstWhere((r) => r.isPayer);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paid By',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.darkerGrotesque,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: _avatarProvider(payer.avatar),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    payer.name,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFonts.darkerGrotesque,
                    ),
                  ),
                ),
                Text(
                  _fmt(payer.amount),
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.darkerGrotesque,
                    fontFamilyFallback: _currencyFallback,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareAmongstSection() {
    // Check if we need to use grid layout (more than 4 people excluding payer)
    List<Roommate> nonPayers = roommates.where((r) => !r.isPayer).toList();
    bool useGridLayout = nonPayers.length > 4;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Amongst',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.darkerGrotesque,
            ),
          ),
          SizedBox(height: 16),
          useGridLayout
              ? _buildGridLayout(nonPayers)
              : _buildListLayout(nonPayers),
        ],
      ),
    );
  }

  Widget _buildCreateInvoiceButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _createInvoice,
          icon: Icon(Icons.receipt_long),
          label: Text(
            'Create Invoice',
            style: TextStyle(
              fontFamily: AppFonts.darkerGrotesque,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryYellow,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListLayout(List<Roommate> nonPayers) {
    return Column(
      children: nonPayers.asMap().entries.map((entry) {
        int index = entry.key;
        Roommate roommate = entry.value;
        int originalIndex = roommates.indexOf(roommate);

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: _avatarProvider(roommate.avatar),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  roommate.name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.darkerGrotesque,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 80,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryBlue),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            _fmt(roommate.amount),
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFonts.darkerGrotesque,
                              fontFamilyFallback: _currencyFallback,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Owes ${roommates.firstWhere((r) => r.isPayer).name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.darkerGrotesque,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridLayout(List<Roommate> nonPayers) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.5,
    ),
    itemCount: nonPayers.length,
    itemBuilder: (context, index) {
      final roommate = nonPayers[index];
      final originalIndex = roommates.indexOf(roommate);

      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: _avatarProvider(roommate.avatar),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roommate.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFonts.darkerGrotesque,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 24,
                    child: TextFormField(
                      key: ValueKey(
                        '${roommate.id}-${CurrencyStore.symbol.value}-${roommate.amount.toStringAsFixed(2)}',
                      ), // rebuild on symbol/amount change
                      initialValue: _fmt(roommate.amount),
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFonts.darkerGrotesque,
                        fontFamilyFallback: _currencyFallback,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // allow digits, dot and spaces (symbol comes from formatter)
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\.\s]')),
                        _CurrencyTextInputFormatter(
                          () => CurrencyStore.symbol.value,
                        ),
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide:
                              const BorderSide(color: AppColors.primaryBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                      ),
                      onChanged: (value) {
                        final n = double.tryParse(_sanitize(value)) ?? 0.0;
                        _updateRoommateAmount(originalIndex, n);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    if (_loadingMembers) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: 10,
                    right: 20,
                    child: Image.asset(
                      'assets/images/star.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  Positioned(
                    top: 30,
                    right: 60,
                    child: Image.asset(
                      'assets/images/money.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 80,
                    child: Image.asset(
                      'assets/images/star.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              children: [
                                Icon(Icons.refresh,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: AppFonts.darkerGrotesque,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppFonts.boulder,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _calculateSplit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Split',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFonts.darkerGrotesque,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Amount input
                      TextField(
                        controller: _priceController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                          fontFamily: AppFonts.darkerGrotesque,
                          fontFamilyFallback: _currencyFallback,
                        ),
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          // Allow digits, dot and spaces (no hardcoded $)
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\.\s]')),
                          _CurrencyTextInputFormatter(
                              () => CurrencyStore.symbol.value),
                        ],
                        decoration: InputDecoration(
                          hintText: '$_cur 0.00', // ← dynamic hint
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                            fontFamily: AppFonts.darkerGrotesque,
                          ),
                          border: InputBorder.none,
                        ),
                      ),

                      SizedBox(height: 20),

                      // Bill name
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: AppFonts.darkerGrotesque,
                          ),
                          decoration: InputDecoration(
                            icon: const Icon(Icons.edit,
                                color: Colors.white, size: 20),
                            hintText: 'Bill name (e.g. Water bill)',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontFamily: AppFonts.darkerGrotesque,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

// Description (multiline)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _descController,
                          maxLines: 3,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: AppFonts.darkerGrotesque,
                          ),
                          decoration: InputDecoration(
                            icon: const Icon(Icons.notes,
                                color: Colors.white, size: 20),
                            hintText: 'Description (optional)',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontFamily: AppFonts.darkerGrotesque,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

// Save to Contracts toggle
                      InkWell(
                        onTap: () => setState(() => _isContract = !_isContract),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isContract,
                              onChanged: (v) =>
                                  setState(() => _isContract = v ?? false),
                              activeColor: AppColors.primaryYellow,
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Save to Contracts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: AppFonts.darkerGrotesque,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Attach Photo
                      GestureDetector(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Text(
                                hasPhoto ? 'Photo Attached' : 'Upload Photo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: AppFonts.darkerGrotesque,
                                ),
                              ),
                              if (hasPhoto) ...[
                                Spacer(),
                                Icon(Icons.check_circle,
                                    color: AppColors.primaryYellow, size: 20),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    _buildInvoiceItems(),
                    _buildPaidBySection(),
                    _buildShareAmongstSection(),
                    _buildCreateInvoiceButton(),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.home, color: Colors.grey[600]),
            Icon(Icons.person, color: Colors.grey[600]),
            Image.asset(
              'assets/images/shopping_cart.png',
              width: 24,
              height: 24,
              color: Colors.grey[600],
            ),
            Image.asset(
              'assets/images/money.png',
              width: 24,
              height: 24,
              color: AppColors.primaryBlue,
            ),
            Icon(Icons.chat, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    CurrencyStore.symbol.removeListener(_currencyListener); // 👈 important
    _priceController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}

class Roommate {
  final String id;
  final String name;
  final String avatar;
  double amount;
  final bool isPayer;

  Roommate({
    required this.id,
    required this.name,
    required this.avatar,
    this.amount = 0.0,
    this.isPayer = false,
  });
}

class _CurrencyTextInputFormatter extends TextInputFormatter {
  final String Function() symbolProvider;
  _CurrencyTextInputFormatter(this.symbolProvider);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sym = symbolProvider();
    final numericText = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');
    if ('.'.allMatches(numericText).length > 1) return oldValue;

    final next = numericText.isEmpty ? '$sym 0.00' : '$sym $numericText';
    return TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }
}
