import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'shared_bottom_nav.dart';
import '../api/client.dart';
import '../api/auth_api.dart';
import '../api/room_api.dart';
import '../api/shopping_api.dart';
import 'payment_page.dart';

class ShoppingListPage extends StatefulWidget {
  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  late final ApiClient _api;
  late final ShoppingApi _shopping;
  String? _roomId, _userId, _userName;
  bool _bootLoading = true;

  final Map<String, List<ShoppingItemDto>> _byList = {};
  String? _selectedList;
  final Set<String> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    _api = ApiClient.dev();
    _shopping = ShoppingApi(_api);

    () async {
      final me = await AuthApi(_api).getMe();
      final myRoom = await RoomApi(_api).getMyRoom();
      final roomId = myRoom.room?.id;

      List<ShoppingItemDto> items = [];
      if (roomId != null) {
        items = await _shopping.list(roomId);
      }
      _byList
        ..clear()
        ..addAll(_groupByList(items));

      setState(() {
        _userId = me.id;
        _userName = me.firstName;
        _roomId = roomId;
        _selectedList = _byList.keys.isNotEmpty ? _byList.keys.first : 'General';
        _bootLoading = false;
      });
    }();
  }

  Map<String, List<ShoppingItemDto>> _groupByList(List<ShoppingItemDto> items) {
    final m = <String, List<ShoppingItemDto>>{};
    for (final it in items) {
      (m[it.listName] ??= []).add(it);
    }
    return m;
  }

  Future<void> _showItemActionsDialog(ShoppingItemDto it) async {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.only(top: 100),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), 
              topRight: Radius.circular(20)
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(it.itemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFonts.darkerGrotesque)),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 16,
                          fontFamily: AppFonts.darkerGrotesque),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_userId == null || _userName == null) return;
                          try {
                            final updated = await _shopping.markBought(
                              roomId: _roomId!,
                              itemId: it.id,
                              boughtByUserId: _userId!,
                              boughtByName: _userName!,
                            );
                            setState(() {
                              final listItems = _byList[it.listName] ?? [];
                              final idx = listItems.indexWhere((x) => x.id == it.id);
                              if (idx >= 0) listItems[idx] = updated;
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Marked as bought!')),
                            );
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not mark bought')),
                            );
                          }
                        },
                        icon: const Icon(Icons.shopping_bag, color: Colors.white),
                        label: const Text(
                          'Mark as Bought',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: AppFonts.darkerGrotesque
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await _shopping.delete(it.id, _roomId!);
                            setState(() {
                              _byList[it.listName]?.removeWhere((x) => x.id == it.id);
                              _selectedItemIds.remove(it.id);
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Item removed')),
                            );
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not remove item')),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text(
                          'Remove',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: AppFonts.darkerGrotesque
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)
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
      ),
    );
  }

  List<ShoppingItemDto> _recentlyBought() {
    return _byList.values
        .expand((l) => l)
        .where((it) => it.isBought == true)
        .toList();
  }

  Future<String?> _promptForListName(BuildContext ctx) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('New List'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'e.g., Grocery, Yard, Toiletries'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel')
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Add')
          ),
        ],
      ),
    );
  }

  final TextEditingController _makeEntryController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();

  Future<void> _addItemToCurrentList() async {
    final itemName = _makeEntryController.text.trim();
    if (itemName.isEmpty || _roomId == null || _userId == null || _userName == null) return;

    final listName = _selectedList ?? 'General';

    try {
      final created = await _shopping.create(
        roomId: _roomId!,
        listName: listName,
        itemName: itemName,
        addedByUserId: _userId!,
        addedByName: _userName!,
      );
      setState(() {
        (_byList[listName] ??= []).add(created);
        _makeEntryController.clear();
        _infoController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item added!'),
          backgroundColor: AppColors.primaryBlue
        ),
      );
    } catch (e, st) {
      debugPrint('Create failed: $e');
      debugPrint('Stack: $st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add item')),
      );
    }
  }

  Widget _buildSelectedListItems() {
    final ln = _selectedList ?? 'General';
    final items = _byList[ln] ?? const <ShoppingItemDto>[];

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No items in "$ln" yet.',
            style: const TextStyle(fontSize: 14)),
      );
    }

    return Column(
      children: [
        for (final it in items) _buildItemRow(it),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20), 
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10, right: 20,
            child: Image.asset('assets/images/star.png', width: 34, height: 34),
          ),
          Positioned(
            top: 40, right: 80,
            child: Image.asset('assets/images/money.png', width: 34, height: 34),
          ),
          Positioned(
            top: 20, left: 100,
            child: Image.asset('assets/images/star.png', width: 34, height: 34),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Colors.white),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Image.asset('assets/images/shopping_cart.png', width: 24, height: 24),
                      const SizedBox(width: 4),
                      const Text(
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
                  const Spacer(),
                  const Icon(Icons.sort, color: Colors.white),
                  const SizedBox(width: 8),
                  const Icon(Icons.share, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 6),
              _buildTabs(),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _makeEntryController,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 14, 
                          fontFamily: AppFonts.darkerGrotesque,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addItemToCurrentList(),
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
                    const Icon(Icons.menu, color: Colors.white, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _infoController,
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 12, 
                    fontFamily: AppFonts.darkerGrotesque,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addItemToCurrentList(),
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
    );
  }

  Widget _buildItemRow(ShoppingItemDto it) {
    final selected = _selectedItemIds.contains(it.id);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedItemIds.remove(it.id);
                  } else {
                    _selectedItemIds.add(it.id);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to Payment'),
                        duration: Duration(milliseconds: 800),
                      ),
                    );
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryYellow
                      : AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Image.asset('assets/images/shopping_cart.png',
                        width: 20, height: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        it.itemName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: AppFonts.darkerGrotesque,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showItemActionsDialog(it),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _selectedItemNames() {
    final names = <String>[];
    for (final list in _byList.values) {
      for (final it in list) {
        if (_selectedItemIds.contains(it.id)) {
          names.add(it.itemName);
        }
      }
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final rb = _recentlyBought();
    if (_bootLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSelectedListItems(),
                    const SizedBox(height: 24),
                    if (rb.isNotEmpty) ...[
                      const Padding(
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
                      const SizedBox(height: 8),
                      ...rb.map((it) => Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            padding: const EdgeInsets.all(16),
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    it.itemName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFonts.darkerGrotesque,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Builder(builder: (context) {
  final ln = _selectedList ?? 'General';
  final items = _byList[ln] ?? const <ShoppingItemDto>[];
  if (items.isEmpty || _roomId == null || _userId == null) {
    return const SizedBox.shrink();
  }

  return SafeArea(
    minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                selectedItems: _currentListNames(),
                roomId: _roomId!,
                userId: _userId!,
              ),
            ),
          );

          if (ok == true && mounted) {
            setState(() {
              // clear the current list visually
              _byList[ln] = [];
              _selectedItemIds.clear(); // in case you had any selection
            });

        
             for (final it in items) {
             await _shopping.delete(it.id, _roomId!);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invoiced "$ln" (${items.length}) items')),
            );
          }
        },
        icon: const Icon(Icons.payments),
        label: Text(
          'Invoice "$ln" (${items.length})',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: AppFonts.darkerGrotesque,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
      ),
    ),
  );
}),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: const SharedBottomNav(currentIndex: 1),
    );
  }


    List<ShoppingItemDto> _currentListItems() {
  final ln = _selectedList ?? 'General';
  return List<ShoppingItemDto>.from(_byList[ln] ?? const <ShoppingItemDto>[]);
}

List<String> _currentListNames() {
  return _currentListItems().map((e) => e.itemName).toList();
}

  Widget _buildTabs() {
    final keys = _byList.keys.toList()..sort();
    if (keys.isEmpty) keys.add('General');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final k in keys) ...[
            GestureDetector(
              onTap: () => setState(() => _selectedList = k),
              child: _buildTab(k, _selectedList == k),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () async {
              final name = await _promptForListName(context);
              if (name == null || name.trim().isEmpty) return;
              setState(() {
                _byList.putIfAbsent(name.trim(), () => []);
                _selectedList = name.trim();
              });
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primaryBlue, size: 18),
            ),
          ),
        ],
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
        color: isSelected
            ? AppColors.primaryYellow
            : AppColors.primaryYellow.withOpacity(0.3),
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
