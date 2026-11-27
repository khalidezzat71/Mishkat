/// القوالب الهيكلية العشرة — تغيّر التنقل والبنية لا الألوان فقط.
enum NavigationStyle { bottomBar, topTabs, floatingDock, radial, none }

class LayoutDefinition {
  const LayoutDefinition({
    required this.id,
    required this.key,
    required this.navigationStyle,
    required this.density,
  });

  final int id;
  final String key;
  final NavigationStyle navigationStyle;

  /// 0 مريح، 1 مكثّف، 2 كبير لكبار السن.
  final int density;
}

const List<LayoutDefinition> kLayouts = [
  LayoutDefinition(1, 'layoutClassicMushaf', NavigationStyle.bottomBar, 0),
  LayoutDefinition(2, 'layoutBento', NavigationStyle.bottomBar, 0),
  LayoutDefinition(3, 'layoutKalaRadial', NavigationStyle.floatingDock, 0),
  LayoutDefinition(4, 'layoutTahajjudOled', NavigationStyle.bottomBar, 0),
  LayoutDefinition(5, 'layoutMihrabGlass', NavigationStyle.bottomBar, 0),
  LayoutDefinition(6, 'layoutPillarsZen', NavigationStyle.none, 0),
  LayoutDefinition(7, 'layoutQuranCompact', NavigationStyle.topTabs, 1),
  LayoutDefinition(8, 'layoutTarteelEditorial', NavigationStyle.topTabs, 0),
  LayoutDefinition(9, 'layoutNusukAccessible', NavigationStyle.bottomBar, 2),
  LayoutDefinition(10, 'layoutMaterialYou', NavigationStyle.bottomBar, 0),
];
