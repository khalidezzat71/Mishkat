/// القوالب الهيكلية العشرة — تغيّر التنقل والبنية لا الألوان فقط.
enum NavigationStyle { bottomBar, topTabs, floatingDock, radial, none }

class LayoutDefinition {
  LayoutDefinition({
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
  LayoutDefinition(
    id: 1,
    key: 'layoutClassicMushaf',
    navigationStyle: NavigationStyle.bottomBar,
    density: 0,
  ),
  LayoutDefinition(
    id: 2,
    key: 'layoutBento',
    navigationStyle: NavigationStyle.bottomBar,
    density: 0,
  ),
  LayoutDefinition(
    id: 3,
    key: 'layoutKalaRadial',
    navigationStyle: NavigationStyle.floatingDock,
    density: 0,
  ),
  LayoutDefinition(
    id: 4,
    key: 'layoutTahajjudOled',
    navigationStyle: NavigationStyle.bottomBar,
    density: 0,
  ),
  LayoutDefinition(
    id: 5,
    key: 'layoutMihrabGlass',
    navigationStyle: NavigationStyle.bottomBar,
    density: 0,
  ),
  LayoutDefinition(
    id: 6,
    key: 'layoutPillarsZen',
    navigationStyle: NavigationStyle.none,
    density: 0,
  ),
  LayoutDefinition(
    id: 7,
    key: 'layoutQuranCompact',
    navigationStyle: NavigationStyle.topTabs,
    density: 1,
  ),
  LayoutDefinition(
    id: 8,
    key: 'layoutTarteelEditorial',
    navigationStyle: NavigationStyle.topTabs,
    density: 0,
  ),
  LayoutDefinition(
    id: 9,
    key: 'layoutNusukAccessible',
    navigationStyle: NavigationStyle.bottomBar,
    density: 2,
  ),
  LayoutDefinition(
    id: 10,
    key: 'layoutMaterialYou',
    navigationStyle: NavigationStyle.bottomBar,
    density: 0,
  ),
];
