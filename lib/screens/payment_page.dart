import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class PaymentPage extends StatefulWidget {
  final List<String> selectedItems;
  
  const PaymentPage({Key? key, required this.selectedItems}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  TextEditingController _priceController = TextEditingController();
  double totalAmount = 0.0;
  bool hasPhoto = false;
  
  
  // Mock roommates data - in real app, this would come from backend
  List<Roommate> roommates = [
  Roommate(name: 'Tola', avatar: 'assets/images/avatar_1.png', amount: 0.0, isPayer: true),
  Roommate(name: 'Sade', avatar: 'assets/images/avatar_2.png', amount: 0.0),
  Roommate(name: 'Kemi', avatar: 'assets/images/avatar_3.png', amount: 0.0),
  Roommate(name: 'Bola', avatar: 'assets/images/avatar_4.png', amount: 0.0),
];


  @override
  void initState() {
    super.initState();
    _priceController.text = '\$ 0.00';
    
    
  }

void _calculateSplit() {
  String text = _priceController.text.replaceAll('\$', '').replaceAll(' ', '');
  double price = double.tryParse(text) ?? 0.0;

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
          content: Text('This app needs access to your photos to upload receipts.'),
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
          ...widget.selectedItems.map((item) => Padding(
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
          )).toList(),
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
                  backgroundImage: AssetImage(payer.avatar),
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
                  '\$${payer.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.darkerGrotesque,
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
          useGridLayout ? _buildGridLayout(nonPayers) : _buildListLayout(nonPayers),
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


Future<void> _createInvoice() async {
  Roommate payer = roommates.firstWhere((r) => r.isPayer);
  DateTime now = DateTime.now();

  Map<String, dynamic> invoice = {
    "title": "Shared Expense",
    "total": totalAmount,
    "paidBy": payer.name,
    "date": now.toIso8601String(),
    "splits": roommates
        .where((r) => !r.isPayer)
        .map((r) => {
              "name": r.name,
              "owes": r.amount,
            })
        .toList(),
  };

  // Save to database or print for now
  print(invoice); 

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Invoice created and sent to housemates' Bills")),
  );

   Navigator.pop(context, true);

 
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
                backgroundImage: AssetImage(roommate.avatar),
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
          '\$${roommate.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: AppFonts.darkerGrotesque,
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
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: nonPayers.length,
      itemBuilder: (context, index) {
        Roommate roommate = nonPayers[index];
        int originalIndex = roommates.indexOf(roommate);
        
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: AssetImage(roommate.avatar),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roommate.name,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.darkerGrotesque,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Container(
                      height: 24,
                      child: TextFormField(
                        initialValue: '\$${roommate.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFonts.darkerGrotesque,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: AppColors.primaryBlue),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        ),
                        onChanged: (value) {
                          double newAmount = double.tryParse(value.replaceAll('\$', '')) ?? 0.0;
                          _updateRoommateAmount(originalIndex, newAmount);
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
                                Icon(Icons.refresh, color: Colors.white, size: 20),
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
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      Container(
                        width: double.infinity,
                        child: TextField(
                          controller: _priceController,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                            fontFamily: AppFonts.darkerGrotesque,
                          ),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d\.\$\s]')),
                            _DollarTextInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            hintText: '\$ 0.00',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              fontFamily: AppFonts.darkerGrotesque,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
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
                              Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
                                Icon(Icons.check_circle, color: AppColors.primaryYellow, size: 20),
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
    _priceController.dispose();
    super.dispose();
  }
}

class Roommate {
  final String name;
  final String avatar;
  double amount;
  final bool isPayer;

  Roommate({
    required this.name,
    required this.avatar,
    this.amount = 0.0,
    this.isPayer = false,
  });
}

class _DollarTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    // Strip out any non-numeric characters (except the dot)
    String numericText = newText.replaceAll(RegExp(r'[^\d.]'), '');

    // Prevent multiple dots
    if ('.'.allMatches(numericText).length > 1) {
      return oldValue;
    }

    if (numericText.isEmpty) {
      return TextEditingValue(
        text: '\$ ',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    return TextEditingValue(
      text: '\$ $numericText',
      selection: TextSelection.collapsed(offset: '\$ $numericText'.length),
    );
  }
}
