
const Map<String,String> kAssetToIconEnum = {
  'cleaning.png'       : 'CLEANING',
  'bathroom_icon.png'  : 'BATHROOM',
  'watering_can.png'   : 'WATERING',
  'glove.png'          : 'GLOVES',
  'spraybottle.png'    : 'SPRAY',
  'shopping_cart.png'  : 'SHOPPING',
  'money.png'          : 'MONEY',
  'pizza.png'          : 'PIZZA',
};

String? iconEnumFromAsset(String asset) => kAssetToIconEnum[asset];


String assetFromIconEnum(String? iconId) {
  final entry = kAssetToIconEnum.entries.firstWhere(
    (e) => e.value == iconId, orElse: () => const MapEntry('cleaning.png','CLEANING'));
  return entry.key;
}
