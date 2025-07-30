import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

class ShoppingListPage extends StatefulWidget {
  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  String selectedCategory = 'Grocery';
  
  Map<String, List<ShoppingList>> folders = {
    'Grocery': [
      ShoppingList('Oranges', ['Oranges'], [false]),
      ShoppingList('Carrots', ['Carrots'], [false]),
      ShoppingList('Broccoli', ['Broccoli'], [false]),
    ],
    'Toilet stuff': [
      ShoppingList('Bathroom Essentials', ['Toilet Paper', 'Soap'], [false, false]),
    ],
    'Yard stuff': [
      ShoppingList('Garden Tools', ['Watering Can', 'Gloves'], [false, false]),
    ],
  };

  List<ShoppingList> recentlyBought = [
    ShoppingList('Hot Chocolate', ['Hot Chocolate'], [true]),
  ];

  TextEditingController _infoController = TextEditingController();
  TextEditingController _makeEntryController = TextEditingController();

  void _addItemToCurrentList() {
    String itemName = _makeEntryController.text.trim();
    String itemInfo = _infoController.text.trim();
    
    if (itemName.isEmpty) {
      return; // Cannot add if make entry is empty
    }
    
    setState(() {
      // Create new shopping list item
      ShoppingList newItem = ShoppingList(itemName, [itemName], [false]);
      
      // Add to current selected category
      if (folders[selectedCategory] != null) {
        folders[selectedCategory]!.add(newItem);
      }
      
      // Clear the text fields
      _makeEntryController.clear();
      _infoController.clear();
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName added to $selectedCategory!'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  void _showListDetailDialog(String folderName, ShoppingList shoppingList) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.only(top: 100),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        shoppingList.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFonts.darkerGrotesque,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFonts.darkerGrotesque,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Info text field
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: AppColors.primaryBlue,
                  child: TextField(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: AppFonts.darkerGrotesque,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Info, quantity, description',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontFamily: AppFonts.darkerGrotesque,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                
                // Tags section
                Container(
                  padding: EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag('Kg'),
                      _buildTag('1'),
                      _buildTag('2'),
                      _buildTag('3'),
                      _buildTag('Ltr'),
                      _buildTag('Pcs'),
                      _buildTag('Cm'),
                      _buildTag('Gm'),
                      _buildTag('Ml'),
                      _buildTag('Dozen'),
                      _buildTag('Meter'),
                    ],
                  ),
                ),
                
                // Action buttons
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Mark as bought logic
                            setState(() {
                              // Move to recently bought
                              recentlyBought.add(ShoppingList(
                                shoppingList.name, 
                                shoppingList.items, 
                                shoppingList.items.map((e) => true).toList()
                              ));
                              // Remove from current folder
                              folders[folderName]!.remove(shoppingList);
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${shoppingList.name} marked as bought!')),
                            );
                          },
                          icon: Icon(Icons.shopping_bag, color: Colors.white),
                          label: Text(
                            'Bought ${shoppingList.name}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: AppFonts.darkerGrotesque,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              folders[folderName]!.remove(shoppingList);
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${shoppingList.name} removed!')),
                            );
                          },
                          icon: Icon(Icons.delete, color: Colors.white),
                          label: Text(
                            'Remove ${shoppingList.name}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: AppFonts.darkerGrotesque,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: AppFonts.darkerGrotesque,
        ),
      ),
    );
  }

  Widget _buildFolderSection(List<ShoppingList> lists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Folder header with + button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                selectedCategory,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppFonts.darkerGrotesque,
                  color: AppColors.black,
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // Add new list to folder
                  setState(() {
                    lists.add(ShoppingList('New List', [], []));
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Vertical list of shopping items
        ...lists.map((list) => Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: GestureDetector(
            onTap: () => _showListDetailDialog(selectedCategory, list),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/shopping_cart.png',
                    width: 20,
                    height: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      list.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.darkerGrotesque,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        )).toList(),
      ],
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
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: 10,
                    right: 20,
                    child: Image.asset(
                      'assets/images/star.png',
                      width: 34,
                      height: 34,
                 
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 80,
                    child: Image.asset(
                      'assets/images/money.png',
                      width: 34,
                      height: 34,
                   
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 100,
                    child: Image.asset(
                      'assets/images/star.png',
                        width: 34,
                      height: 34,
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings, color: Colors.white),
                          SizedBox(width: 8),
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/shopping_cart.png',
                                width: 24,
                                height: 24,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Shopping List',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppFonts.boulder,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Icon(Icons.sort, color: Colors.white),
                          SizedBox(width: 8),
                          Icon(Icons.share, color: Colors.white),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Tabs (Clickable Category Folders)
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => selectedCategory = 'Grocery'),
                            child: _buildTab('Grocery', selectedCategory == 'Grocery'),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => selectedCategory = 'Toilet stuff'),
                            child: _buildTab('Toilet stuff', selectedCategory == 'Toilet stuff'),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => selectedCategory = 'Yard stuff'),
                            child: _buildTab('Yard stuff', selectedCategory == 'Yard stuff'),
                          ),
                          Spacer(),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.question_mark,
                              color: AppColors.primaryBlue,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Search bar (Make entry)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _makeEntryController,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: AppFonts.darkerGrotesque,
                                ),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (value) {
                                  _addItemToCurrentList();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Make entry...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontFamily: AppFonts.darkerGrotesque,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Icon(Icons.menu, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      
                      // Info text field
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _infoController,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: AppFonts.darkerGrotesque,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (value) {
                            _addItemToCurrentList();
                          },
                          decoration: InputDecoration(
                            hintText: 'Info, quantity, description',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontFamily: AppFonts.darkerGrotesque,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Category tags
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryTag('All', true),
                  _buildCategoryTag('Beverages', false),
                  _buildCategoryTag('Groceries', false),
                  _buildCategoryTag('Meat', false),
                  _buildCategoryTag('Vegetables', false),
                  _buildCategoryTag('Fruit', false),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    
                    // Current selected folder content
                    _buildFolderSection(folders[selectedCategory] ?? []),
                    
                    SizedBox(height: 24),
                    
                    // Recently Bought
                    if (recentlyBought.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Recently Bought',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppFonts.darkerGrotesque,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      ...recentlyBought.map((item) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/shopping_cart.png',
                              width: 20,
                              height: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFonts.darkerGrotesque,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white, size: 20),
                          ],
                        ),
                      )).toList(),
                    ],
                    
                    SizedBox(height: 100), // Bottom padding
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
              color: AppColors.primaryBlue,
            ),
            Icon(Icons.camera_alt, color: Colors.grey[600]),
            Icon(Icons.chat, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: AppFonts.darkerGrotesque,
        ),
      ),
    );
  }

  Widget _buildCategoryTag(String text, bool isSelected) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryYellow : AppColors.primaryYellow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.black,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: AppFonts.darkerGrotesque,
        ),
      ),
    );
  }
}

class ShoppingList {
  String name;
  List<String> items;
  List<bool> isCompleted;

  ShoppingList(this.name, this.items, this.isCompleted);
}

/** 
 * TODO : marking as paid and distributing bills amongst housemates
 * An invoice starts to generate at the bottom of the screen
 * when clicked (assuming done) it then asks tothe total amount, attach photo
 * Lisrt of what was biought , who originally paid, and manually sharing the prices 
 * it iniotially automatically evenly splis it amongst the number of housemates , then you can edit the prices  then you can create invoice payment 
 * Check Flatify again
 * 
*/


