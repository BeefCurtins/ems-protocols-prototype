import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/protocol.dart';
import 'data/general.dart';
import 'data/medications.dart';
import 'data/procedures.dart';
import 'data/cardiac.dart';
import 'data/respiratory.dart';
import 'data/medical.dart';
import 'data/trauma.dart';
import 'data/obgyn.dart';
import 'data/pediatric.dart';
import 'data/forms.dart';
import 'data/transfer_protocol.dart';

late final List<Protocol> allProtocols = [
  ...general_protocols,
  ...medications_protocols,
  ...procedures_protocols,
  ...cardiac_protocols,
  ...respiratory_protocols,
  ...medical_protocols,
  ...trauma_protocols,
  ...obgyn_protocols,
  ...pediatric_protocols,
  ...forms_protocols,
];

final Set<String> favorites = <String>{};

void main() => runApp(const EMSProtocolsApp());

class EMSProtocolsApp extends StatefulWidget {
  const EMSProtocolsApp({super.key});

  @override
  State<EMSProtocolsApp> createState() => _EMSProtocolsAppState();
}

class _EMSProtocolsAppState extends State<EMSProtocolsApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _themeMode = prefs.getBool('dark_mode') ?? true
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() {
      _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', enabled);
  }

  @override
  Widget build(BuildContext context) {
    const baxterBlue = Color(0xFF025EFF);

    return MaterialApp(
      title: 'Baxter Health EMS',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: baxterBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FA),
          foregroundColor: Color(0xFF2F3338),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: Color(0x22025EFF),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: baxterBlue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A111A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1018),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF17222E),
          elevation: 7,
          shadowColor: Colors.black.withValues(alpha: 0.58),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.055)),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF182431),
          hintStyle: const TextStyle(color: Color(0xFF9EADC0)),
          prefixIconColor: const Color(0xFFB9C8DA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide(color: Color(0x553B8FFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide(color: Color(0x553B8FFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide(color: Color(0xFF0A83FF), width: 1.4),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 78,
          backgroundColor: const Color(0xFF080D13),
          indicatorColor: baxterBlue.withValues(alpha: 0.14),
          elevation: 14,
          shadowColor: Colors.black87,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? baxterBlue : const Color(0xFF9AA7B5),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: selected ? 25 : 23,
              color: selected ? baxterBlue : const Color(0xFF9AA7B5),
            );
          }),
        ),
        useMaterial3: true,
      ),
      home: MainShell(
        darkMode: _themeMode == ThemeMode.dark,
        onDarkModeChanged: _setDarkMode,
      ),
    );
  }
}

class PersistentHomeButton extends StatelessWidget {
  const PersistentHomeButton({super.key});

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: null,
      tooltip: 'Home',
      onPressed: () => _goHome(context),
      backgroundColor: const Color(0xFF025EFF),
      foregroundColor: Colors.white,
      child: const Icon(Icons.home_rounded),
    );
  }
}

class BaxterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;

  const BaxterAppBar({super.key, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      centerTitle: true,
      toolbarHeight: 82,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            isDark ? 'assets/baxter_mark_ui.png' : 'assets/baxter_mark_light.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 10),
          Text(
            'BAXTER HEALTH',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.4,
              color: isDark ? const Color(0xFFF2F5F8) : const Color(0xFF1F2A36),
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.white.withValues(alpha: 0.045)),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const MainShell({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(),
      FavoritesPage(protocols: allProtocols),
      const WhatsNewPage(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: _MainBottomBar(
        selectedIndex: index,
        onSelected: (v) => setState(() => index = v),
      ),
    );
  }
}

class _MainBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const _MainBottomBar({required this.selectedIndex, required this.onSelected});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.star_border_rounded, Icons.star_rounded, 'Favorites'),
    (Icons.new_releases_outlined, Icons.new_releases_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: const BoxDecoration(
        color: Color(0xFF080E15),
        border: Border(top: BorderSide(color: Color(0x1F9CB0C3))),
        boxShadow: [BoxShadow(color: Color(0xAA000000), blurRadius: 16, offset: Offset(0, -5))],
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final selected = i == selectedIndex;
          final item = _items[i];
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? item.$2 : item.$1, size: selected ? 28 : 25, color: selected ? const Color(0xFF0A83FF) : const Color(0xFF9EADC0)),
                  const SizedBox(height: 5),
                  Text(item.$3, style: TextStyle(fontSize: 11.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? const Color(0xFF0A83FF) : const Color(0xFF9EADC0))),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class TopSearchBar extends StatefulWidget {
  const TopSearchBar({super.key});

  @override
  State<TopSearchBar> createState() => _TopSearchBarState();
}

class _TopSearchBarState extends State<TopSearchBar> {
  TextEditingController? _controller;
  FocusNode? _focusNode;

  static const Map<String, String> _toolLabels = {
    'Weight Conversion': 'Tools',
    'ASL / Deaf Patient': 'Tools',
    'Translator': 'Tools',
    'IV Drip Rate': 'Tools',
    'GCS Calculator': 'Tools',
    'Burn Calculator': 'Tools',
    'AHA Algorithms': 'Tools',
    'Pediatric Emergency': 'Tools',
    'Oxygen Tank Duration': 'Tools',
    'Medication Reference': 'Tools',
    'Pill Identifier': 'Tools',
    'Lab / Medical Reference': 'Tools',
    'LIFEPAK 35': 'Education',
    'Training Academy': 'Education',
    'ECG Academy': 'Training Academy',
    'Medication Academy': 'Training Academy',
    'Airway Academy': 'Training Academy',
    'Cardiac Arrest Academy': 'Training Academy',
    'Stroke Academy': 'Training Academy',
    'Pediatric Academy': 'Training Academy',
    'Trauma Academy': 'Training Academy',
    'OB / Neonatal Academy': 'Training Academy',
  };

  static const List<String> _staticSearchItems = [
    'Weight Conversion',
    'ASL / Deaf Patient',
    'Translator',
    'IV Drip Rate',
    'GCS Calculator',
    'Burn Calculator',
    'AHA Algorithms',
    'Pediatric Emergency',
    'Oxygen Tank Duration',
    'Medication Reference',
    'Pill Identifier',
    'Lab / Medical Reference',
    'Transfer Protocol',
    'Phone Numbers',
    'Study the Current Protocol',
    'TLC',
    'LIFEPAK 35',
    'Training Academy',
    'ECG Academy',
    'Medication Academy',
    'Airway Academy',
    'Cardiac Arrest Academy',
    'Stroke Academy',
    'Pediatric Academy',
    'Trauma Academy',
    'OB / Neonatal Academy',
    'Education',
    'Tools',
    'Useful Information',
    'Medications',
    'Cardiac',
    'Respiratory',
    'Medical',
    'Trauma',
    'OB/GYN',
    'Pediatric',
    'General',
  ];

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  List<String> _suggestions(String value) {
    final q = value.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final results = <String>[];
    final seen = <String>{};

    void add(String item) {
      if (seen.add(item)) results.add(item);
    }

    // Static tools/pages are prioritized so the new app features are easy to find.
    for (final item in _staticSearchItems) {
      if (item.toLowerCase().contains(q)) add(item);
      if (results.length >= 8) return results;
    }

    // Protocols remain searchable exactly as before.
    final titleMatches = allProtocols.where(
      (p) => p.title.toLowerCase().contains(q),
    );
    final otherMatches = allProtocols.where(
      (p) =>
          !p.title.toLowerCase().contains(q) &&
          '${p.category} ${p.content}'.toLowerCase().contains(q),
    );

    for (final protocol in [...titleMatches, ...otherMatches]) {
      add(protocol.title);
      if (results.length >= 8) break;
    }

    return results;
  }

  Future<void> _openStatic(String label) async {
    _focusNode?.unfocus();

    switch (label) {
      case 'Weight Conversion':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightConversionPage()));
        break;
      case 'ASL / Deaf Patient':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AslDictationPage()));
        break;
      case 'Translator':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslatorPage()));
        break;
      case 'IV Drip Rate':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const IvDripRatePage()));
        break;
      case 'GCS Calculator':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GcsCalculatorPage()));
        break;
      case 'Burn Calculator':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BurnCalculatorPage()));
        break;
      case 'AHA Algorithms':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AhaAlgorithmsPage()));
        break;
      case 'Pediatric Emergency':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PediatricEmergencyPage()));
        break;
      case 'Oxygen Tank Duration':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OxygenTankDurationPage()));
        break;
      case 'Medication Reference':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationReferencePage()));
        break;
      case 'Pill Identifier':
        await launchUrl(
          Uri.parse('https://www.drugs.com/imprints.php'),
          mode: LaunchMode.externalApplication,
        );
        break;
      case 'Lab / Medical Reference':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const LabReferencePage()));
        break;
      case 'Transfer Protocol':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferProtocolPage()));
        break;
      case 'Phone Numbers':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneNumbersPage()));
        break;
      case 'Study the Current Protocol':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProtocolStudyPage()));
        break;
      case 'TLC':
        await launchUrl(
          Uri.parse(EducationPage._tlcUrl),
          mode: LaunchMode.externalApplication,
        );
        break;
      case 'LIFEPAK 35':
        await launchUrl(
          Uri.parse(EducationPage._lifepak35Url),
          mode: LaunchMode.externalApplication,
        );
        break;
      case 'ECG Academy':
      case 'Medication Academy':
      case 'Airway Academy':
      case 'Cardiac Arrest Academy':
      case 'Stroke Academy':
      case 'Pediatric Academy':
      case 'Trauma Academy':
      case 'OB / Neonatal Academy':
        Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingAcademyPage(initialAcademy: label)));
        break;
      default:
        _openCategory(label);
    }
  }

  void _openCategory(String label) {
    final categories = <String>{
      'General',
      'Medications',
      'Cardiac',
      'Respiratory',
      'Medical',
      'Trauma',
      'OB/GYN',
      'Pediatric',
    };

    if (label == 'Education') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationPage()));
      return;
    }
    if (label == 'Tools') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsPage()));
      return;
    }
    if (label == 'Useful Information') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const UsefulInformationPage()));
      return;
    }
    if (categories.contains(label)) {
      final results = allProtocols.where((p) => p.category == label).toList();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProtocolsPage(protocols: results, title: label)),
      );
    }
  }

  void _search(String value) {
    final q = value.trim().toLowerCase();
    if (q.isEmpty) return;

    final exactStatic = _staticSearchItems.firstWhere(
      (item) => item.toLowerCase() == q,
      orElse: () => '',
    );
    if (exactStatic.isNotEmpty) {
      _openStatic(exactStatic);
      return;
    }

    final results = allProtocols.where((p) {
      final haystack = '${p.title} ${p.category} ${p.content}'.toLowerCase();
      return haystack.contains(q);
    }).toList();

    _focusNode?.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProtocolsPage(protocols: results, title: 'Search Results'),
      ),
    );
  }

  void _selectSuggestion(String item) {
    _controller?.text = item;
    _openStaticOrProtocol(item);
  }

  void _openStaticOrProtocol(String item) {
    if (_staticSearchItems.contains(item)) {
      _openStatic(item);
      return;
    }

    final matches = allProtocols.where((p) => p.title == item).toList();
    if (matches.isNotEmpty) {
      _focusNode?.unfocus();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProtocolDetailPage(protocol: matches.first)),
      );
    } else {
      _search(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Autocomplete<String>(
              optionsBuilder: (textEditingValue) => _suggestions(textEditingValue.text),
              onSelected: _selectSuggestion,
              fieldViewBuilder: (
                context,
                fieldController,
                fieldFocusNode,
                onFieldSubmitted,
              ) {
                _controller = fieldController;
                _focusNode = fieldFocusNode;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return TextField(
                  controller: fieldController,
                  focusNode: fieldFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    onFieldSubmitted();
                    if (value.trim().isNotEmpty) _search(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search protocols, medications, or keywords...',
                    hintStyle: TextStyle(fontSize: 14.5, color: isDark ? const Color(0xFFA5B4C7) : const Color(0xFF6B7F96)),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 6, right: 2),
                      child: Icon(Icons.search_rounded, size: 25, color: isDark ? const Color(0xFFD8E2EE) : const Color(0xFF344B63)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 52),
                    suffixIcon: fieldController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              fieldController.clear();
                              fieldFocusNode.requestFocus();
                              setState(() {});
                            },
                          ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF182431) : const Color(0xFFF7F9FC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: isDark ? const Color(0x332C78FF) : const Color(0x553B7FD1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: isDark ? const Color(0x332C78FF) : const Color(0x553B7FD1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF2C78FF) : const Color(0xFF025EFF), width: 1.4),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                final items = options.take(8).toList();
                return Align(
                  alignment: Alignment.topCenter,
                  child: Material(
                    elevation: 6,
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 360),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isStatic = _staticSearchItems.contains(item);
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              isStatic ? Icons.build_rounded : Icons.menu_book_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              item,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              isStatic ? (_toolLabels[item] ?? 'App') :
                                  (allProtocols.firstWhere((p) => p.title == item).category),
                            ),
                            onTap: () => onSelected(item),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _items = <_HomeItem>[
    _HomeItem('Protocols', 'General • Cardiac • Respiratory\nTrauma • Pediatric', Icons.description_rounded, Color(0xFFE12D35), false),
    _HomeItem('Tools', 'Calculators • Scores • References', Icons.calculate_rounded, Color(0xFF08A66A), false),
    _HomeItem('Useful Information', 'Guidelines • Resources • Links', Icons.menu_book_rounded, Color(0xFFF2B313), false),
    _HomeItem('Education', 'Learning • Procedures • CE • Training', Icons.school_rounded, Color(0xFF0A78FF), false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1520), Color(0xFF09111A), Color(0xFF070D14)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Column(
                  children: [
                    Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/baxter_mark_ui.png'
                          : 'assets/baxter_mark_light.png',
                      width: 92,
                      height: 92,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'BAXTER HEALTH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4.0,
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF5F7FA) : const Color(0xFF1F2A36),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const TopSearchBar(),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  itemCount: _items.length,
                  itemBuilder: (context, index) => _HomeDepthCard(item: _items[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool blue;

  const _HomeItem(this.title, this.subtitle, this.icon, this.color, this.blue);
}

class _HomeDepthCard extends StatelessWidget {
  final _HomeItem item;

  const _HomeDepthCard({required this.item});

  void _open(BuildContext context) {
    switch (item.title) {
      case 'Protocols':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProtocolCategoriesPage()));
        break;
      case 'Tools':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolsPage()));
        break;
      case 'Useful Information':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UsefulInformationPage()));
        break;
      case 'Education':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = item.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2734), Color(0xFF111A24)],
        ),
        border: Border.all(color: const Color(0x226F8BA6)),
        boxShadow: const [
          BoxShadow(color: Color(0xB8000000), blurRadius: 20, offset: Offset(0, 9)),
          BoxShadow(color: Color(0x18025EFF), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                _RenderIcon(color: accent, icon: item.icon, blue: item.blue),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                      const SizedBox(height: 6),
                      Text(item.subtitle, style: const TextStyle(fontSize: 12.2, height: 1.35, color: Color(0xFFB4C2D2))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFE8EEF5), size: 27),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RenderIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool blue;

  const _RenderIcon({required this.color, required this.icon, required this.blue});

  @override
  Widget build(BuildContext context) {
    final primary = blue ? const Color(0xFF0A78FF) : color;
    return BaxterIconBadge(
      icon: icon,
      color: primary,
      size: 72,
      iconSize: 37,
    );
  }
}

class BaxterIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const BaxterIconBadge({super.key, required this.icon, required this.color, this.size = 64, this.iconSize = 32});

  @override
  Widget build(BuildContext context) {
    // Shared icon treatment used across content cards throughout the app:
    // saturated color, soft top-left highlight, dark lower-right depth,
    // a restrained edge highlight, and a soft colored glow.
    final deep = Color.lerp(color, const Color(0xFF061321), 0.58)!;
    final highlight = Color.lerp(color, Colors.white, 0.14)!;
    final edge = Color.lerp(color, Colors.white, 0.26)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .24),
        gradient: LinearGradient(
          begin: const Alignment(-0.85, -0.95),
          end: const Alignment(.90, .95),
          stops: const [0.0, 0.48, 1.0],
          colors: [highlight, color, deep],
        ),
        border: Border.all(color: edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .58),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: color.withValues(alpha: .34),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: const Color(0xFFF5F7FA),
          size: iconSize,
        ),
      ),
    );
  }
}

class _ProtocolSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            onPressed: () => query = '',
            icon: const Icon(Icons.clear_rounded),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, ''),
        icon: const Icon(Icons.arrow_back_rounded),
      );

  @override
  Widget buildResults(BuildContext context) {
    final results = allProtocols.where((p) {
      final haystack = '${p.title} ${p.category} ${p.content}'.toLowerCase();
      return haystack.contains(query.trim().toLowerCase());
    }).toList();
    return ProtocolsPage(protocols: results, title: 'Search Results');
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.trim().toLowerCase();
    final results = q.isEmpty
        ? allProtocols.take(8).toList()
        : allProtocols.where((p) {
            return '${p.title} ${p.category}'.toLowerCase().contains(q);
          }).take(8).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final p = results[index];
        return ListTile(
          leading: const Icon(Icons.description_rounded, color: Color(0xFF1976D2)),
          title: Text(p.title),
          subtitle: Text(p.category),
          onTap: () => close(context, p.title),
        );
      },
    );
  }
}

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Text(
                  'Tools',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.monitor_weight_rounded, color: primary, size: 58, iconSize: 28),
                    title: const Text(
                      'Weight Conversion',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Convert pounds (lb) to kilograms (kg).'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WeightConversionPage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.hearing_disabled_rounded, color: const Color(0xFF00897B), size: 58, iconSize: 28),
                    title: const Text(
                      'ASL / Deaf Patient',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Speak and display large, readable text.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AslDictationPage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.translate_rounded, color: const Color(0xFF00897B), size: 58, iconSize: 28),
                    title: const Text(
                      'Translator',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('English ↔ Spanish with voice input.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TranslatorPage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.water_drop_rounded, color: const Color(0xFF1565C0), size: 58, iconSize: 28),
                    title: const Text(
                      'IV Drip Rate',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Calculate drops per minute from volume, time, and drop factor.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IvDripRatePage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.psychology_rounded, color: primary, size: 58, iconSize: 28),
                    title: const Text(
                      'GCS Calculator',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Calculate Eye, Verbal, and Motor scores.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GcsCalculatorPage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.local_fire_department_rounded, color: const Color(0xFFEF6C00), size: 58, iconSize: 28),
                    title: const Text(
                      'Burn Calculator',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Estimate adult TBSA using the Rule of Nines.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BurnCalculatorPage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.favorite_border_rounded, color: const Color(0xFFC62828), size: 58, iconSize: 28),
                    title: const Text(
                      'AHA Algorithms',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('2025 AHA CPR & ECC algorithms and official flowcharts.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AhaAlgorithmsPage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.child_friendly_rounded, color: const Color(0xFF00695C), size: 58, iconSize: 28),
                    title: const Text(
                      'Pediatric Emergency',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Broselow-style length-based weight and color-zone reference.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PediatricEmergencyPage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.medication_rounded, color: const Color(0xFF7B1FA2), size: 58, iconSize: 28),
                    title: const Text(
                      'Medication Reference',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Look up unfamiliar prescription and OTC medications.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MedicationReferencePage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.local_pharmacy_rounded, color: const Color(0xFF00838F), size: 58, iconSize: 28),
                    title: const Text(
                      'Pill Identifier',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Identify a pill by imprint, color, or shape.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final uri = Uri.parse('https://www.drugs.com/imprints.php');
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.science_rounded, color: const Color(0xFF5E35B1), size: 58, iconSize: 28),
                    title: const Text(
                      'Lab / Medical Reference',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Common laboratory reference ranges at a glance.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LabReferencePage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.air_rounded, color: const Color(0xFF00897B), size: 58, iconSize: 28),
                    title: const Text(
                      'Oxygen Tank Duration',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Estimate remaining oxygen time from tank pressure and flow.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OxygenTankDurationPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class AhaAlgorithm {
  final String title;
  final String imageUrl;
  final String description;

  const AhaAlgorithm(this.title, this.imageUrl, this.description);
}

class AhaAlgorithmsPage extends StatefulWidget {
  const AhaAlgorithmsPage({super.key});

  @override
  State<AhaAlgorithmsPage> createState() => _AhaAlgorithmsPageState();
}

class _AhaAlgorithmsPageState extends State<AhaAlgorithmsPage>
    with SingleTickerProviderStateMixin {
  static const String _officialPage =
      'https://cpr.heart.org/en/resuscitation-science/cpr-and-ecc-guidelines/algorithms';

  // Organized to mirror the major algorithm groupings used by the current
  // AHA 2025 algorithm library while preserving the official algorithm names.
  static const Map<String, List<AhaAlgorithm>> _sections = {
    'Adult BLS': [
      AhaAlgorithm(
        'Adult Basic Life Support — Healthcare Professionals',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-1-Adult-BLS-Algorithm-for-Health-Care-Professionals.jpg?h=1539&iar=0&mw=1910&sc_lang=en&w=1200',
        'Adult Basic Life Support Algorithm for Healthcare Professionals',
      ),
      AhaAlgorithm(
        'Adult Basic Life Support — Lay Rescuers',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-2-Adult-BLS-Algorithm-for-Lay-Rescuers.jpg?h=1789&iar=0&mw=1910&sc_lang=en&w=1200',
        'Adult Basic Life Support Algorithm for Lay Rescuers',
      ),
      AhaAlgorithm(
        'Adult Foreign-Body Airway Obstruction',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-3-Adult-FBAO-Algorithm.jpg?h=1156&iar=0&mw=1910&sc_lang=en&w=1200',
        'Adult Foreign-Body Airway Obstruction Algorithm',
      ),
    ],
    'Pediatric BLS': [
      AhaAlgorithm(
        'Pediatric BLS — Single Rescuer',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-9-Pediatric-BLS-Algorithm-Single-Rescuer.jpg?h=1654&iar=0&mw=1910&sc_lang=en&w=1200',
        'Pediatric Basic Life Support Algorithm (Infants to Puberty) for Healthcare Professionals — Single Rescuer',
      ),
      AhaAlgorithm(
        'Pediatric BLS — 2 or More Rescuers',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-10-Pediatric-BLS-Algorithm-2-or-more-Rescuers.jpg?h=1548&iar=0&mw=1910&sc_lang=en&w=1200',
        'Pediatric Basic Life Support Algorithm (Infants to Puberty) for Healthcare Professionals — 2 or More Rescuers',
      ),
      AhaAlgorithm(
        'Infant FBAO',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Algorithm-BLS-Infant-FBAO.jpg?h=1377&iar=0&mw=1910&sc_lang=en&w=1200',
        'Infant Foreign-Body Airway Obstruction Algorithm',
      ),
      AhaAlgorithm(
        'Child Foreign-Body Airway Obstruction',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Algorithm-BLS-Child-FBAO.jpg?h=1312&iar=0&mw=1910&sc_lang=en&w=1200',
        'Child Foreign-Body Airway Obstruction Algorithm',
      ),
    ],
    'Adult ALS': [
      AhaAlgorithm(
        'Adult Cardiac Arrest — Circular Algorithm',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-1-Adult-Cardiac-Arrest-Circular-Algorithm.jpg?h=995&iar=0&mw=1910&sc_lang=en&w=1200',
        'Adult Cardiac Arrest Circular Algorithm',
      ),
      AhaAlgorithm(
        'Adult Cardiac Arrest',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-2-Adult-Cardiac-Arrest-Algorithm.jpg?h=1548&iar=0&mw=1910&sc_lang=en&w=1200',
        'Adult Cardiac Arrest Algorithm',
      ),
      AhaAlgorithm(
        'BLS / Universal Termination of Resuscitation Rules',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-3-BLS-Universal-Termination-of-Resuscitation-Rules.jpg?h=736&iar=0&mw=1910&sc_lang=en&w=1200',
        'BLS/Universal Termination of Resuscitation Rules',
      ),
      AhaAlgorithm(
        'ALS Termination of Resuscitation Rule',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-4-ALS-Termination-of-Resuscitation-Rule.jpg?h=789&iar=0&mw=1910&sc_lang=en&w=1200',
        'ALS Termination of Resuscitation Rule',
      ),
      AhaAlgorithm(
        'Adult Tachyarrhythmia With a Pulse',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-6-Adult-Tachyarrhythmia-With-a-Pulse-Algorithm.jpg?h=1047&iar=0&mw=1910&sc_lang=en&w=1200',
        'Adult Tachyarrhythmia With a Pulse Algorithm',
      ),
      AhaAlgorithm(
        'Electrical Cardioversion',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-7-Electrical-Cardioversion-Algorithm.jpg?h=2063&iar=0&mw=1910&sc_lang=en&w=1200',
        'Electrical Cardioversion Algorithm',
      ),
      AhaAlgorithm(
        'Adult Bradycardia With a Pulse',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-8-Adult-Bradycardia-with-a-Pulse-Algorithm.jpg?h=1339&iar=0&mw=1910&sc_lang=en&w=1200',
        'Adult Bradycardia With a Pulse Algorithm',
      ),
      AhaAlgorithm(
        'Adult Post-Cardiac Arrest Care',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/pcac-Figure-1-Adult-PCAC-Algorithm.jpg?h=1570&iar=0&mw=1910&sc_lang=en&w=1200',
        'Adult Post–Cardiac Arrest Care Algorithm',
      ),
    ],
    'Pediatric ALS': [
      AhaAlgorithm(
        'Pediatric Cardiac Arrest',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-2-Pediatric-Cardiac-Arrest-Algorithm-2.jpg?h=1549&iar=0&mw=1910&sc_lang=en&w=1200',
        'Pediatric Cardiac Arrest Algorithm',
      ),
      AhaAlgorithm(
        'Pediatric Bradycardia With a Pulse',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-6-Pediatric-Bradycardia-With-a-Pulse-Algorithm.jpg?h=1709&iar=0&mw=1910&sc_lang=en&w=1200',
        'Pediatric Bradycardia With a Pulse Algorithm',
      ),
      AhaAlgorithm(
        'Pediatric Tachyarrhythmia With a Pulse',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-7-Pediatric-Tachyarrhythmia-With-a-Pulse-Algorithm.jpg?h=1349&iar=0&mw=1910&sc_lang=en&w=1200',
        'Pediatric Tachyarrhythmia With a Pulse Algorithm',
      ),
    ],
    'Special Situations': [
      AhaAlgorithm(
        'Adult and Pediatric Durable LVAD',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-4-Adult-and-Pediatric-Durable-LVAD-Algorithm.jpg?h=1047&iar=0&mw=1910&sc_lang=en&w=1200',
        'Adult and Pediatric Durable Left Ventricular Assist Device Algorithm',
      ),
      AhaAlgorithm(
        'Cardiac Arrest in Pregnancy',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-5-Cardiac-Arrest-in-Pregnancy.jpg?h=1134&iar=0&mw=1910&sc_lang=en&w=1200',
        'Cardiac Arrest in Pregnancy Algorithm',
      ),
    ],
    'Neonatal': [
      AhaAlgorithm(
        'Neonatal Resuscitation',
        'https://cpr.heart.org/en/-/media/CPR-Images/CPR-Guidelines-2025/Algorithms/Figure-2-Neonatal-Resuscitation.jpg?h=1689&iar=0&mw=1910&sc_lang=en&w=1200',
        'Neonatal Resuscitation Algorithm',
      ),
    ],
  };

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionNames = _sections.keys.toList(growable: false);

    return Scaffold(
      appBar: const BaxterAppBar(),
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          const TopSearchBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              children: [
                const Text(
                  'AHA Algorithms',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '2025 American Heart Association CPR & ECC Guidelines',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: isDark ? const Color(0xFF17191C) : Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF025EFF),
              unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
              indicatorColor: const Color(0xFF025EFF),
              tabs: [
                for (final name in sectionNames) Tab(text: name),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final name in sectionNames)
                  _buildAlgorithmList(context, name, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmList(
    BuildContext context,
    String sectionName,
    bool isDark,
  ) {
    final algorithms = _sections[sectionName] ?? const <AhaAlgorithm>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFC62828),
              child: Icon(Icons.favorite_rounded, color: Colors.white),
            ),
            title: const Text(
              'American Heart Association',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Text('2025 CPR & ECC algorithm library'),
            ),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () async {
              await launchUrl(
                Uri.parse(_officialPage),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
          child: Text(
            sectionName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        for (final algorithm in algorithms)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFC62828),
                child: Icon(Icons.account_tree_rounded, color: Colors.white),
              ),
              title: Text(
                algorithm.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(algorithm.description),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AhaOfflineAlgorithmPage(algorithm: algorithm),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}



class AhaOfflineAlgorithmPage extends StatelessWidget {
  final AhaAlgorithm algorithm;

  const AhaOfflineAlgorithmPage({super.key, required this.algorithm});

  static const Map<String, List<String>> _offlineSteps = {
    'Adult Basic Life Support — Healthcare Professionals': [
      'Verify scene safety and assess responsiveness.',
      'Activate the emergency response system and obtain an AED/defibrillator.',
      'Assess breathing and pulse; begin CPR when indicated.',
      'Provide high-quality chest compressions and ventilations according to current AHA guidance.',
      'Use the AED/defibrillator as soon as available and follow device prompts.',
      'Continue the resuscitation sequence and reassess according to the algorithm.'
    ],
    'Adult Basic Life Support — Lay Rescuers': [
      'Recognize suspected cardiac arrest and activate the emergency response system.',
      'Begin chest compressions promptly and obtain an AED when available.',
      'Use the AED and follow its prompts.',
      'Continue CPR until signs of life, trained rescuers take over, or the resuscitation is otherwise terminated.'
    ],
    'Adult Foreign-Body Airway Obstruction': [
      'Recognize mild versus severe foreign-body airway obstruction.',
      'For severe obstruction in a conscious adult, use the current AHA sequence of back blows and abdominal thrusts.',
      'If the patient becomes unresponsive, activate the emergency response system and begin CPR.',
      'Each time the airway is opened during CPR, look for a visible object and remove it if present; do not perform blind finger sweeps.'
    ],
    'Pediatric BLS — Single Rescuer': [
      'Assess responsiveness and breathing and activate the emergency response system as indicated.',
      'Check for a pulse when appropriate for the healthcare professional algorithm.',
      'Begin CPR when indicated and use an AED/defibrillator as soon as available.',
      'Follow the pediatric compression, ventilation, and rhythm-assessment sequence in the current AHA algorithm.',
      'Continue cycles of CPR and reassessment until return of circulation or termination of resuscitation.'
    ],
    'Pediatric BLS — 2 or More Rescuers': [
      'Assess the child or infant and activate the emergency response system.',
      'Assign roles and begin high-quality CPR when indicated.',
      'Use an AED/defibrillator as soon as available.',
      'Follow the pediatric 2-or-more-rescuer compression, ventilation, and rhythm sequence.',
      'Continue CPR and reassessment according to the current AHA algorithm.'
    ],
    'Infant FBAO': [
      'Recognize severe foreign-body airway obstruction in an infant.',
      'Use the current AHA sequence of repeated back blows and chest thrusts.',
      'If the infant becomes unresponsive, begin CPR and activate the emergency response system.',
      'Remove a visible object when encountered during airway assessment; do not perform blind finger sweeps.'
    ],
    'Child Foreign-Body Airway Obstruction': [
      'Recognize severe foreign-body airway obstruction in a child.',
      'Use the current AHA sequence of back blows and abdominal thrusts.',
      'If the child becomes unresponsive, begin CPR and activate the emergency response system.',
      'Remove a visible object when encountered during airway assessment; do not perform blind finger sweeps.'
    ],
    'Adult Cardiac Arrest — Circular Algorithm': [
      'Start with high-quality CPR and rapid rhythm assessment.',
      'For a shockable rhythm, deliver defibrillation and resume CPR promptly.',
      'For a nonshockable rhythm, continue CPR and address reversible causes.',
      'Use medications and advanced airway/ventilation strategies according to the current AHA ALS algorithm.',
      'Reassess rhythm at the appropriate intervals and continue until ROSC or termination criteria are met.'
    ],
    'Adult Cardiac Arrest': [
      'Begin high-quality CPR and obtain a monitor/defibrillator.',
      'Determine whether the rhythm is shockable or nonshockable.',
      'Treat VF/pVT with defibrillation and continued CPR; treat asystole/PEA with CPR and appropriate medications.',
      'Consider advanced airway and capnography when indicated.',
      'Identify and treat reversible causes and reassess rhythm at the designated intervals.',
      'If ROSC occurs, transition to post-cardiac-arrest care.'
    ],
    'BLS / Universal Termination of Resuscitation Rules': [
      'Use the rule only when its inclusion and criteria are applicable to the resuscitation setting.',
      'Confirm the required clinical and system-level criteria before considering termination.',
      'If termination criteria are not met, continue resuscitation and transport/medical control actions as required.',
      'Follow local medical direction and system policy in addition to the AHA rule.'
    ],
    'ALS Termination of Resuscitation Rule': [
      'Apply the rule only to patients and systems for which the ALS termination criteria are intended.',
      'Confirm all required clinical criteria and absence of exclusion conditions.',
      'If criteria are not satisfied, continue resuscitation and follow medical direction.',
      'Use local EMS policy and medical control requirements for any termination decision.'
    ],
    'Adult Tachyarrhythmia With a Pulse': [
      'Assess the airway, breathing, oxygenation, circulation, and monitor the rhythm.',
      'Determine whether the tachyarrhythmia is causing hemodynamic instability.',
      'For unstable tachyarrhythmia, use synchronized cardioversion when indicated.',
      'For stable patients, identify rhythm characteristics and use the appropriate medication/consultation pathway.',
      'Reassess continuously and address underlying causes.'
    ],
    'Electrical Cardioversion': [
      'Confirm the patient has a tachyarrhythmia requiring synchronized cardioversion.',
      'Prepare the monitor/defibrillator for synchronized mode and apply appropriate pads.',
      'Provide sedation/analgesia when appropriate and when it will not delay lifesaving therapy.',
      'Deliver the recommended synchronized shock for the rhythm and reassess.',
      'Escalate or repeat therapy according to the current AHA algorithm and clinical response.'
    ],
    'Adult Bradycardia With a Pulse': [
      'Assess airway, breathing, oxygenation, circulation, and obtain a rhythm.',
      'Determine whether the bradycardia is causing cardiopulmonary compromise.',
      'Treat reversible causes and provide supportive care.',
      'For persistent symptomatic bradycardia, follow the AHA pathway for atropine and pacing/vasoactive support as indicated.',
      'Reassess response continuously.'
    ],
    'Adult Post-Cardiac Arrest Care': [
      'After ROSC, stabilize airway, breathing, and circulation.',
      'Optimize oxygenation and ventilation and support appropriate blood pressure/perfusion.',
      'Obtain a 12-lead ECG and evaluate for an underlying cause.',
      'Consider indicated coronary, neurologic, temperature-management, and seizure-related evaluation/interventions.',
      'Continue structured post-cardiac-arrest care and reassessment.'
    ],
    'Pediatric Cardiac Arrest': [
      'Begin high-quality pediatric CPR and obtain a monitor/defibrillator.',
      'Determine whether the rhythm is shockable or nonshockable.',
      'For VF/pVT, defibrillate and resume CPR promptly; for asystole/PEA, continue CPR and treat reversible causes.',
      'Use weight-based medications and advanced airway/ventilation strategies according to the current AHA algorithm.',
      'Reassess rhythm at the appropriate intervals and transition to post-arrest care after ROSC.'
    ],
    'Pediatric Bradycardia With a Pulse': [
      'Assess airway, breathing, oxygenation, circulation, and obtain a rhythm.',
      'Determine whether the bradycardia is causing cardiopulmonary compromise.',
      'Support oxygenation/ventilation and treat the underlying cause.',
      'If compromise persists, follow the AHA pathway for CPR, epinephrine, atropine when appropriate, and pacing when indicated.',
      'Reassess continuously.'
    ],
    'Pediatric Tachyarrhythmia With a Pulse': [
      'Assess airway, breathing, oxygenation, circulation, and rhythm.',
      'Determine whether the tachyarrhythmia is causing cardiopulmonary compromise.',
      'For unstable tachyarrhythmia, follow the AHA synchronized cardioversion pathway.',
      'For stable tachyarrhythmia, identify the rhythm and follow the appropriate vagal/adenosine or consultation pathway.',
      'Reassess response and underlying causes.'
    ],
    'Adult and Pediatric Durable LVAD': [
      'Assess the patient while recognizing that usual pulse and blood-pressure findings may be unreliable with continuous-flow LVADs.',
      'Check the LVAD controller, power source, alarms, and driveline as appropriate.',
      'Determine whether the device is functioning and address correctable equipment or power problems.',
      'If the patient is in cardiac arrest or severe instability, follow the AHA LVAD resuscitation pathway and local specialty guidance.',
      'Consult the LVAD center/medical control when indicated.'
    ],
    'Cardiac Arrest in Pregnancy': [
      'Begin high-quality CPR and follow the standard adult cardiac-arrest sequence.',
      'Activate the obstetric/neonatal and resuscitation teams early.',
      'Address reversible causes and pregnancy-specific considerations.',
      'Perform indicated left uterine displacement and prepare for resuscitative delivery when criteria are met.',
      'Continue coordinated maternal and neonatal resuscitation according to the current AHA algorithm.'
    ],
    'Neonatal Resuscitation': [
      'Prepare for birth and perform the initial newborn assessment.',
      'Provide routine care when the newborn is breathing effectively and has good tone.',
      'If needed, initiate ventilation support and reassess heart rate.',
      'Escalate respiratory support and chest compressions according to the neonatal resuscitation pathway when indicated.',
      'Use umbilical vascular access and medications when indicated by the algorithm.',
      'Continue reassessment and transition to post-resuscitation care.'
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = _offlineSteps[algorithm.title] ?? const <String>[];

    return Scaffold(
      appBar: const BaxterAppBar(),
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Text(
                  algorithm.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Offline quick reference',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Key sequence',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        for (var i = 0; i < steps.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: const Color(0xFF025EFF),
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    steps[i],
                                    style: const TextStyle(fontSize: 16, height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await launchUrl(
                      Uri.parse(algorithm.imageUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Official AHA Flowchart'),
                ),
                const SizedBox(height: 10),
                Text(
                  'The quick reference above is available offline. The official AHA flowchart is opened from AHA online and requires an internet connection. Use current approved protocols and medical direction for patient care.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final TextEditingController _englishController = TextEditingController();
  final GoogleTranslator _translator = GoogleTranslator();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  String _spanishText = '';
  String? _errorText;
  bool _isTranslating = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      _tts.setStartHandler(() { if (mounted) setState(() => _isSpeaking = true); });
      _tts.setCompletionHandler(() { if (mounted) setState(() => _isSpeaking = false); });
      _tts.setCancelHandler(() { if (mounted) setState(() => _isSpeaking = false); });
      _tts.setErrorHandler((_) { if (mounted) setState(() => _isSpeaking = false); });
    } catch (_) {}
  }

  Future<void> _speakSpanish() async {
    final text = _spanishText.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Translate something into Spanish first.');
      return;
    }
    try {
      if (_isSpeaking) {
        await _tts.stop();
        if (mounted) setState(() => _isSpeaking = false);
        return;
      }
      setState(() => _errorText = null);
      await _tts.setLanguage('es-ES');
      await _tts.speak(text);
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Audio playback is unavailable on this device or browser.');
      }
    }
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _isListening = status == 'listening');
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _errorText = 'Voice input is unavailable: ${error.errorMsg}';
        });
      },
    );
    if (mounted) {
      setState(() => _speechAvailable = available);
    }
  }

  Future<void> _translate() async {
    final text = _englishController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _spanishText = '';
        _errorText = 'Enter or speak something in English first.';
      });
      return;
    }

    setState(() {
      _isTranslating = true;
      _errorText = null;
    });

    try {
      final translation = await _translator.translate(text, from: 'en', to: 'es');
      if (!mounted) return;
      setState(() => _spanishText = translation.text);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Translation failed. Check your internet connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      await _initializeSpeech();
    }
    if (!_speechAvailable) {
      setState(() => _errorText = 'Speech recognition is not available in this browser.');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _errorText = null);
    await _speech.listen(
      localeId: 'en_US',
      partialResults: true,
      listenFor: const Duration(minutes: 1),
      pauseFor: const Duration(seconds: 3),
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) return;
        setState(() {
          _englishController.text = result.recognizedWords;
          _englishController.selection = TextSelection.fromPosition(
            TextPosition(offset: _englishController.text.length),
          );
        });
        if (result.finalResult) _translate();
      },
    );
  }

  void _clear() {
    _englishController.clear();
    setState(() {
      _spanishText = '';
      _errorText = null;
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _englishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(child: _buildTranslatorTab(context)),
        ],
      ),
    );
  }

  Widget _buildTranslatorTab(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        Row(
          children: [
            Icon(Icons.translate_rounded, color: const Color(0xFF00897B), size: 30),
            const SizedBox(width: 10),
            const Expanded(child: Text('English → Spanish', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('English', style: TextStyle(fontWeight: FontWeight.w800, color: onSurface)),
                const SizedBox(height: 8),
                TextField(
                  controller: _englishController,
                  minLines: 4,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Type or speak English here...',
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isTranslating ? null : _translate,
                        icon: _isTranslating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.translate_rounded),
                        label: Text(_isTranslating ? 'Translating...' : 'Translate'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: _isListening ? 'Stop listening' : 'Speak English',
                      onPressed: _isTranslating ? null : _toggleListening,
                      icon: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded),
                    ),
                    const SizedBox(width: 4),
                    IconButton(tooltip: 'Clear', onPressed: _clear, icon: const Icon(Icons.clear_rounded)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spanish', style: TextStyle(fontWeight: FontWeight.w800, color: onSurface)),
                const SizedBox(height: 10),
                SelectableText(
                  _spanishText.isEmpty ? 'Your Spanish translation will appear here.' : _spanishText,
                  style: TextStyle(fontSize: 18, height: 1.4, color: _spanishText.isEmpty ? muted : onSurface),
                ),
                if (_spanishText.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _speakSpanish,
                      icon: Icon(_isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded),
                      label: Text(_isSpeaking ? 'Stop Audio' : 'Play Translation'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 10),
          Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 14),
        Text(
          'Important: Do not enter patient names, dates of birth, medical record numbers, or other protected health information. Translation uses an online service.',
          style: TextStyle(fontSize: 12, color: muted, height: 1.35),
        ),
      ],
    );
  }
}

class AslDictationPage extends StatefulWidget {
  const AslDictationPage({super.key});

  @override
  State<AslDictationPage> createState() => _AslDictationPageState();
}

class _AslDictationPageState extends State<AslDictationPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _controller = TextEditingController();
  bool _speechAvailable = false;
  bool _isListening = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _isListening = status == 'listening');
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _errorText = 'Voice input is unavailable: ${error.errorMsg}';
        });
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) await _initializeSpeech();
    if (!_speechAvailable) {
      setState(() => _errorText = 'Speech recognition is not available in this browser.');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    // Start each dictation session with a clean display.
    _controller.clear();
    setState(() {
      _errorText = null;
      _isListening = true;
    });

    await _speech.listen(
      localeId: 'en_US',
      partialResults: true,
      listenFor: const Duration(minutes: 1),
      pauseFor: const Duration(seconds: 3),
      onResult: (SpeechRecognitionResult result) {
        if (!mounted) return;
        // The recognizer can return interim results while the user is still
        // speaking. setState is required here so the large display rebuilds
        // immediately instead of waiting for STOP LISTENING.
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );
  }

  void _clear() {
    _controller.clear();
    setState(() => _errorText = null);
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
        Row(
          children: [
            Icon(Icons.hearing_disabled_rounded, color: const Color(0xFF00897B), size: 30),
            const SizedBox(width: 10),
            const Expanded(child: Text('ASL / Deaf Patient', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Speak into the microphone and display your words in large, readable text for the patient.',
          style: TextStyle(fontSize: 15, color: muted, height: 1.35),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _toggleListening,
                    icon: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, size: 28),
                    label: Text(_isListening ? 'STOP LISTENING' : 'TAP TO SPEAK', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 260),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.topLeft,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _controller.text.isEmpty ? 'Your spoken words will appear here.' : _controller.text,
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: _controller.text.isEmpty ? muted : onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text('Clear Text'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isListening) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic_rounded, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Listening…', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 10),
          Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 14),
              Text(
                'This tool converts spoken English to text. It does not translate speech into ASL signs. For clinical communication, confirm that the patient understands the displayed message.',
                style: TextStyle(fontSize: 12, color: muted, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
}


class GcsCalculatorPage extends StatefulWidget {
  const GcsCalculatorPage({super.key});

  @override
  State<GcsCalculatorPage> createState() => _GcsCalculatorPageState();
}

class _GcsCalculatorPageState extends State<GcsCalculatorPage> {
  int _eye = 4;
  int _verbal = 5;
  int _motor = 6;

  int get _total => _eye + _verbal + _motor;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Text(
                  'GCS Calculator',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the best Eye, Verbal, and Motor responses.',
                  style: TextStyle(color: onSurfaceVariant, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    child: Column(
                      children: [
                        _scoreDropdown(
                          context,
                          label: 'Eye',
                          value: _eye,
                          items: const [
                            DropdownMenuItem(value: 4, child: Text('4 — Spontaneous')),
                            DropdownMenuItem(value: 3, child: Text('3 — To voice')),
                            DropdownMenuItem(value: 2, child: Text('2 — To pain')),
                            DropdownMenuItem(value: 1, child: Text('1 — None')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _eye = value);
                          },
                        ),
                        _scoreDropdown(
                          context,
                          label: 'Verbal',
                          value: _verbal,
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5 — Oriented')),
                            DropdownMenuItem(value: 4, child: Text('4 — Confused')),
                            DropdownMenuItem(value: 3, child: Text('3 — Inappropriate words')),
                            DropdownMenuItem(value: 2, child: Text('2 — Incomprehensible sounds')),
                            DropdownMenuItem(value: 1, child: Text('1 — None')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _verbal = value);
                          },
                        ),
                        _scoreDropdown(
                          context,
                          label: 'Motor',
                          value: _motor,
                          items: const [
                            DropdownMenuItem(value: 6, child: Text('6 — Obeys commands')),
                            DropdownMenuItem(value: 5, child: Text('5 — Localizes pain')),
                            DropdownMenuItem(value: 4, child: Text('4 — Withdraws from pain')),
                            DropdownMenuItem(value: 3, child: Text('3 — Abnormal flexion')),
                            DropdownMenuItem(value: 2, child: Text('2 — Extension')),
                            DropdownMenuItem(value: 1, child: Text('1 — None')),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _motor = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                    child: Column(
                      children: [
                        Text(
                          'TOTAL GCS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: onSurfaceVariant,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_total / 15',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'E$_eye  V$_verbal  M$_motor',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _eye = 4;
                      _verbal = 5;
                      _motor = 6;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                ),
                const SizedBox(height: 16),
                Text(
                  'GCS scoring is provided as a reference tool. Use your clinical assessment and current approved protocols when evaluating patients.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreDropdown(
    BuildContext context, {
    required String label,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<int>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class IvDripRatePage extends StatefulWidget {
  const IvDripRatePage({super.key});

  @override
  State<IvDripRatePage> createState() => _IvDripRatePageState();
}

class _IvDripRatePageState extends State<IvDripRatePage> {
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  double _dropFactor = 10;
  String? _result;

  @override
  void dispose() {
    _volumeController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final volume = double.tryParse(_volumeController.text.trim());
    final minutes = double.tryParse(_timeController.text.trim());
    if (volume == null || minutes == null || volume <= 0 || minutes <= 0) {
      setState(() => _result = null);
      return;
    }
    final gttPerMin = (volume * _dropFactor / minutes).round();
    setState(() => _result = '$gttPerMin gtt/min');
  }

  void _clear() {
    _volumeController.clear();
    _timeController.clear();
    setState(() {
      _dropFactor = 10;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Text('IV Drip Rate', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Calculate drops per minute using volume, time, and tubing drop factor.', style: TextStyle(color: muted, fontSize: 15)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        TextField(
                          controller: _volumeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Volume (mL)', hintText: 'e.g. 1000'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _timeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Time (minutes)', hintText: 'e.g. 60'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<double>(
                          initialValue: _dropFactor,
                          decoration: const InputDecoration(labelText: 'Drop Factor (gtt/mL)'),
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10 gtt/mL')),
                            DropdownMenuItem(value: 15, child: Text('15 gtt/mL')),
                            DropdownMenuItem(value: 20, child: Text('20 gtt/mL')),
                            DropdownMenuItem(value: 60, child: Text('60 gtt/mL')),
                          ],
                          onChanged: (value) => setState(() => _dropFactor = value ?? 10),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _calculate,
                            icon: const Icon(Icons.calculate_rounded),
                            label: const Text('Calculate'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                      child: Column(
                        children: [
                          Text('DRIP RATE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: muted, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(_result!, style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: primary)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(onPressed: _clear, icon: const Icon(Icons.refresh_rounded), label: const Text('Clear')),
                const SizedBox(height: 14),
                Text('Enter the drop factor printed on the IV tubing. Verify the tubing set and calculated rate before administration.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OxygenTankDurationPage extends StatefulWidget {
  const OxygenTankDurationPage({super.key});

  @override
  State<OxygenTankDurationPage> createState() => _OxygenTankDurationPageState();
}

class _OxygenTankDurationPageState extends State<OxygenTankDurationPage> {
  final TextEditingController _pressureController = TextEditingController();
  final TextEditingController _flowController = TextEditingController();
  String _tank = 'C';
  String? _result;

  static const Map<String, double> _factors = {
    'C': 0.16,
    'G': 2.41,
  };

  @override
  void dispose() {
    _pressureController.dispose();
    _flowController.dispose();
    super.dispose();
  }

  void _calculate() {
    final psi = double.tryParse(_pressureController.text.trim());
    final lpm = double.tryParse(_flowController.text.trim());
    if (psi == null || lpm == null || psi <= 200 || lpm <= 0) {
      setState(() => _result = null);
      return;
    }
    final minutes = ((psi - 200) * _factors[_tank]!) / lpm;
    final wholeMinutes = minutes.floor();
    final hours = wholeMinutes ~/ 60;
    final remaining = wholeMinutes % 60;
    setState(() {
      _result = hours > 0 ? '$hours hr $remaining min' : '$remaining min';
    });
  }

  void _clear() {
    _pressureController.clear();
    _flowController.clear();
    setState(() {
      _tank = 'C';
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Text('Oxygen Tank Duration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Estimate remaining oxygen time from cylinder size, pressure, and flow.', style: TextStyle(color: muted, fontSize: 15)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _tank,
                          decoration: const InputDecoration(labelText: 'Cylinder Size'),
                          items: const [
                            DropdownMenuItem(value: 'C', child: Text('C — Small')),
                            DropdownMenuItem(value: 'G', child: Text('G — Large')),
                          ],
                          onChanged: (value) => setState(() => _tank = value ?? 'C'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pressureController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Tank Pressure (PSI)', hintText: 'e.g. 2000'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _flowController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Flow Rate (L/min)', hintText: 'e.g. 15'),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate_rounded), label: const Text('Calculate'))),
                      ],
                    ),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                      child: Column(
                        children: [
                          Text('ESTIMATED REMAINING TIME', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: muted, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(_result!, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: primary)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(onPressed: _clear, icon: const Icon(Icons.refresh_rounded), label: const Text('Clear')),
                const SizedBox(height: 14),
                Text('Approximate estimate. This calculator uses a 200 PSI reserve and common cylinder factors; verify the actual cylinder factor and remaining pressure before relying on the result.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BurnCalculatorPage extends StatefulWidget {
  const BurnCalculatorPage({super.key});

  @override
  State<BurnCalculatorPage> createState() => _BurnCalculatorPageState();
}

class _BurnCalculatorPageState extends State<BurnCalculatorPage> {
  final Map<String, bool> _selected = {
    'Head & neck': false,
    'Right arm': false,
    'Left arm': false,
    'Anterior trunk': false,
    'Posterior trunk': false,
    'Right leg': false,
    'Left leg': false,
    'Perineum': false,
  };

  static const Map<String, double> _percent = {
    'Head & neck': 9,
    'Right arm': 9,
    'Left arm': 9,
    'Anterior trunk': 18,
    'Posterior trunk': 18,
    'Right leg': 18,
    'Left leg': 18,
    'Perineum': 1,
  };

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _fluidGivenController = TextEditingController();
  bool _weightPounds = false;
  DateTime? _injuryDateTime;
  Timer? _elapsedTimer;

  double get _total => _selected.entries.fold(0, (sum, entry) => sum + (entry.value ? _percent[entry.key]! : 0));

  double? get _weightKg {
    final value = double.tryParse(_weightController.text.trim());
    if (value == null || value <= 0) return null;
    return _weightPounds ? value * 0.45359237 : value;
  }

  double? get _hoursSinceBurn {
    final injury = _injuryDateTime;
    if (injury == null) return null;
    final elapsed = DateTime.now().difference(injury).inSeconds / 3600;
    if (elapsed < 0) return null;
    return elapsed;
  }

  String get _injuryTimeLabel {
    final injury = _injuryDateTime;
    if (injury == null) return 'Select time of injury';
    final date = MaterialLocalizations.of(context).formatMediumDate(injury);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(injury));
    return '$date at $time';
  }

  Future<void> _pickInjuryDateTime() async {
    final now = DateTime.now();
    final initial = _injuryDateTime ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: now.subtract(const Duration(days: 2)),
      lastDate: now,
      helpText: 'Select date of burn injury',
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Select time of burn injury',
    );
    if (!mounted || time == null) return;
    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (selected.isAfter(DateTime.now())) return;
    setState(() => _injuryDateTime = selected);
  }

  double get _fluidGivenMl {
    final value = double.tryParse(_fluidGivenController.text.trim());
    if (value == null || value < 0) return 0;
    return value;
  }

  void _clear() {
    setState(() {
      for (final key in _selected.keys) {
        _selected[key] = false;
      }
      _weightController.clear();
      _injuryDateTime = null;
      _fluidGivenController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _elapsedTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _injuryDateTime != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _elapsedTimer?.cancel();
    _fluidGivenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Text('Burn Calculator', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Estimate adult total body surface area (TBSA) using the Rule of Nines.', style: TextStyle(color: muted, fontSize: 15)),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: _selected.keys.map((region) {
                      return CheckboxListTile(
                        title: Text(region),
                        secondary: Text('${_percent[region]!.toStringAsFixed(_percent[region]! % 1 == 0 ? 0 : 1)}%'),
                        value: _selected[region],
                        onChanged: (value) => setState(() => _selected[region] = value ?? false),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                    child: Column(
                      children: [
                        Text('ESTIMATED TBSA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: muted, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('${_total.toStringAsFixed(0)}%', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: primary)),
                      ],
                    ),
                  ),
                ),
                if (_total > 0) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PARKLAND BURN FORMULA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: primary, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text('4 mL × weight (kg) × %TBSA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _weightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: 'Patient weight',
                                    suffixText: _weightPounds ? 'lb' : 'kg',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment<bool>(value: false, label: Text('kg')),
                                  ButtonSegment<bool>(value: true, label: Text('lb')),
                                ],
                                selected: {_weightPounds},
                                onSelectionChanged: (selection) {
                                  final newPounds = selection.first;
                                  final current = double.tryParse(_weightController.text.trim());
                                  setState(() {
                                    if (current != null) {
                                      final kg = _weightPounds ? current * 0.45359237 : current;
                                      final converted = newPounds ? kg / 0.45359237 : kg;
                                      _weightController.text = converted.toStringAsFixed(1);
                                      _weightController.selection = TextSelection.fromPosition(TextPosition(offset: _weightController.text.length));
                                    }
                                    _weightPounds = newPounds;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickInjuryDateTime,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Time of injury',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.schedule_rounded),
                                helperText: 'The first 8 hours are measured from the time of injury, not arrival.',
                              ),
                              child: Text(
                                _injuryTimeLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _injuryDateTime == null ? FontWeight.w400 : FontWeight.w600,
                                  color: _injuryDateTime == null ? muted : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          if (_injuryDateTime != null) ...[
                            const SizedBox(height: 8),
                            Builder(builder: (context) {
                              final elapsed = _hoursSinceBurn!;
                              final totalMinutes = (elapsed * 60).round();
                              final hours = totalMinutes ~/ 60;
                              final minutes = totalMinutes % 60;
                              final remainingMinutes = max(0, 480 - totalMinutes);
                              final remainingHours = remainingMinutes ~/ 60;
                              final remainingRemainder = remainingMinutes % 60;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Elapsed since injury: $hours hr ${minutes.toString().padLeft(2, '0')} min',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      totalMinutes < 480
                                          ? 'Time remaining in first 8 hours: $remainingHours hr ${remainingRemainder.toString().padLeft(2, '0')} min'
                                          : 'First 8-hour window has elapsed.',
                                      style: TextStyle(color: muted),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            controller: _fluidGivenController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Crystalloid already given',
                              suffixText: 'mL',
                              border: OutlineInputBorder(),
                              helperText: 'Optional — subtracts documented pre-calculated crystalloid from the first-8-hour amount.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_weightKg == null)
                            Text('Enter patient weight to calculate fluid volumes.', style: TextStyle(color: muted, fontWeight: FontWeight.w600))
                          else ...[
                            Builder(builder: (context) {
                              final weightKg = _weightKg!;
                              final total24 = 4 * weightKg * _total;
                              final first8 = total24 / 2;
                              final remaining16 = total24 / 2;
                              final hours = _hoursSinceBurn;
                              final elapsedFirst8 = hours == null ? null : hours.clamp(0, 8).toDouble();
                              final remainingFirst8 = (first8 - _fluidGivenMl).clamp(0, first8).toDouble();
                              final rate = elapsedFirst8 != null && elapsedFirst8 < 8
                                  ? (remainingFirst8 / (8 - elapsedFirst8)).toDouble()
                                  : null;
                              return Column(
                                children: [
                                  _BurnResultRow(label: '24-hour volume', value: _formatMl(total24)),
                                  _BurnResultRow(label: 'First 8 hours', value: _formatMl(first8)),
                                  _BurnResultRow(label: 'Remaining 16 hours', value: _formatMl(remaining16)),
                                  if (_fluidGivenMl > 0)
                                    _BurnResultRow(label: 'Remaining first-8-hour volume', value: _formatMl(remainingFirst8)),
                                  if (rate != null)
                                    _BurnResultRow(label: 'Calculated rate for remaining first-8-hour period', value: '${_formatMl(rate)}/hr'),
                                ],
                              );
                            }),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'Parkland formula is a starting estimate. Actual fluid administration should be adjusted to the patient’s clinical response and your current burn-resuscitation protocol. For children, maintenance fluids may also be required.',
                            style: TextStyle(fontSize: 12, color: muted, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(onPressed: _clear, icon: const Icon(Icons.refresh_rounded), label: const Text('Clear')),
                const SizedBox(height: 14),
                Text('Adult Rule of Nines estimate. This is not a substitute for a detailed burn assessment. For pediatric patients or irregular/small burns, use the appropriate clinical method and current approved protocols.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMl(double value) {
  if (value >= 100) {
    return '${value.round()} mL';
  }
  return '${value.toStringAsFixed(1)} mL';
}

class _BurnResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _BurnResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: muted, fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class PediatricEmergencyPage extends StatefulWidget {
  const PediatricEmergencyPage({super.key});

  @override
  State<PediatricEmergencyPage> createState() => _PediatricEmergencyPageState();
}

class _PediatricEmergencyPageState extends State<PediatricEmergencyPage> {
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  _PediatricZone? _zone;
  bool _useMeasuredWeight = false;
  bool _lengthInches = false;
  bool _weightPounds = false;
  final Set<String> _expandedClinicalCards = <String>{};

  static const List<_PediatricZone> _zones = [
    _PediatricZone('Gray', 46.8, 59.1, 3, 5, 'Newborn–2 months'),
    _PediatricZone('Pink', 59.2, 66.8, 6, 7, '4 months'),
    _PediatricZone('Red', 66.9, 74.1, 8, 9, '8 months'),
    _PediatricZone('Purple', 74.2, 83.7, 10, 11, '1 year'),
    _PediatricZone('Yellow', 83.8, 95.3, 12, 14, '2 years'),
    _PediatricZone('White', 95.4, 108.2, 15, 18, '4 years'),
    _PediatricZone('Blue', 108.3, 121.4, 19, 23, '6 years'),
    _PediatricZone('Orange', 121.5, 130.6, 24, 29, '8 years'),
    _PediatricZone('Green', 130.7, 143.3, 30, 36, '10 years'),
  ];

  @override
  void dispose() {
    _lengthController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _setLengthUnit(bool inches) {
    if (_lengthInches == inches) return;
    final value = double.tryParse(_lengthController.text.trim());
    setState(() {
      if (value != null) {
        final converted = inches ? value / 2.54 : value * 2.54;
        _lengthController.text = converted.toStringAsFixed(1);
      }
      _lengthInches = inches;
    });
    _lookup();
  }

  void _setWeightUnit(bool pounds) {
    if (_weightPounds == pounds) return;
    final value = double.tryParse(_weightController.text.trim());
    setState(() {
      if (value != null) {
        final converted = pounds ? value / 0.45359237 : value * 0.45359237;
        _weightController.text = converted.toStringAsFixed(1);
      }
      _weightPounds = pounds;
    });
  }

  void _lookup() {
    final enteredLength = double.tryParse(_lengthController.text.trim());
    final length = enteredLength == null
        ? null
        : (_lengthInches ? enteredLength * 2.54 : enteredLength);
    if (length == null || length <= 0) {
      setState(() => _zone = null);
      return;
    }

    _PediatricZone? match;
    for (final zone in _zones) {
      if (length >= zone.minCm && length <= zone.maxCm) {
        match = zone;
        break;
      }
    }
    setState(() => _zone = match);
  }

  double? get _measuredWeight {
    final value = double.tryParse(_weightController.text.trim());
    if (value == null || value <= 0) return null;
    return _weightPounds ? value * 0.45359237 : value;
  }

  double? get _clinicalWeight {
    final measured = _measuredWeight;
    if (_useMeasuredWeight && measured != null) return measured;
    if (_zone == null) return null;
    return (_zone!.minKg + _zone!.maxKg) / 2;
  }

  void _clear() {
    _lengthController.clear();
    _weightController.clear();
    _ageController.clear();
    setState(() {
      _zone = null;
      _useMeasuredWeight = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final measured = _measuredWeight;
    final weight = _clinicalWeight;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Text('Pediatric Emergency', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Length-based pediatric clinical reference', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Child Length', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _lengthController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => _lookup(),
                                decoration: InputDecoration(
                                  labelText: _lengthInches ? 'Length in inches' : 'Length in centimeters',
                                  suffixText: _lengthInches ? 'in' : 'cm',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ToggleButtons(
                              isSelected: [_lengthInches == false, _lengthInches == true],
                              onPressed: (index) => _setLengthUnit(index == 1),
                              borderRadius: BorderRadius.circular(8),
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              children: const [Text('cm', style: TextStyle(fontWeight: FontWeight.w700)), Text('in', style: TextStyle(fontWeight: FontWeight.w700))],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text('For a length-based lookup, measure the child supine from the top of the head to the heel.'),
                      ],
                    ),
                  ),
                ),
                if (_zone != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(color: _zone!.color, borderRadius: BorderRadius.circular(12)),
                            child: Text(_zone!.name.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _zone!.textColor)),
                          ),
                          const SizedBox(height: 16),
                          _resultRow('Estimated weight', _formatWeightRange(_zone!.minKg, _zone!.maxKg)),
                          _resultRow('Age reference', _zone!.age),
                          _resultRow('Length range', _formatLengthRange(_zone!)),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_lengthController.text.trim().isNotEmpty && _zone == null) ...[
                  const SizedBox(height: 12),
                  Card(child: Padding(padding: const EdgeInsets.all(18), child: Text('No zone found in this prototype reference range. Recheck the measurement.', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700)))),
                ],
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Measured Weight Override', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: _weightPounds ? 'Measured weight in pounds' : 'Measured weight in kilograms',
                                  suffixText: _weightPounds ? 'lb' : 'kg',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ToggleButtons(
                              isSelected: [_weightPounds == false, _weightPounds == true],
                              onPressed: (index) => _setWeightUnit(index == 1),
                              borderRadius: BorderRadius.circular(8),
                              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                              children: const [Text('kg', style: TextStyle(fontWeight: FontWeight.w700)), Text('lb', style: TextStyle(fontWeight: FontWeight.w700))],
                            ),
                          ],
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Use measured weight for calculations'),
                          subtitle: Text(measured == null ? 'Enter a measured weight to enable this option.' : '${measured.toStringAsFixed(1)} kg available'),
                          value: _useMeasuredWeight && measured != null,
                          onChanged: measured == null ? null : (value) => setState(() => _useMeasuredWeight = value),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_zone != null) ...[
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'AIRWAY',
                    icon: Icons.air,
                    children: [
                      _infoLine('Cuffed ETT', 'Age-based formula: (age ÷ 4) + 3.5 mm'),
                      _infoLine('Uncuffed ETT', 'Age-based formula: (age ÷ 4) + 4.0 mm'),
                      _infoLine('ETT depth', 'Approximate oral depth: 3 × ETT internal diameter'),
                      const SizedBox(height: 8),
                      Text('Optional age input can calculate the age-based ETT size.', style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ageController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Age in years (optional)', suffixText: 'yr', border: OutlineInputBorder()),
                      ),
                      if (double.tryParse(_ageController.text.trim()) != null) ...[
                        const SizedBox(height: 10),
                        _resultRow('Cuffed ETT', '${(double.parse(_ageController.text.trim()) / 4 + 3.5).toStringAsFixed(1)} mm'),
                        _resultRow('Uncuffed ETT', '${(double.parse(_ageController.text.trim()) / 4 + 4).toStringAsFixed(1)} mm'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'RESUSCITATION',
                    icon: Icons.monitor_heart,
                    children: [
                      _expandableClinicalCard(
                        id: 'aha-defib-1',
                        title: 'Defibrillation — first shock',
                        summary: '2 J/kg',
                        details: const [
                          _ClinicalDetail('Calculation', '2 J/kg × clinical weight'),
                          _ClinicalDetail('Route', 'Defibrillation'),
                          _ClinicalDetail('Reference', '2025 AHA PALS cardiac arrest algorithm'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight * 2)} J',
                      ),
                      _expandableClinicalCard(
                        id: 'aha-defib-2',
                        title: 'Defibrillation — second shock',
                        summary: '4 J/kg',
                        details: const [
                          _ClinicalDetail('Calculation', '4 J/kg × clinical weight'),
                          _ClinicalDetail('Route', 'Defibrillation'),
                          _ClinicalDetail('Reference', '2025 AHA PALS cardiac arrest algorithm'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight * 4)} J',
                      ),
                      _expandableClinicalCard(
                        id: 'aha-defib-subsequent',
                        title: 'Defibrillation — subsequent shocks',
                        summary: '≥4 J/kg; maximum 10 J/kg or adult dose',
                        details: const [
                          _ClinicalDetail('Calculation', 'At least 4 J/kg × clinical weight'),
                          _ClinicalDetail('Maximum', '10 J/kg or adult dose'),
                          _ClinicalDetail('Reference', '2025 AHA PALS cardiac arrest algorithm'),
                        ],
                        calculated: weight == null ? null : 'Minimum ${_formatNumber(weight * 4)} J • Maximum ${_formatNumber(weight * 10)} J',
                      ),
                      _expandableClinicalCard(
                        id: 'aha-epi',
                        title: 'Epinephrine',
                        summary: '0.01 mg/kg IV/IO • 0.1 mg/mL',
                        details: const [
                          _ClinicalDetail('Indication', 'Pediatric cardiac arrest'),
                          _ClinicalDetail('Dose', '0.01 mg/kg IV/IO'),
                          _ClinicalDetail('Concentration', '0.1 mg/mL'),
                          _ClinicalDetail('Maximum', '1 mg'),
                          _ClinicalDetail('Route', 'IV/IO'),
                          _ClinicalDetail('Reference', '2025 AHA PALS cardiac arrest algorithm'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight * 0.01)} mg • ${_formatNumber((weight * 0.01) / 0.1)} mL',
                      ),
                      _expandableClinicalCard(
                        id: 'aha-amiodarone',
                        title: 'Amiodarone',
                        summary: '5 mg/kg IV/IO bolus',
                        details: const [
                          _ClinicalDetail('Indication', 'Shock-refractory VF/pulseless VT during pediatric cardiac arrest'),
                          _ClinicalDetail('Dose', '5 mg/kg IV/IO bolus'),
                          _ClinicalDetail('Maximum', '300 mg initial; subsequent doses max 150 mg'),
                          _ClinicalDetail('Route', 'IV/IO'),
                          _ClinicalDetail('Reference', '2025 AHA PALS cardiac arrest algorithm'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight * 5)} mg',
                      ),
                      _expandableClinicalCard(
                        id: 'aha-lido',
                        title: 'Lidocaine',
                        summary: '1 mg/kg IV/IO',
                        details: const [
                          _ClinicalDetail('Indication', 'Shock-refractory VF/pulseless VT during pediatric cardiac arrest'),
                          _ClinicalDetail('Dose', '1 mg/kg IV/IO'),
                          _ClinicalDetail('Route', 'IV/IO'),
                          _ClinicalDetail('Reference', '2025 AHA PALS cardiac arrest algorithm'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight)} mg',
                      ),
                      const SizedBox(height: 6),
                      const Text('AHA values are based on the 2025 PALS cardiac arrest algorithm. Verify your current protocol and medication concentration before administration.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'BAXTER PEDIATRIC MEDICATIONS',
                    icon: Icons.medication_outlined,
                    children: [
                      _expandableClinicalCard(
                        id: 'baxter-zofran',
                        title: 'Zofran (ondansetron)',
                        summary: '0.1–0.15 mg/kg',
                        details: const [
                          _ClinicalDetail('Indication', 'Nausea/vomiting; protocol states Zofran should routinely be used as first-line anti-emetic'),
                          _ClinicalDetail('Dose', '0.1–0.15 mg/kg slowly IV; protocol also lists 0.1–0.15 mg/kg per medical control'),
                          _ClinicalDetail('Concentration', '4 mg/2 mL (2 mg/mL)'),
                          _ClinicalDetail('Route', 'IV'),
                          _ClinicalDetail('Protocol source', 'Baxter 2021 protocol set'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight * 0.1)}–${_formatNumber(weight * 0.15)} mg • ${_formatNumber(weight * 0.1 / 2)}–${_formatNumber(weight * 0.15 / 2)} mL',
                      ),
                      _expandableClinicalCard(
                        id: 'baxter-fentanyl',
                        title: 'Fentanyl',
                        summary: '1 mcg/kg IV/IO/IM/IN • may repeat ×1',
                        details: const [
                          _ClinicalDetail('Indication', 'Severe pain; protocol identifies fentanyl as first choice for severe pain'),
                          _ClinicalDetail('Dose', '1 mcg/kg IV/IO/IM/IN; may repeat ×1'),
                          _ClinicalDetail('Concentration', '100 mcg/2 mL (50 mcg/mL)'),
                          _ClinicalDetail('Route', 'IV/IO/IM/IN'),
                          _ClinicalDetail('Protocol source', 'Baxter 2021 protocol set'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight)} mcg • ${_formatNumber(weight / 50)} mL',
                      ),
                      _expandableClinicalCard(
                        id: 'baxter-morphine',
                        title: 'Morphine',
                        summary: '0.05 mg/kg IV/IO/IN • max 5 mg',
                        details: const [
                          _ClinicalDetail('Indication', 'Severe pain; protocol identifies morphine as second choice for severe pain'),
                          _ClinicalDetail('Dose', '0.05 mg/kg IV/IO/IN'),
                          _ClinicalDetail('Maximum', '5 mg for pediatrics'),
                          _ClinicalDetail('Concentration', '5 mg/1 mL (5 mg/mL)'),
                          _ClinicalDetail('Route', 'IV/IO/IN'),
                          _ClinicalDetail('Protocol source', 'Baxter 2021 protocol set'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber((weight * 0.05).clamp(0, 5))} mg • ${_formatNumber((weight * 0.05).clamp(0, 5) / 5)} mL',
                      ),
                      _expandableClinicalCard(
                        id: 'baxter-ketamine',
                        title: 'Ketamine',
                        summary: '0.1 mg/kg IV/IM/IN',
                        details: const [
                          _ClinicalDetail('Indication', 'Moderate pain; pediatric dose listed in the pain-control protocol'),
                          _ClinicalDetail('Dose', '0.1 mg/kg IV/IM/IN'),
                          _ClinicalDetail('Concentration', '50 mg/2 mL (25 mg/mL)'),
                          _ClinicalDetail('Route', 'IV/IM/IN'),
                          _ClinicalDetail('Protocol source', 'Baxter 2021 protocol set'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight * 0.1)} mg • ${_formatNumber(weight * 0.1 / 25)} mL',
                      ),
                      _expandableClinicalCard(
                        id: 'baxter-lido-rsi',
                        title: 'Lidocaine — RSI blunting',
                        summary: '1.5 mg/kg IV push',
                        details: const [
                          _ClinicalDetail('Indication', 'RSI blunting; protocol notes consideration for “Tight Brain”'),
                          _ClinicalDetail('Dose', '1.5 mg/kg IV push'),
                          _ClinicalDetail('Concentration', '100 mg/5 mL (20 mg/mL)'),
                          _ClinicalDetail('Route', 'IV push'),
                          _ClinicalDetail('Protocol source', 'Baxter 2021 protocol set'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight * 1.5)} mg • ${_formatNumber(weight * 1.5 / 20)} mL',
                      ),
                      _expandableClinicalCard(
                        id: 'baxter-fluid',
                        title: 'Normal Saline / Lactated Ringer’s bolus',
                        summary: '20 mL/kg',
                        details: const [
                          _ClinicalDetail('Indication', 'Fluid challenge / hypotension reference in the Baxter protocol set'),
                          _ClinicalDetail('Dose', '20 mL/kg'),
                          _ClinicalDetail('Route', 'IV/IO'),
                          _ClinicalDetail('Protocol source', 'Baxter 2021 protocol set'),
                        ],
                        calculated: weight == null ? null : '${_formatNumber(weight * 20)} mL',
                      ),
                      const SizedBox(height: 6),
                      const Text('Baxter medication entries are derived from the loaded 2021 protocol set and should be treated as historical protocol content until replaced with your current approved protocol set.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'IMPORTANT',
                    icon: Icons.warning_amber_rounded,
                    children: [
                      const Text('Length-based weight is an estimate. The dose calculations above use the measured weight when the override is enabled; otherwise they use the midpoint of the prototype zone weight range.'),
                      const SizedBox(height: 8),
                      const Text('This tool is a clinical reference aid, not a substitute for current approved protocols, medical direction, or verification of medication concentration and equipment size.'),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(onPressed: _clear, icon: const Icon(Icons.clear), label: const Text('Clear')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 24), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), const SizedBox(width: 12), Expanded(child: Text(value, textAlign: TextAlign.right))]),
    );
  }

  Widget _doseCard(String title, String formula, double? dose, String unit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(formula),
          if (dose != null) ...[
            const SizedBox(height: 6),
            Text('${dose.toStringAsFixed(dose < 10 ? 2 : 1)} $unit', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ]),
      ),
    );
  }

  Widget _baxterDose(String title, String formula, double? weight, {String unit = 'mg', double? maxMg}) {
    double? dose;
    String display = 'Enter length or measured weight';
    if (weight != null) {
      final match = RegExp(r'([0-9.]+)(?:–|-)([0-9.]+)').firstMatch(formula);
      if (match != null) {
        final low = weight * double.parse(match.group(1)!);
        final high = weight * double.parse(match.group(2)!);
        display = '${low.toStringAsFixed(2)}–${high.toStringAsFixed(2)} $unit';
      } else {
        final matchSingle = RegExp(r'([0-9.]+)').firstMatch(formula);
        if (matchSingle != null) {
          dose = weight * double.parse(matchSingle.group(1)!);
          if (maxMg != null && dose > maxMg) dose = maxMg;
          display = '${dose.toStringAsFixed(dose < 10 ? 2 : 1)} $unit';
        }
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(formula),
          const SizedBox(height: 6),
          Text(display, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  Widget _expandableClinicalCard({
    required String id,
    required String title,
    required String summary,
    required List<_ClinicalDetail> details,
    String? calculated,
  }) {
    final expanded = _expandedClinicalCards.contains(id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          if (expanded) {
            _expandedClinicalCards.remove(id);
          } else {
            _expandedClinicalCards.add(id);
          }
        }),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(summary),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              if (calculated != null) ...[
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Calculated: $calculated',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
              if (expanded) ...[
                const Divider(height: 20),
                ...details.map((detail) => _clinicalDetailRow(detail.label, detail.value)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _clinicalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value.abs() >= 10) return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    if (value.abs() >= 1) return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatWeightRange(double minKg, double maxKg) {
    if (!_weightPounds) return '${minKg.toStringAsFixed(0)}–${maxKg.toStringAsFixed(0)} kg';
    return '${(minKg / 0.45359237).toStringAsFixed(1)}–${(maxKg / 0.45359237).toStringAsFixed(1)} lb';
  }

  String _formatLengthRange(_PediatricZone zone) {
    if (_lengthInches) return '${(zone.minCm / 2.54).toStringAsFixed(1)}–${(zone.maxCm / 2.54).toStringAsFixed(1)} in';
    return '${zone.minCm.toStringAsFixed(1)}–${zone.maxCm.toStringAsFixed(1)} cm';
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), const SizedBox(width: 12), Expanded(child: Text(value, textAlign: TextAlign.right))]),
    );
  }
}

class _ClinicalDetail {
  final String label;
  final String value;
  const _ClinicalDetail(this.label, this.value);
}

class _PediatricZone {
  final String name;
  final double minCm;
  final double maxCm;
  final double minKg;
  final double maxKg;
  final String age;

  const _PediatricZone(
    this.name,
    this.minCm,
    this.maxCm,
    this.minKg,
    this.maxKg,
    this.age,
  );

  Color get color {
    switch (name) {
      case 'Gray':
        return const Color(0xFFBDBDBD);
      case 'Pink':
        return const Color(0xFFF48FB1);
      case 'Red':
        return const Color(0xFFE53935);
      case 'Purple':
        return const Color(0xFF8E5BAA);
      case 'Yellow':
        return const Color(0xFFFFD54F);
      case 'White':
        return const Color(0xFFF5F5F5);
      case 'Blue':
        return const Color(0xFF64B5F6);
      case 'Orange':
        return const Color(0xFFFFA726);
      case 'Green':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  Color get textColor {
    switch (name) {
      case 'Red':
      case 'Purple':
        return Colors.white;
      default:
        return Colors.black87;
    }
  }
}

class WeightConversionPage extends StatefulWidget {
  const WeightConversionPage({super.key});

  @override
  State<WeightConversionPage> createState() => _WeightConversionPageState();
}

class _WeightConversionPageState extends State<WeightConversionPage> {
  final TextEditingController _lbsController = TextEditingController();
  String? _kgResult;

  @override
  void dispose() {
    _lbsController.dispose();
    super.dispose();
  }

  void _convert() {
    final lbs = double.tryParse(_lbsController.text.trim());
    setState(() {
      if (lbs == null || lbs < 0) {
        _kgResult = null;
      } else {
        final kg = lbs * 0.45359237;
        _kgResult = kg.toStringAsFixed(2);
      }
    });
  }

  void _clear() {
    _lbsController.clear();
    setState(() => _kgResult = null);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final error = Theme.of(context).colorScheme.error;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_weight_rounded, color: primary, size: 30),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Weight Conversion',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Convert pounds (lb) to kilograms (kg).',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _lbsController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _convert(),
                          decoration: InputDecoration(
                            labelText: 'Weight in pounds',
                            hintText: 'Enter lb',
                            suffixText: 'lb',
                            prefixIcon: const Icon(Icons.scale_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _convert,
                                icon: const Icon(Icons.calculate_rounded),
                                label: const Text('Convert'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: _clear,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        if (_lbsController.text.isNotEmpty &&
                            _kgResult == null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Enter a valid weight of 0 lb or greater.',
                            style: TextStyle(color: error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_kgResult != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '$_kgResult kg',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_lbsController.text.trim()} lb = $_kgResult kg',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Conversion: 1 lb = 0.45359237 kg. This tool is a unit converter and does not determine clinical dosing.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UsefulInformationPage extends StatelessWidget {
  const UsefulInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Text(
                  'Useful Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.local_shipping_rounded, color: primary, size: 58, iconSize: 28),
                    title: const Text(
                      'Transfer Protocol',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Baxter Health transfer order and coverage.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransferProtocolPage(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: BaxterIconBadge(icon: Icons.phone_rounded, color: primary, size: 58, iconSize: 28),
                    title: const Text(
                      'Phone Numbers',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Important contact numbers.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhoneNumbersPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PhoneNumbersPage extends StatelessWidget {
  const PhoneNumbersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const Text(
                  'Phone Numbers',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.phone_in_talk_rounded,
                          size: 52,
                          color: primary,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Phone numbers will be added here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This section is a placeholder for important EMS, hospital, medical control, and other contact numbers.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TransferProtocolPage extends StatelessWidget {
  const TransferProtocolPage({super.key});

  Widget _scheduleColumn(
    BuildContext context,
    String title,
    List<String> lines,
  ) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            SizedBox(
              height: 34,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    color: textColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 10),
            child: Text(
              '•',
              style: TextStyle(fontSize: 18, color: textColor),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        const Text(
                          'Baxter Health',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Transfer Order',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _scheduleColumn(context, '4 ALS', transfer4Als),
                            const SizedBox(width: 32),
                            _scheduleColumn(context, '5 ALS', transfer5Als),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          transferBasicHours,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _bullet(context, transferBullet1),
                        _bullet(context, transferBullet2),
                        _bullet(context, transferBullet3),
                        _bullet(context, transferBullet4),
                        _bullet(context, transferBullet5),
                        const SizedBox(height: 6),
                        Text(
                          transferContactText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            transferUpdatedDate,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProtocolStudyPage extends StatefulWidget {
  const ProtocolStudyPage({super.key});

  @override
  State<ProtocolStudyPage> createState() => _ProtocolStudyPageState();
}

class _ProtocolStudyPageState extends State<ProtocolStudyPage> {
  final Random _random = Random();
  late List<_EducationQuestion> _questionPool;
  int _score = 0;
  int _answeredCount = 0;
  bool _answered = false;
  int? _selectedIndex;
  _EducationQuestion? _currentQuestion;

  @override
  void initState() {
    super.initState();
    _questionPool = _buildQuestionPool();
    _questionPool.shuffle(_random);
    _currentQuestion = _questionPool.removeLast();
  }

  List<_EducationQuestion> _buildQuestionPool() {
    final questions = <_EducationQuestion>[];
    final sections = <_EducationProtocolSection>[];

    final labelPattern = RegExp(
      r'^\s*(Effects|Effect|Indications|Contraindications|Contraindication|Adverse Reactions|Precautions|Side Effects|Dose|Dosage|Adult Dose|Pedi Dose|Pediatric Dose|Procedure|Procedures|Actions|Considerations|Medical Control|Guidelines of Care|Notes|Note|Competency|Quality Improvement/Key Documentation Elements|Performance Measures \(Process, Structure, and Outcomes\)|Treatment and Interventions|Treatment)\s*:\s*(.*)$',
      caseSensitive: false,
    );

    for (final protocol in allProtocols) {
      String? currentLabel;
      final buffer = <String>[];
      void flush() {
        if (currentLabel == null) return;
        final text = _normalizeEducationText(buffer.join(' '));
        if (text.length >= 12) {
          sections.add(_EducationProtocolSection(protocol.title, currentLabel!, text));
        }
        buffer.clear();
      }

      for (final rawLine in protocol.content.split('\n')) {
        final match = labelPattern.firstMatch(rawLine);
        if (match != null) {
          flush();
          currentLabel = match.group(1)!.trim();
          final first = match.group(2)!.trim();
          if (first.isNotEmpty) buffer.add(first);
        } else if (currentLabel != null) {
          final line = rawLine.trim();
          if (line.isNotEmpty) buffer.add(line);
        }
      }
      flush();
    }

    // Question style 1: identify what the source protocol lists in a section.
    for (final section in sections) {
      final distractors = sections
          .where((s) => s.label.toLowerCase() == section.label.toLowerCase() && s.text != section.text)
          .map((s) => s.text)
          .toSet()
          .toList();
      if (distractors.length >= 3) {
        distractors.shuffle(_random);
        final options = <String>[section.text, distractors[0], distractors[1], distractors[2]];
        options.shuffle(_random);
        questions.add(_EducationQuestion(
          question: 'According to "${section.protocolTitle}", what is listed under ${section.label}?',
          options: options.map(_shortenEducationOption).toList(),
          answerIndex: options.indexOf(section.text),
          reference: '${section.protocolTitle} — ${section.label}',
        ));
      }
    }

    // Question style 2: identify which protocol contains a source-derived statement.
    for (final section in sections) {
      final snippet = _educationSnippet(section.text);
      if (snippet.length < 12) continue;
      final otherTitles = sections
          .where((s) => s.protocolTitle != section.protocolTitle)
          .map((s) => s.protocolTitle)
          .toSet()
          .toList();
      if (otherTitles.length >= 3) {
        otherTitles.shuffle(_random);
        final options = <String>[section.protocolTitle, otherTitles[0], otherTitles[1], otherTitles[2]];
        options.shuffle(_random);
        questions.add(_EducationQuestion(
          question: 'Which protocol lists this under ${section.label}: "$snippet"?',
          options: options,
          answerIndex: options.indexOf(section.protocolTitle),
          reference: '${section.protocolTitle} — ${section.label}',
        ));
      }
    }

    return questions;
  }

  String _normalizeEducationText(String text) {
    return text
        .replaceAll('', '•')
        .replaceAll('', '•')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _educationSnippet(String text) {
    final normalized = _normalizeEducationText(text);
    final sentence = normalized.split(RegExp(r'(?<=[.!?])\s+')).first;
    return _shortenEducationOption(sentence);
  }

  String _shortenEducationOption(String text) {
    final normalized = _normalizeEducationText(text);
    if (normalized.length <= 180) return normalized;
    return '${normalized.substring(0, 177).trimRight()}...';
  }

  void _selectAnswer(int index) {
    if (_answered || _currentQuestion == null) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      _answeredCount++;
      if (index == _currentQuestion!.answerIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion == null) return;
    setState(() {
      if (_questionPool.isEmpty) {
        _questionPool = _buildQuestionPool();
        _questionPool.shuffle(_random);
      }
      _currentQuestion = _questionPool.removeLast();
      _answered = false;
      _selectedIndex = null;
    });
  }

  static const String _lifepak35Url =
      'https://ec.stryker-learning.com/resources/category/LIFEPAK%2035';

  static const String _tlcUrl =
      'https://login.healthstream.com/hstmsts/MobileLogin.aspx?ReturnUrl=%2fHSTMSTS%2fusers%2fissue.aspx%3fwa%3dwsignin1.0%26wtrealm%3dhttp%253a%252f%252fwww.healthstream.com%252fhlc%26wctx%3drm%253d0%2526id%253dpassive%2526ru%253d%25252fHLC%25252fLogin%25252fLogin.aspx%25253forganizationID%25253de4b9e57c-0d7e-df11-98c2-00151729cb2f%26wct%3d2023-07-06T15%253a10%253a06Z%26wreply%3dhttps%253a%252f%252fwww.healthstream.com%252fHLC%252flogin%252flogin.aspx%26sts_OrgId%3de4b9e57c-0d7e-df11-98c2-00151729cb2f&sts_OrgId=e4b9e57c-0d7e-df11-98c2-00151729cb2f&sts_OrgNodeId=00000000-0000-0000-0000-000000000000&wtrealm=http%3a%2f%2fwww.healthstream.com%2fhlc';

  Future<void> _openTlc() async {
    final uri = Uri.parse(_tlcUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open TLC.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open TLC.')),
      );
    }
  }

  Widget _buildStudyView(BuildContext context) {
    final question = _currentQuestion!;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protocol Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                ...List.generate(question.options.length, (i) {
                  final isCorrect = i == question.answerIndex;
                  final isSelected = i == _selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () => _selectAnswer(i),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(question.options[i])),
                          if (_answered && isCorrect)
                            const Icon(Icons.check_circle_rounded, color: Colors.green),
                          if (_answered && isSelected && !isCorrect)
                            const Icon(Icons.cancel_rounded, color: Colors.red),
                        ],
                      ),
                    ),
                  );
                }),
                if (_answered) ...[
                  const SizedBox(height: 4),
                  Text(
                    _selectedIndex == question.answerIndex
                        ? 'Correct.'
                        : 'Review the protocol section for the correct answer.',
                    style: TextStyle(
                      color: _selectedIndex == question.answerIndex
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reference: ${question.reference}',
                    style: TextStyle(
                      fontSize: 13,
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next Question'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: BaxterIconBadge(icon: Icons.scoreboard_rounded, color: primary, size: 58, iconSize: 28),
            title: const Text(
              'Current Score',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('$_score correct out of $_answeredCount answered'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Education content in this prototype is based on the currently loaded 2021 protocol set. Questions are generated from the loaded protocol text and are intended for study and review; always verify against the current approved protocols before clinical use.',
          style: TextStyle(
            fontSize: 13,
            color: onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_rounded, color: primary, size: 30),
                    const SizedBox(width: 10),
                    const Text(
                      'Study the Current Protocol',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Study the current protocol set with source-based review questions.',
                  style: TextStyle(
                    fontSize: 15,
                    color: onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildStudyView(context)),
        ],
      ),
    );
  }
}

class EducationPage extends StatelessWidget {
  const EducationPage({super.key});

  static const String _lifepak35Url =
      'https://ec.stryker-learning.com/resources/category/LIFEPAK%2035';

  static const String _tlcUrl =
      'https://login.healthstream.com/hstmsts/MobileLogin.aspx?ReturnUrl=%2fHSTMSTS%2fusers%2fissue.aspx%3fwa%3dwsignin1.0%26wtrealm%3dhttp%253a%252f%252fwww.healthstream.com%252fhlc%26wctx%3drm%253d0%2526id%253dpassive%2526ru%253d%25252fHLC%25252fLogin%25252fLogin.aspx%25253forganizationID%253de4b9e57c-0d7e-df11-98c2-00151729cb2f%26wct%3d2023-07-06T15%253a10%253a06Z%26wreply%3dhttps%253a%252f%252fwww.healthstream.com%252fHLC%252flogin%252flogin.aspx%26sts_OrgId%3de4b9e57c-0d7e-df11-98c2-00151729cb2f&sts_OrgId=e4b9e57c-0d7e-df11-98c2-00151729cb2f&sts_OrgNodeId=00000000-0000-0000-0000-000000000000&wtrealm=http%3a%2f%2fwww.healthstream.com%2fhlc';

  Future<void> _openTlc(BuildContext context) async {
    final uri = Uri.parse(_tlcUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open TLC.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open TLC.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_rounded, color: primary, size: 30),
                    const SizedBox(width: 10),
                    const Text(
                      'Education',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Study the current protocol set or access TLC training.',
                  style: TextStyle(
                    fontSize: 15,
                    color: onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    leading: BaxterIconBadge(icon: Icons.menu_book_rounded, color: primary, size: 58, iconSize: 28),
                    title: const Text(
                      'Study the Current Protocol',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Review and quiz yourself on the current protocol set.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProtocolStudyPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    leading: BaxterIconBadge(icon: Icons.school_rounded, color: primary, size: 58, iconSize: 28),
                    title: const Text(
                      'TLC',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Access TLC training through HealthStream.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openTlc(context),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    leading: BaxterIconBadge(icon: Icons.school_rounded, color: primary, size: 58, iconSize: 28),
                    title: const Text(
                      'Training Academy',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Build clinical knowledge with focused EMS training modules.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TrainingAcademyPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    leading: BaxterIconBadge(icon: Icons.monitor_heart_rounded, color: primary, size: 58, iconSize: 28),
                    title: const Text(
                      'LIFEPAK 35',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Access LIFEPAK 35 training resources through Stryker.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final uri = Uri.parse(EducationPage._lifepak35Url);
                      try {
                        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unable to open LIFEPAK 35 training.')),
                          );
                        }
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to open LIFEPAK 35 training.')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class TrainingAcademyPage extends StatefulWidget {
  final String? initialAcademy;

  const TrainingAcademyPage({super.key, this.initialAcademy});

  @override
  State<TrainingAcademyPage> createState() => _TrainingAcademyPageState();
}

class _TrainingAcademyPageState extends State<TrainingAcademyPage> {
  static const _academies = [
    'ECG Academy',
    'Medication Academy',
    'Airway Academy',
    'Cardiac Arrest Academy',
    'Stroke Academy',
    'Pediatric Academy',
    'Trauma Academy',
    'OB / Neonatal Academy',
  ];

  static const _descriptions = {
    'ECG Academy': 'Learn ECG fundamentals, rhythms, intervals, and 12-lead concepts.',
    'Medication Academy': 'Build medication knowledge with focused EMS drug lessons.',
    'Airway Academy': 'Review airway assessment, ventilation, and advanced airway concepts.',
    'Cardiac Arrest Academy': 'Review cardiac arrest assessment, rhythms, and resuscitation concepts.',
    'Stroke Academy': 'Review stroke recognition, assessment, and time-critical considerations.',
    'Pediatric Academy': 'Build confidence with pediatric assessment and emergency care concepts.',
    'Trauma Academy': 'Review trauma assessment, hemorrhage, shock, and common trauma emergencies.',
    'OB / Neonatal Academy': 'Review delivery, obstetric emergencies, and neonatal assessment concepts.',
  };

  static const _icons = {
    'ECG Academy': Icons.monitor_heart_rounded,
    'Medication Academy': Icons.medication_rounded,
    'Airway Academy': Icons.air_rounded,
    'Cardiac Arrest Academy': Icons.favorite_rounded,
    'Stroke Academy': Icons.psychology_rounded,
    'Pediatric Academy': Icons.child_care_rounded,
    'Trauma Academy': Icons.healing_rounded,
    'OB / Neonatal Academy': Icons.pregnant_woman_rounded,
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialAcademy != null && _academies.contains(widget.initialAcademy)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openAcademy(widget.initialAcademy!);
      });
    }
  }

  void _openAcademy(String academy) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrainingAcademyDetailPage(academy: academy),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_rounded, color: primary, size: 30),
                    const SizedBox(width: 10),
                    const Text(
                      'Training Academy',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Focused EMS education and skills review.',
                  style: TextStyle(fontSize: 15, color: onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: _academies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final academy = _academies[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    leading: BaxterIconBadge(icon: _icons[academy]!, color: primary, size: 58, iconSize: 28),
                    title: Text(
                      academy,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(_descriptions[academy]!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openAcademy(academy),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TrainingAcademyDetailPage extends StatefulWidget {
  final String academy;

  const TrainingAcademyDetailPage({super.key, required this.academy});

  @override
  State<TrainingAcademyDetailPage> createState() => _TrainingAcademyDetailPageState();
}

class _TrainingAcademyDetailPageState extends State<TrainingAcademyDetailPage> {
  final Random _random = Random();
  late List<_AcademyQuestion> _questionPool;
  _AcademyQuestion? _currentQuestion;
  int _answeredCount = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _questionPool = _academyQuestions(widget.academy)..shuffle(_random);
    _nextQuestion(initial: true);
  }

  void _nextQuestion({bool initial = false}) {
    if (_questionPool.isEmpty) {
      _questionPool = _academyQuestions(widget.academy)..shuffle(_random);
    }
    final question = _questionPool.removeLast();
    if (initial) {
      _currentQuestion = question;
      return;
    }
    setState(() {
      _currentQuestion = question;
      _answered = false;
      _selectedIndex = null;
    });
  }

  void _selectAnswer(int index) {
    if (_answered || _currentQuestion == null) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      _answeredCount++;
      if (index == _currentQuestion!.answerIndex) _score++;
    });
  }

  List<_AcademyQuestion> _academyQuestions(String academy) {
    switch (academy) {
      case 'ECG Academy':
        return _ecgQuestions();
      case 'Medication Academy':
        return _medicationQuestions();
      case 'Airway Academy':
        return _airwayQuestions();
      case 'Cardiac Arrest Academy':
        return _cardiacArrestQuestions();
      case 'Stroke Academy':
        return _strokeQuestions();
      case 'Pediatric Academy':
        return _pediatricQuestions();
      case 'Trauma Academy':
        return _traumaQuestions();
      case 'OB / Neonatal Academy':
        return _obNeonatalQuestions();
      default:
        return const [];
    }
  }

  _AcademyQuestion q(String question, List<String> options, int answer, String explanation, String reference) {
    return _AcademyQuestion(
      question: question,
      options: options,
      answerIndex: answer,
      explanation: explanation,
      reference: reference,
    );
  }

  List<_AcademyQuestion> _ecgQuestions() => [
    q('What does the P wave represent?', ['Atrial depolarization', 'Ventricular depolarization', 'Atrial repolarization', 'Ventricular repolarization'], 0, 'The P wave represents atrial depolarization.', 'ECG fundamentals'),
    q('What does the QRS complex primarily represent?', ['Atrial contraction', 'Ventricular depolarization', 'Atrial repolarization', 'Ventricular filling'], 1, 'The QRS complex represents ventricular depolarization.', 'ECG fundamentals'),
    q('What does the T wave represent?', ['Atrial depolarization', 'AV nodal conduction', 'Ventricular repolarization', 'Ventricular depolarization'], 2, 'The T wave represents ventricular repolarization.', 'ECG fundamentals'),
    q('Which PR interval is generally considered within the normal adult range?', ['0.02–0.06 sec', '0.08–0.10 sec', '0.12–0.20 sec', '0.24–0.32 sec'], 2, 'A normal adult PR interval is generally 0.12–0.20 seconds.', 'ECG fundamentals'),
    q('A rhythm is irregularly irregular with no consistent P waves. Which rhythm is most characteristic?', ['Atrial fibrillation', 'Sinus rhythm', 'First-degree AV block', 'Ventricular paced rhythm'], 0, 'Atrial fibrillation classically produces an irregularly irregular ventricular rhythm with absent consistent P waves.', 'Rhythm recognition'),
    q('Which finding is most characteristic of a regular narrow-complex tachycardia?', ['QRS duration is always >0.12 sec', 'The ventricular rhythm is regular and QRS complexes are narrow', 'P waves must be absent', 'The rhythm must be ventricular in origin'], 1, 'A regular narrow-complex tachycardia commonly reflects a supraventricular rhythm, although the ECG must be interpreted in clinical context.', 'Tachyarrhythmias'),
    q('Which leads are commonly associated with the inferior wall of the left ventricle?', ['I, aVL, V5, V6', 'V1, V2', 'II, III, aVF', 'V3, V4'], 2, 'Leads II, III, and aVF view the inferior wall.', '12-lead ECG'),
    q('Which leads primarily view the lateral wall?', ['II, III, aVF', 'I, aVL, V5, V6', 'V1, V2', 'V3, V4'], 1, 'Leads I, aVL, V5, and V6 are commonly used to assess the lateral wall.', '12-lead ECG'),
    q('A QRS duration of 0.14 seconds would generally be described as:', ['Narrow', 'Wide', 'Absent', 'Normal PR prolongation'], 1, 'A QRS duration of 0.12 seconds or greater is generally considered wide.', 'ECG fundamentals'),
    q('What is the most useful general approach when interpreting a 12-lead ECG?', ['Look only at lead II', 'Interpret the tracing systematically and correlate it with the patient', 'Ignore the clinical presentation', 'Use heart rate alone to determine the diagnosis'], 1, 'A systematic interpretation paired with the patient presentation is safer than relying on one lead or one measurement.', '12-lead ECG'),
  
    q("What is the normal adult QRS duration generally considered narrow?", ["Less than 0.12 sec", "0.12–0.20 sec", "0.20–0.30 sec", "Greater than 0.30 sec"], 0, "A QRS duration under 0.12 seconds is generally considered narrow.", "ECG fundamentals"),
    q("Which ECG component represents ventricular repolarization?", ["P wave", "PR interval", "QRS complex", "T wave"], 3, "The T wave represents ventricular repolarization.", "ECG fundamentals"),
    q("What does the PR interval primarily represent?", ["Atrial depolarization only", "Conduction from atria through the AV node to the ventricles", "Ventricular repolarization", "Ventricular contraction duration"], 1, "The PR interval reflects conduction from atrial depolarization through the AV node and His-Purkinje system to the ventricles.", "ECG fundamentals"),
    q("A regular rhythm at 72 beats/min with a P wave before every QRS is most consistent with:", ["Sinus rhythm", "Atrial fibrillation", "Ventricular fibrillation", "Asystole"], 0, "A regular rhythm with consistent P waves preceding each QRS is characteristic of sinus rhythm.", "Rhythm recognition"),
    q("Which feature best describes sinus tachycardia?", ["Sinus rhythm with a rate above the expected adult resting range", "No P waves and an irregular rhythm", "Wide-complex rhythm with no pulse", "Chaotic ventricular activity"], 0, "Sinus tachycardia is sinus rhythm occurring at a faster-than-normal rate.", "Rhythm recognition"),
    q("Which feature best describes sinus bradycardia?", ["Sinus rhythm with a slower-than-normal adult rate", "Atrial activity with no ventricular response", "Irregularly irregular rhythm without P waves", "Polymorphic ventricular tachycardia"], 0, "Sinus bradycardia is sinus rhythm with a slower-than-normal rate.", "Rhythm recognition"),
    q("Atrial fibrillation is classically characterized by:", ["Regular rhythm with sawtooth waves", "Irregularly irregular rhythm without consistent P waves", "Wide QRS with a pulse absent", "Regular narrow rhythm with one P wave per QRS"], 1, "Atrial fibrillation is typically irregularly irregular with no consistent organized P waves.", "Atrial fibrillation"),
    q("Atrial flutter classically produces which atrial activity pattern?", ["Sawtooth flutter waves", "Chaotic fibrillatory waves only", "One wide QRS per P wave", "Absent atrial activity"], 0, "Atrial flutter commonly produces organized flutter waves with a sawtooth appearance.", "Atrial flutter"),
    q("Which lead is commonly used to assess inferior myocardial territory?", ["V1", "V2", "II", "aVL"], 2, "Lead II is one of the inferior leads; the inferior territory is assessed with II, III, and aVF.", "12-lead ECG"),
    q("Which leads are commonly associated with the anterior wall?", ["V3 and V4", "II and III", "I and aVL only", "V7 and V8"], 0, "V3 and V4 are commonly considered anterior precordial leads.", "12-lead ECG"),
    q("Which leads are commonly associated with the septal wall?", ["V1 and V2", "V3 and V4", "I and aVL", "II and aVF"], 0, "V1 and V2 are commonly considered septal leads.", "12-lead ECG"),
    q("Which leads are commonly associated with the lateral wall?", ["V1 and V2", "II, III, aVF", "I, aVL, V5, and V6", "V3 and V4 only"], 2, "I, aVL, V5, and V6 are commonly used to assess the lateral wall.", "12-lead ECG"),
    q("What is the usual ventricular response pattern in atrial fibrillation?", ["Regularly regular", "Irregularly irregular", "Always exactly 60 bpm", "Always wide and regular"], 1, "Atrial fibrillation commonly produces an irregularly irregular ventricular response.", "Atrial fibrillation"),
    q("First-degree AV block is identified by:", ["A consistently prolonged PR interval", "Progressive PR shortening", "Dropped QRS complexes with no PR changes", "Wide QRS without atrial activity"], 0, "First-degree AV block is characterized by a prolonged but consistent PR interval.", "AV blocks"),
    q("Mobitz I second-degree AV block is classically associated with:", ["Progressive PR prolongation followed by a dropped beat", "Constant PR intervals with random dropped beats only", "Complete AV dissociation", "No atrial activity"], 0, "Mobitz I classically shows progressive PR prolongation followed by a nonconducted P wave.", "AV blocks"),
    q("Mobitz II second-degree AV block is classically associated with:", ["Progressive PR prolongation before every dropped beat", "Constant PR intervals with intermittent nonconducted P waves", "Atrial fibrillation only", "No P waves"], 1, "Mobitz II has consistent PR intervals with intermittent dropped ventricular complexes.", "AV blocks"),
    q("Complete heart block is characterized by:", ["AV dissociation", "One P wave before every QRS", "Progressive PR shortening only", "No atrial activity"], 0, "In complete AV block, atrial and ventricular activity are dissociated.", "AV blocks"),
    q("Which rhythm is typically described as a wide-complex tachycardia that may be monomorphic or polymorphic?", ["Ventricular tachycardia", "Sinus bradycardia", "First-degree AV block", "Atrial flutter"], 0, "Ventricular tachycardia may be monomorphic or polymorphic and commonly presents as a wide-complex tachycardia.", "Ventricular tachycardia"),
    q("What does ventricular fibrillation represent?", ["Organized atrial activity", "Chaotic ventricular electrical activity without effective mechanical contraction", "A regular narrow-complex rhythm", "A normal sinus rhythm"], 1, "Ventricular fibrillation is chaotic ventricular electrical activity that does not produce effective cardiac output.", "Ventricular fibrillation"),
    q("Asystole is best described as:", ["A normal rhythm with absent P waves", "Absence of discernible ventricular electrical activity", "A regular wide-complex rhythm", "Atrial flutter with slow conduction"], 1, "Asystole is the absence of discernible ventricular electrical activity; artifact must be excluded.", "Cardiac arrest rhythms"),
    q("PEA means:", ["Pulsed electrical activity", "Pulseless electrical activity", "Premature electrical acceleration", "Periodic electrical alternation"], 1, "PEA is pulseless electrical activity: organized electrical activity without a palpable pulse.", "Cardiac arrest rhythms"),
    q("Why should artifact be considered when interpreting a concerning ECG?", ["Artifact can mimic or obscure rhythms", "Artifact always means VF", "Artifact proves the patient is pulseless", "Artifact replaces clinical assessment"], 0, "Motion, poor contact, electrical interference, and other artifact can mimic or obscure true cardiac activity.", "ECG interpretation"),
    q("What is the primary purpose of checking lead placement before interpreting a 12-lead?", ["To improve the reliability of the tracing", "To determine the patient’s blood type", "To replace the physical exam", "To calculate glucose"], 0, "Correct lead placement improves the reliability of the ECG and reduces misleading findings.", "12-lead ECG"),
    q("What is a common reason to obtain serial 12-lead ECGs in a patient with ongoing ischemic symptoms?", ["ECG findings can evolve over time", "One ECG always rules out ischemia", "Serial ECGs replace vital signs", "The first ECG is never useful"], 0, "Ischemic changes can evolve, so serial ECGs may provide additional information when symptoms persist or change.", "12-lead ECG"),
    q("What does QTc attempt to account for?", ["Heart-rate effects on the QT interval", "Patient height only", "QRS amplitude only", "P-wave morphology"], 0, "QT correction adjusts the measured QT interval for heart rate.", "QT/QTc"),
    q("Which rhythm is usually regular with narrow QRS complexes and a very rapid rate?", ["SVT", "Atrial fibrillation", "Ventricular fibrillation", "Asystole"], 0, "Many SVTs present as regular narrow-complex tachycardias.", "Tachyarrhythmias"),
    q("A wide-complex tachycardia should be approached cautiously because:", ["Ventricular tachycardia is an important possible diagnosis", "It is always sinus tachycardia", "Wide QRS always means artifact", "It can never be clinically significant"], 0, "VT is an important consideration with a wide-complex tachycardia, particularly in an unstable patient.", "Tachyarrhythmias"),
    q("What is electrical alternans?", ["Beat-to-beat variation in QRS amplitude or morphology", "A fixed prolonged PR interval", "A sawtooth atrial pattern", "A complete absence of QRS complexes"], 0, "Electrical alternans refers to alternating amplitude or morphology of ECG complexes from beat to beat.", "ECG findings"),
    q("Which finding is most concerning for acute myocardial injury when correlated with symptoms and the ECG?", ["New ST-segment elevation in a relevant contiguous lead pattern", "A normal PR interval", "A normal sinus rhythm alone", "A single normal T wave"], 0, "New ST-segment elevation in an appropriate clinical context can be a marker of acute myocardial injury and requires urgent evaluation.", "12-lead ECG"),
    q("Why is lead aVR sometimes useful in 12-lead interpretation?", ["It can provide additional information about certain global or proximal ischemic patterns", "It is the only lead that shows ventricular activity", "It replaces all other leads", "It measures oxygen saturation"], 0, "aVR can contribute to recognition of certain ischemic patterns when interpreted with the full ECG and clinical context.", "12-lead ECG"),
    q("Which rhythm has no organized ventricular electrical activity and is immediately life-threatening?", ["Ventricular fibrillation", "Sinus rhythm", "First-degree AV block", "Atrial flutter"], 0, "Ventricular fibrillation is a cardiac arrest rhythm with no effective organized ventricular contraction.", "Cardiac arrest rhythms"),
    q("What is the key distinction between a pulse-bearing tachyarrhythmia and a pulseless ventricular rhythm?", ["Presence of effective circulation", "P-wave height", "Patient age alone", "Lead placement"], 0, "Whether effective circulation is present changes the resuscitation pathway and urgency.", "Tachyarrhythmias"),
    q("What does a premature ventricular complex originate from?", ["Ventricular myocardium", "The sinus node", "The AV node only", "The atrial septum"], 0, "A PVC originates from an ectopic ventricular focus rather than the normal conduction pathway.", "Ectopy"),
    q("A premature atrial contraction originates from:", ["An ectopic atrial focus", "The ventricular myocardium", "The His bundle only", "The aorta"], 0, "A PAC is an early atrial depolarization arising outside the sinus node.", "Ectopy"),
    q("Which rhythm is commonly associated with an irregularly irregular pulse?", ["Atrial fibrillation", "Sinus rhythm", "Complete heart block in every case", "Ventricular paced rhythm"], 0, "Atrial fibrillation classically produces an irregularly irregular ventricular rhythm.", "Atrial fibrillation"),
    q("What does a right bundle branch block primarily affect?", ["Right-sided ventricular conduction", "Atrial depolarization only", "AV nodal blood flow", "Sinus node firing"], 0, "A right bundle branch block delays conduction through the right bundle and alters ventricular depolarization.", "Conduction abnormalities"),
    q("Why should ECG interpretation be correlated with the patient?", ["The same ECG finding can have different significance depending on symptoms and context", "ECGs never provide useful information alone", "Symptoms are irrelevant to rhythm interpretation", "Patient assessment can be skipped if the ECG is normal"], 0, "ECG findings must be interpreted in the context of the patient\u2019s presentation, history, and other findings.", "Clinical correlation"),
    q("Which measurement is most directly related to ventricular depolarization time?", ["QRS duration", "PR interval", "QT interval only", "RR interval"], 0, "QRS duration measures the time required for ventricular depolarization.", "ECG fundamentals"),
    q("The RR interval is commonly used to estimate:", ["Heart rate and rhythm regularity", "Oxygen saturation", "Blood pressure", "Cardiac output directly"], 0, "RR intervals help determine ventricular rate and whether the rhythm is regular.", "ECG fundamentals"),
    q("A systematic ECG approach should include rate, rhythm, intervals, morphology, and:", ["ST-T changes and clinical correlation", "Patient shoe size", "Only lead II", "Only the QRS amplitude"], 0, "A systematic interpretation includes rate, rhythm, intervals, morphology, ST-T changes, and clinical correlation.", "ECG interpretation"),];

  List<_AcademyQuestion> _medicationQuestions() => [
    q('What is the primary purpose of checking a medication concentration before drawing up a dose?', ['To determine the patient\'s diagnosis', 'To calculate the correct volume to administer', 'To determine the patient\'s age', 'To replace medication verification'], 1, 'The concentration tells you how much drug is present per unit of volume and is necessary for a volume calculation.', 'Medication safety'),
    q('A medication is ordered at 0.1 mg/kg for a 70 kg patient. What is the calculated dose?', ['0.7 mg', '7 mg', '70 mg', '700 mg'], 1, '0.1 mg/kg × 70 kg = 7 mg.', 'Dose calculation'),
    q('A medication contains 10 mg/mL. How many mL contain 50 mg?', ['0.5 mL', '2 mL', '5 mL', '10 mL'], 2, '50 mg ÷ 10 mg/mL = 5 mL.', 'Dose calculation'),
    q('Why is an independent medication check valuable for high-risk medications?', ['It eliminates the need to read the label', 'It adds another opportunity to catch a dosing or concentration error', 'It guarantees the medication is indicated', 'It replaces patient assessment'], 1, 'A second check can catch errors in medication, concentration, dose, route, or patient before administration.', 'Medication safety'),
    q('Which information should be verified before administering an unfamiliar medication?', ['Medication, dose, route, patient, indication, and allergies as applicable', 'Only the medication color', 'Only the package size', 'Only the expiration date'], 0, 'Medication verification should include the relevant rights/checks and the clinical indication, not just the package appearance.', 'Medication safety'),
    q('A dose is ordered in mcg/kg/min. Which additional patient factor is normally required for a weight-based infusion calculation?', ['Patient weight', 'Height only', 'Temperature only', 'Respiratory rate only'], 0, 'Weight is required to convert a mcg/kg/min order into an absolute dose rate.', 'Infusion calculations'),
    q('What is a common safety problem when converting between mg and mcg?', ['There is no conversion factor', 'A 1,000-fold difference can be missed', 'The units are identical', 'The concentration never matters'], 1, '1 mg equals 1,000 mcg, so unit conversion errors can create a 1,000-fold dosing error.', 'Medication safety'),
    q('Why should medication dosing tools be treated as calculation aids rather than independent treatment protocols?', ['Calculators cannot determine whether a medication is appropriate for the patient', 'Calculators always contain the current protocol', 'Calculators replace medical direction', 'Calculators determine allergies'], 0, 'The clinician and applicable protocol determine whether a medication is indicated and what dose should be used; the calculator can perform the math.', 'Medication safety'),
    q('If a medication label and the electronic reference disagree, what is the safest immediate approach?', ['Ignore both', 'Use the first number you see', 'Pause and verify the discrepancy using an authoritative source or medical direction', 'Double the dose'], 2, 'A discrepancy should be resolved before administration rather than guessed or averaged.', 'Medication safety'),
    q('Which is most important when documenting medication administration?', ['Only the medication name', 'Medication, dose, route, time, and clinically relevant response', 'Only the vial size', 'Only the manufacturer'], 1, 'Complete documentation supports continuity of care and quality review.', 'Medication documentation'),
  
    q("What is the difference between a generic name and a brand name?", ["They are always different drugs", "The generic identifies the active drug while a brand is a marketed product name", "The brand name is always the chemical formula", "There is no difference"], 1, "A generic name identifies the medication substance, while a brand name is a manufacturer-marketed name.", "Medication fundamentals"),
    q("What is the purpose of medication reconciliation?", ["Identify what medications a patient is actually taking and detect discrepancies", "Determine the patient’s height", "Replace the medical history", "Calculate GCS"], 0, "Medication reconciliation compares the patient\u2019s reported medications with available records to identify discrepancies and risks.", "Medication safety"),
    q("Which route generally delivers medication directly into the vascular system?", ["IV", "PO", "Topical", "Rectal"], 0, "Intravenous administration places the medication directly into the vascular system.", "Routes of administration"),
    q("What does IM mean?", ["Intramuscular", "Intra-mucosal", "Intra-medullary", "Intra-metabolic"], 0, "IM means intramuscular.", "Routes of administration"),
    q("What does IN mean in medication administration?", ["Intranasal", "Intravenous", "Intraosseous", "Intracardiac"], 0, "IN means intranasal.", "Routes of administration"),
    q("What does IO mean?", ["Intraosseous", "Intranasal oral", "Intraocular", "Intradermal oral"], 0, "IO means intraosseous.", "Routes of administration"),
    q("If a medication is ordered in mg/kg, which patient factor is essential to the calculation?", ["Weight", "Height only", "Age only", "Respiratory rate"], 0, "A mg/kg dose requires patient weight.", "Dose calculation"),
    q("A patient weighs 80 kg and an order is 2 mg/kg. What is the calculated dose?", ["40 mg", "80 mg", "160 mg", "800 mg"], 2, "2 mg/kg \u00d7 80 kg = 160 mg.", "Dose calculation"),
    q("A vial contains 25 mg in 5 mL. What is the concentration?", ["1 mg/mL", "5 mg/mL", "10 mg/mL", "25 mg/mL"], 1, "25 mg \u00f7 5 mL = 5 mg/mL.", "Concentration"),
    q("If the concentration is 5 mg/mL, how much volume contains 20 mg?", ["1 mL", "2 mL", "4 mL", "10 mL"], 2, "20 mg \u00f7 5 mg/mL = 4 mL.", "Dose calculation"),
    q("What does mcg stand for?", ["Microgram", "Milligram", "Microgram per kilogram", "Milliliter"], 0, "mcg is the abbreviation for microgram.", "Medication units"),
    q("How many micrograms are in 1 milligram?", ["10", "100", "1,000", "10,000"], 2, "1 milligram equals 1,000 micrograms.", "Medication units"),
    q("Why can mg-to-mcg conversion errors be dangerous?", ["The conversion changes the numeric value by a factor of 1,000", "The units are identical", "There is no concentration involved", "It only changes the label color"], 0, "A missed 1,000-fold conversion can create a major medication error.", "Medication safety"),
    q("What is a medication contraindication?", ["A circumstance in which the medication should not be used", "A reason to double the dose", "A medication brand name", "A documentation field only"], 0, "A contraindication is a condition or circumstance in which a medication should not be used.", "Medication fundamentals"),
    q("What is an adverse drug reaction?", ["An unwanted or harmful response associated with a medication", "A medication indication", "A route of administration", "A brand name"], 0, "An adverse drug reaction is an unintended harmful or undesirable response to a medication.", "Medication safety"),
    q("Why should allergies be checked before medication administration?", ["To reduce the risk of an allergic reaction to the medication", "To determine the patient’s pulse", "To calculate oxygen flow", "To replace the physical exam"], 0, "Medication allergies can lead to serious reactions and should be checked before administration when applicable.", "Medication safety"),
    q("Why should medication expiration dates be checked?", ["Potency and safety may be affected after expiration", "Expiration dates determine the patient’s diagnosis", "Expired medications become automatically stronger", "They determine the route"], 0, "Expiration dating helps ensure the medication remains within its labeled quality and potency specifications.", "Medication safety"),
    q("What is a medication\u2019s indication?", ["The condition or purpose for which it is used", "The concentration only", "The expiration date", "The manufacturer"], 0, "An indication is the clinical reason a medication is used.", "Medication fundamentals"),
    q("What is the purpose of a medication label?", ["To provide information such as drug identity, strength, and other required details", "To replace patient assessment", "To determine the patient’s diagnosis", "To guarantee the medication is appropriate"], 0, "The label provides critical product information that must be verified before administration.", "Medication safety"),
    q("If a medication is supplied as 2 mg/1 mL, what is its concentration?", ["0.5 mg/mL", "1 mg/mL", "2 mg/mL", "4 mg/mL"], 2, "2 mg in 1 mL equals 2 mg/mL.", "Concentration"),
    q("What is the safest response to an unclear medication order?", ["Pause and clarify the order before administration", "Guess the intended dose", "Administer half", "Ask another patient"], 0, "An unclear order should be clarified before administration rather than guessed.", "Medication safety"),
    q("Which is an example of a high-alert medication characteristic?", ["An error can cause significant patient harm", "It is always given orally", "It has no side effects", "It never requires monitoring"], 0, "High-alert medications are drugs for which errors can cause significant harm and therefore deserve heightened safeguards.", "Medication safety"),
    q("Why can route of administration matter even when the drug and dose are correct?", ["Different routes can change onset, absorption, and safety", "Route never affects a medication", "Route only changes packaging", "Route determines the patient’s age"], 0, "Route affects pharmacokinetics, onset, absorption, and sometimes safety.", "Routes of administration"),
    q("What does PO mean?", ["By mouth", "Per oxygen", "Post-operative only", "Pulse oximetry"], 0, "PO means by mouth or orally.", "Routes of administration"),
    q("What does SL mean?", ["Sublingual", "Subcutaneous left", "Slow infusion", "Saline line"], 0, "SL means sublingual, or under the tongue.", "Routes of administration"),
    q("What does PRN generally mean?", ["As needed", "Immediately", "By mouth", "Before meals only"], 0, "PRN means as needed. The actual indication and limits still depend on the order or protocol.", "Medication terminology"),
    q("What does STAT generally indicate?", ["Immediate or urgent administration", "Once per week", "At bedtime", "Only if the patient requests it"], 0, "STAT is commonly used to indicate an immediate or urgent action.", "Medication terminology"),
    q("What is titration?", ["Adjusting a medication dose or infusion according to a defined clinical target or response", "Giving every medication at the same rate", "Changing a medication’s brand name", "Diluting every drug to the same concentration"], 0, "Titration means adjusting therapy according to a defined target and the patient\u2019s response.", "Infusion medications"),
    q("Why is concentration important when using an infusion pump?", ["The same dose can require different pump rates at different concentrations", "Concentration never affects volume", "Pump rates are independent of concentration", "It determines the patient’s diagnosis"], 0, "Pump rate depends on the medication concentration and the ordered dose.", "Infusion calculations"),
    q("What does a medication half-life describe?", ["The time required for the amount of drug in the body to decrease by about half under the defined pharmacokinetic model", "The time to administer a medication", "The shelf life of a vial", "The time until the next vital sign"], 0, "Half-life describes the time required for the drug amount or concentration to fall by approximately half under stated conditions.", "Pharmacology basics"),
    q("What is a drug interaction?", ["A medication, food, or other substance changes the effect or handling of another medication", "A normal medication indication", "A route of administration", "A dosing unit"], 0, "Drug interactions can alter pharmacologic effects, metabolism, absorption, or toxicity.", "Medication safety"),
    q("Why should renal function matter for some medications?", ["Kidney impairment can alter elimination and increase drug exposure for renally cleared drugs", "Kidneys never affect medications", "It only changes pill color", "It determines route for every medication"], 0, "Reduced renal clearance can increase exposure to medications that depend on the kidneys for elimination.", "Pharmacology basics"),
    q("Why can hepatic function matter for some medications?", ["The liver is involved in metabolism of many medications", "The liver only stores medications", "Liver function determines all IV rates", "It has no role in pharmacology"], 0, "Many medications undergo hepatic metabolism, so impaired function can affect drug exposure.", "Pharmacology basics"),
    q("What is the purpose of checking the patient\u2019s response after medication administration?", ["To assess effectiveness and detect adverse effects", "To replace documentation", "To determine the manufacturer", "To avoid reassessment"], 0, "Reassessment determines whether the medication achieved its intended effect and whether adverse effects occurred.", "Medication safety"),
    q("Why should medication calculations be performed with units carried through the math?", ["Units help reveal dimensional errors", "Units are only for documentation", "Units make the medication stronger", "Units replace the drug label"], 0, "Tracking units through each calculation helps identify incompatible or incorrect conversions.", "Dose calculation"),
    q("What is a common source of medication error when two concentrations of the same drug are available?", ["Selecting the wrong concentration and drawing the wrong volume", "The medication automatically changes names", "The patient’s age changes the vial concentration", "The route becomes irrelevant"], 0, "Different concentrations can require very different volumes, making concentration verification essential.", "Medication safety"),
    q("Why should verbal medication instructions be repeated back when appropriate?", ["Read-back can confirm that the medication, dose, route, and other details were heard correctly", "It guarantees the order is medically appropriate", "It eliminates the need for documentation", "It replaces the medication label"], 0, "Read-back can reduce communication errors by confirming the critical elements of an order.", "Medication safety"),
    q("What is the best general rule when an unfamiliar medication is identified in the field?", ["Verify the medication identity and relevant clinical information before deciding how it should be used", "Assume the medication is safe because it is prescribed", "Administer it because the patient recognizes it", "Use the most common EMS dose"], 0, "Identification is only the first step; indication, contraindications, dose, route, interactions, and protocol or medical direction must also be considered.", "Medication safety"),
    q("Why should medication references show a source or version date?", ["Drug information and labeling can change over time", "Dates make medications stronger", "Sources are only useful for billing", "Versions never change"], 0, "Source and version information helps clinicians know how current the reference is and when it should be reviewed.", "Medication references"),
    q('What is the safest practice when drawing up a medication from a multi-dose concentration?', ['Verify the exact drug and concentration on the label immediately before calculating and administering','Assume the concentration from memory','Use the largest vial automatically','Ignore the label after opening'], 0, 'The exact medication and concentration should be verified from the label before calculating and administering a dose.', 'Medication safety'),
];

  List<_AcademyQuestion> _airwayQuestions() => [
    q('What is the primary goal of basic airway management?', ['Maintain a patent airway and adequate ventilation/oxygenation', 'Lower blood pressure', 'Increase body temperature', 'Determine the final diagnosis'], 0, 'Airway management prioritizes patency, oxygenation, and ventilation.', 'Airway fundamentals'),
    q('An OPA is generally intended for a patient who:', ['Is awake with an intact gag reflex', 'Is unresponsive without an intact gag reflex', 'Has a suspected ankle fracture', 'Has isolated hypertension'], 1, 'An OPA can help maintain patency in an appropriately unresponsive patient without an intact gag reflex.', 'OPA/NPA'),
    q('An NPA is generally useful when:', ['An oral airway is inappropriate and nasal placement is not contraindicated', 'The patient has no airway concern', 'A patient requires defibrillation', 'The patient has isolated chest pain'], 0, 'An NPA can be useful in patients who need airway support but may not tolerate an OPA, provided there are no contraindications.', 'OPA/NPA'),
    q('What is the most important reason to use suction during airway management?', ['Remove secretions or vomitus that obstruct the airway', 'Lower the patient\'s heart rate', 'Treat hypertension', 'Replace ventilation'], 0, 'Suction helps clear material that interferes with airway patency and ventilation.', 'Airway management'),
    q('What does waveform capnography provide?', ['Information about exhaled CO₂ and ventilation', 'A direct blood pressure measurement', 'A direct hemoglobin measurement', 'A temperature measurement'], 0, 'Waveform capnography provides continuous information about exhaled CO₂ and ventilation and can help assess airway device placement.', 'Capnography'),
    q('After placing an advanced airway, what is an important ongoing consideration?', ['Confirm placement and continuously monitor the patient and ventilation', 'Stop assessing the airway', 'Remove all monitoring', 'Assume placement remains correct regardless of movement'], 0, 'Airway position can change, so ongoing assessment and monitoring are important.', 'Advanced airway'),
    q('Why is a two-person BVM technique often helpful when personnel are available?', ['It can improve mask seal and allow one person to manage the airway while the other ventilates', 'It eliminates the need for oxygen', 'It guarantees intubation', 'It prevents all gastric insufflation'], 0, 'One provider can maintain the airway and mask seal while the other squeezes the bag.', 'BVM ventilation'),
    q('Which finding is most concerning for inadequate ventilation?', ['Rising CO₂ with worsening mental status', 'Normal work of breathing', 'Normal capnography trend', 'Improving respiratory effort'], 0, 'Worsening ventilation can lead to CO₂ retention and declining mental status.', 'Ventilation'),
    q('What should guide the choice of an advanced airway device?', ['Patient anatomy, clinical condition, provider skill, and applicable protocol', 'Device color alone', 'The patient\'s shoe size', 'The time of day'], 0, 'Airway device selection should account for patient factors, clinical circumstances, provider competence, and local protocol.', 'Advanced airway'),
    q('If an airway intervention is not improving the patient, what is the best general principle?', ['Reassess the airway, ventilation, oxygenation, and underlying problem', 'Continue indefinitely without reassessment', 'Ignore the patient response', 'Stop monitoring'], 0, 'Airway management is dynamic; reassessment is required when the patient does not improve as expected.', 'Airway reassessment'),
  
    q("What is the primary purpose of airway positioning?", ["Maintain airway patency", "Lower blood glucose", "Increase heart rate", "Treat hypertension"], 0, "Positioning can help maintain airway patency and improve ventilation.", "Airway fundamentals"),
    q("What is a common first step when an unresponsive patient has no suspected cervical spine injury and needs airway opening?", ["Use an appropriate head-tilt/chin-lift maneuver", "Apply an abdominal binder", "Perform a 12-lead ECG first", "Place the patient prone"], 0, "Head-tilt/chin-lift is a standard airway-opening maneuver when cervical spine concerns do not dictate another approach.", "Airway positioning"),
    q("When cervical spine injury is suspected, which airway-opening approach is commonly considered?", ["Jaw thrust while minimizing unnecessary neck movement", "Forceful head extension", "Prone positioning", "Blind nasal airway placement"], 0, "Jaw thrust can be used to open the airway while minimizing cervical movement when spinal injury is a concern.", "Airway positioning"),
    q("What is the main limitation of a BVM?", ["It requires an open airway and effective technique to provide adequate ventilation", "It cannot deliver oxygen", "It cannot be used with two rescuers", "It always causes gastric inflation"], 0, "BVM ventilation depends on airway patency, mask seal, positioning, and appropriate technique.", "BVM ventilation"),
    q("Why is a two-person BVM technique often helpful?", ["One provider can maintain a better mask seal while the other ventilates", "It doubles the oxygen concentration automatically", "It eliminates the need for airway positioning", "It guarantees intubation"], 0, "Two-person technique can improve mask seal and ventilation mechanics.", "BVM ventilation"),
    q("What is gastric insufflation during BVM ventilation?", ["Air entering the stomach instead of the lungs", "Oxygen entering the bloodstream", "A normal airway reflex", "Air leaving through the nose"], 0, "Excessive ventilation pressure or poor airway technique can force air into the stomach.", "BVM complications"),
    q("Why should ventilation be delivered at an appropriate rate and volume?", ["Excessive ventilation can cause harm and reduce effective circulation during CPR", "More ventilation is always better", "Ventilation rate has no physiologic effect", "It replaces chest compressions"], 0, "Overventilation can increase intrathoracic pressure and adversely affect hemodynamics, among other harms.", "Ventilation fundamentals"),
    q("What is the main purpose of suctioning the airway?", ["Remove secretions, blood, or emesis that obstruct ventilation", "Measure blood pressure", "Treat hypoglycemia", "Replace oxygen therapy"], 0, "Suction helps clear material that can obstruct the airway and impair ventilation.", "Suction"),
    q("What should you generally do if suctioning causes significant patient deterioration?", ["Stop or limit suctioning and reassess oxygenation, ventilation, and airway status", "Continue indefinitely", "Ignore the monitor", "Give oral fluids"], 0, "Suction is a supportive intervention; prolonged or poorly tolerated suctioning can worsen hypoxemia and should prompt reassessment.", "Suction"),
    q("What is the primary purpose of an OPA?", ["Help prevent the tongue from obstructing the airway in an appropriately unresponsive patient", "Provide a route for IV medication", "Measure ETCO2", "Deliver chest compressions"], 0, "An OPA helps keep the tongue from obstructing the airway in a patient who cannot protect the airway and has no intact gag reflex.", "OPA/NPA"),
    q("Why can an OPA cause vomiting or aspiration in an awake patient?", ["It can stimulate an intact gag reflex", "It lowers oxygen saturation directly", "It causes hypotension in every patient", "It blocks the nose"], 0, "An intact gag reflex makes an OPA poorly tolerated and can trigger gagging or vomiting.", "OPA/NPA"),
    q("What is the primary purpose of an NPA?", ["Provide a nasal passage to help maintain airway patency", "Deliver IV medication", "Measure blood glucose", "Defibrillate the heart"], 0, "An NPA can provide a conduit through the nasal passage to help maintain airway patency.", "OPA/NPA"),
    q("Why should facial or basilar skull injury raise concern about nasal airway placement?", ["Nasal insertion may be contraindicated or require special consideration", "It makes the patient immune to hypoxia", "It guarantees bleeding will stop", "It prevents all airway obstruction"], 0, "Certain facial or skull-base injuries are contraindications or require caution with nasal instrumentation according to current protocols.", "OPA/NPA"),
    q("What does an SGA provide?", ["A supraglottic airway that can facilitate ventilation without passing through the vocal cords", "An arterial line", "A gastric feeding tube only", "A central venous catheter"], 0, "A supraglottic airway sits above the glottis and can facilitate ventilation.", "Supraglottic airway"),
    q("What is a major advantage of an SGA in prehospital care?", ["It can often be inserted more rapidly than endotracheal intubation", "It always prevents aspiration completely", "It requires no training", "It directly enters the trachea"], 0, "SGAs can often be inserted rapidly and may provide an effective airway when appropriate.", "Supraglottic airway"),
    q("What is a major limitation of an SGA?", ["It does not provide the same tracheal placement as an endotracheal tube and may have aspiration/ventilation limitations", "It cannot provide ventilation", "It cannot be used in adults", "It always causes pneumothorax"], 0, "An SGA is not a cuffed tube placed through the vocal cords and has important limitations and contraindications.", "Supraglottic airway"),
    q("What is the purpose of preoxygenation before advanced airway attempts?", ["Increase oxygen reserve and delay desaturation during apnea", "Lower blood pressure", "Induce paralysis", "Confirm tube depth"], 0, "Preoxygenation increases oxygen stores before apnea and can extend the time before desaturation.", "Advanced airway"),
    q("What is the purpose of capnography after advanced airway placement?", ["Provide objective information about exhaled CO2 and help assess ventilation and tube placement", "Measure hemoglobin directly", "Replace pulse oximetry in all situations", "Determine blood type"], 0, "Waveform capnography provides continuous information about exhaled CO2 and can help confirm and monitor airway placement and ventilation.", "Capnography"),
    q("What does a persistent waveform ETCO2 tracing after intubation generally support?", ["That the tube is ventilating the lungs and has pulmonary CO2 exchange", "That the patient definitely has normal oxygenation", "That the tube is in the stomach", "That no reassessment is needed"], 0, "A persistent, appropriate waveform supports tracheal placement and effective pulmonary gas exchange but must be interpreted with the clinical context.", "Capnography"),
    q("Why can pulse oximetry and capnography provide different information?", ["SpO2 reflects oxygen saturation while ETCO2 provides information about exhaled carbon dioxide and ventilation", "They measure exactly the same variable", "ETCO2 measures hemoglobin", "SpO2 measures ventilation directly"], 0, "Pulse oximetry primarily reflects oxygen saturation; capnography provides information about ventilation and exhaled CO2.", "Monitoring"),
    q("What is the purpose of confirming endotracheal tube placement with more than one method?", ["No single sign is infallible and multiple methods improve confidence", "Confirmation is unnecessary", "It determines the patient’s age", "It prevents all complications"], 0, "Clinical assessment plus objective methods such as waveform capnography improve confidence in tube placement.", "Advanced airway"),
    q("Why should an airway be reassessed after moving a patient?", ["Position changes can alter airway patency, tube position, or ventilation", "Movement improves every airway", "Reassessment is only needed before transport", "It changes blood type"], 0, "Patient movement can change airway patency and device position, so reassessment is essential.", "Airway reassessment"),
    q("What is the main goal of oxygen therapy?", ["Correct or prevent clinically significant hypoxemia while avoiding unnecessary exposure to excessive oxygen", "Raise oxygen to 100% in every patient regardless of condition", "Lower carbon dioxide in every patient", "Replace ventilation"], 0, "Oxygen therapy is used to address hypoxemia while being titrated appropriately to the clinical situation.", "Oxygen therapy"),
    q("Why is ventilation different from oxygenation?", ["Ventilation concerns movement of air and CO2 removal, while oxygenation concerns oxygen availability in blood", "They are identical", "Ventilation only means oxygen saturation", "Oxygenation only means respiratory rate"], 0, "Ventilation is primarily about moving gas and eliminating CO2; oxygenation is about oxygen transfer and saturation.", "Respiratory physiology"),
    q("What is apnea?", ["Absence of spontaneous breathing", "Rapid breathing", "Low blood pressure", "A normal respiratory pattern"], 0, "Apnea means cessation of spontaneous breathing.", "Respiratory assessment"),
    q("What is agonal breathing in a cardiac arrest context?", ["Abnormal, ineffective gasping that should not be mistaken for normal breathing", "Normal athletic breathing", "A sign of adequate ventilation", "A normal sleep pattern"], 0, "Agonal gasps are not normal effective breathing and can occur during cardiac arrest.", "Respiratory assessment"),
    q("What is the purpose of airway suction before positive-pressure ventilation when secretions obstruct the airway?", ["Clear the obstruction so ventilation can be delivered effectively", "Lower the patient’s temperature", "Treat bradycardia directly", "Measure glucose"], 0, "Removing obstructing material can improve the effectiveness of ventilation.", "Suction"),
    q("Why is a good mask seal important during BVM ventilation?", ["It helps direct delivered gas into the patient rather than leaking around the mask", "It lowers the patient’s heart rate", "It replaces airway positioning", "It prevents all aspiration"], 0, "A good mask seal improves the efficiency of positive-pressure ventilation.", "BVM ventilation"),
    q("What can excessive peak airway pressure during ventilation contribute to?", ["Gastric insufflation and barotrauma risk", "Guaranteed improved oxygenation", "Lower aspiration risk", "Automatic airway protection"], 0, "Excessive pressure can contribute to gastric insufflation and pulmonary barotrauma.", "Ventilation complications"),
    q("What is the purpose of a cuff on a cuffed endotracheal tube?", ["Create a seal within the trachea to facilitate ventilation and reduce leakage", "Prevent all aspiration", "Measure blood pressure", "Provide IV access"], 0, "The cuff creates a seal around the tube within the trachea to reduce gas leak and facilitate ventilation.", "Endotracheal tube"),
    q("Why should cuff pressure be managed appropriately?", ["Excessive pressure can injure tracheal tissue", "Higher pressure is always safer", "Cuff pressure has no effect", "It determines oxygen concentration"], 0, "Excessive cuff pressure can compromise tracheal mucosal perfusion and cause injury.", "Endotracheal tube"),
    q("What is a common sign of upper-airway obstruction?", ["Stridor", "Isolated hypertension", "Clear speech in every case", "Normal airflow"], 0, "Stridor is a high-pitched sound associated with upper-airway narrowing or obstruction.", "Airway assessment"),
    q("What does wheezing generally suggest?", ["Lower-airway narrowing or bronchospasm", "A fractured femur", "An isolated nasal obstruction", "Normal airway mechanics"], 0, "Wheezing commonly reflects narrowed lower airways, such as bronchospasm.", "Respiratory assessment"),
    q("Why can a patient with severe respiratory distress become fatigued?", ["The work of breathing can become unsustainable and lead to respiratory failure", "Fatigue always means the patient is improving", "It only occurs with fever", "It has no relationship to ventilation"], 0, "Severe respiratory effort consumes substantial energy and can progress to fatigue and respiratory failure.", "Respiratory failure"),
    q("What is a key warning sign that respiratory distress may be progressing to respiratory failure?", ["Decreasing mental status with inadequate ventilation", "Mild anxiety with normal ventilation", "Normal work of breathing", "Normal respiratory mechanics"], 0, "Altered mental status with worsening ventilatory failure is a major warning sign.", "Respiratory failure"),
    q("Why should airway equipment be checked before a critical airway procedure?", ["Missing or malfunctioning equipment can delay lifesaving ventilation", "Equipment checks are only for billing", "It guarantees success", "It replaces patient assessment"], 0, "A pre-procedure equipment check reduces preventable delays when airway management becomes difficult.", "Airway preparation"),
    q("What is the safest general approach when an airway attempt is unsuccessful?", ["Reoxygenate/ventilate and follow the difficult-airway or rescue pathway in the applicable protocol", "Continue repeated attempts without reassessment", "Stop all ventilation", "Ignore oxygen saturation"], 0, "When an airway attempt fails, maintaining oxygenation and moving to an appropriate rescue plan is critical.", "Difficult airway"),
    q("Why is continuous reassessment especially important after airway intervention?", ["Airway devices can become displaced or ventilation can deteriorate", "Airways never change after placement", "It only matters in the hospital", "It replaces capnography"], 0, "Airway status and device position can change during movement and treatment, so ongoing reassessment is essential.", "Airway reassessment"),
    q('What is the purpose of a bite block or appropriate airway adjunct consideration in a ventilated patient?', ['Help maintain airway access while preventing device damage when indicated','Guarantee an open airway','Replace suction','Measure ETCO2'], 0, 'Appropriate adjuncts can help maintain access and protect equipment when clinically indicated; they do not replace airway assessment.', 'Airway management'),
    q('What should be done if an airway device becomes displaced during transport?', ['Immediately reassess oxygenation and ventilation and manage the airway according to the applicable rescue plan','Ignore it until arrival','Remove oxygen','Stop monitoring'], 0, 'Device displacement can rapidly compromise ventilation, so immediate reassessment and rescue management are required.', 'Airway reassessment'),
];

  List<_AcademyQuestion> _cardiacArrestQuestions() => [
    q('What is a core priority during adult cardiac arrest?', ['High-quality CPR with minimal interruptions', 'Delaying CPR for a complete history', 'Obtaining a 12-lead before compressions', 'Waiting for vascular access before CPR'], 0, 'High-quality CPR and minimizing interruptions are central to resuscitation.', '2025 AHA CPR/ECC guidelines'),
    q('Which rhythms are generally considered shockable cardiac arrest rhythms?', ['VF and pulseless VT', 'Asystole and PEA', 'Sinus bradycardia and AF', 'SVT and sinus tachycardia'], 0, 'Ventricular fibrillation and pulseless ventricular tachycardia are shockable arrest rhythms.', '2025 AHA ACLS'),
    q('Which rhythms are generally considered nonshockable cardiac arrest rhythms?', ['VF and pulseless VT', 'PEA and asystole', 'SVT and AF', 'Sinus rhythm and PVCs'], 1, 'PEA and asystole are nonshockable rhythms; treatment centers on high-quality CPR, epinephrine, and reversible causes.', '2025 AHA ACLS'),
    q('What is the purpose of a rhythm check during CPR?', ['Assess the rhythm while keeping the pause in compressions as short as possible', 'Provide a full medical history', 'Stop resuscitation automatically', 'Replace pulse assessment entirely'], 0, 'Rhythm checks are brief and should minimize interruption of chest compressions.', '2025 AHA ACLS'),
    q('Which is one of the classic reversible causes commonly considered during cardiac arrest?', ['Hypoxia', 'Appendicitis', 'Migraine', 'Dermatitis'], 0, 'Hypoxia is one of the reversible causes considered during cardiac arrest.', 'Reversible causes'),
    q('What is the main purpose of defibrillation in VF/pulseless VT?', ['Terminate the fibrillatory/ventricular arrhythmia so an organized rhythm may return', 'Provide oxygen directly to the brain', 'Lower the patient\'s temperature', 'Replace CPR permanently'], 0, 'Defibrillation can terminate VF/pulseless VT and allows the possibility of return of organized cardiac activity.', 'Defibrillation'),
    q('After a shock is delivered during a shockable arrest, what is the general CPR principle?', ['Resume CPR promptly rather than pausing for an immediate prolonged pulse check', 'Wait several minutes before CPR', 'Obtain a full set of labs before CPR', 'Immediately transport without further resuscitation'], 0, 'CPR should resume promptly after the shock according to the applicable algorithm.', '2025 AHA ACLS'),
    q('What does ROSC mean?', ['Return of spontaneous circulation', 'Rate of spontaneous compression', 'Respiratory oxygen saturation check', 'Reversal of shock cardioversion'], 0, 'ROSC means return of spontaneous circulation.', 'Post-cardiac arrest'),
    q('Why is waveform capnography useful during cardiac arrest when available?', ['It helps assess ventilation and can provide information about CPR effectiveness and ROSC', 'It directly measures blood pressure', 'It replaces rhythm analysis', 'It identifies every reversible cause'], 0, 'ETCO₂ trends can provide information about ventilation, CPR quality, and possible ROSC when interpreted in context.', 'Capnography in arrest'),
    q('What is a major goal after ROSC?', ['Provide structured post-cardiac-arrest care and identify/treat the underlying cause', 'Stop all monitoring', 'Immediately remove all vascular access', 'Assume the arrest cause is known'], 0, 'ROSC begins a new phase of care that includes stabilization, monitoring, and treatment of the cause.', '2025 AHA post-cardiac arrest care'),
  
    q("What is the first priority when cardiac arrest is recognized?", ["Start high-quality CPR and activate the appropriate resuscitation response", "Obtain a complete medical history first", "Give oral medication", "Wait for a physician before compressions"], 0, "High-quality CPR and activation of the resuscitation system are immediate priorities.", "2025 AHA BLS"),
    q("What is the recommended adult chest compression rate during CPR?", ["60–80/min", "100–120/min", "130–160/min", "40–60/min"], 1, "Adult CPR uses a compression rate of 100\u2013120 per minute.", "2025 AHA BLS"),
    q("What is the recommended adult chest compression depth?", ["At least 2 inches (5 cm) while avoiding excessive depth", "Exactly 1 inch", "Less than 1 cm", "4 inches in every patient"], 0, "Adult chest compressions should be at least 2 inches (5 cm) deep while avoiding excessive depth.", "2025 AHA BLS"),
    q("Why should interruptions in chest compressions be minimized?", ["Interruptions reduce the amount of effective coronary and cerebral perfusion generated by CPR", "Interruptions improve coronary perfusion", "They are required after every breath", "They increase compression quality"], 0, "Minimizing pauses helps maintain perfusion generated by chest compressions.", "High-quality CPR"),
    q("For an adult in cardiac arrest, what is the compression-to-ventilation ratio when no advanced airway is in place?", ["15:2", "30:2", "5:1", "10:1"], 1, "For adult CPR without an advanced airway, the standard ratio is 30 compressions to 2 breaths.", "2025 AHA BLS"),
    q("Once an advanced airway is in place during adult CPR, ventilation is generally delivered:", ["With continuous compressions and breaths at an appropriate rate", "Only once every minute", "With a 30:2 pause pattern forever", "Only after each defibrillation"], 0, "With an advanced airway, compressions continue continuously while ventilations are provided separately at the recommended rate.", "2025 AHA ALS"),
    q("Which rhythm is shockable in the adult cardiac arrest algorithm?", ["VF/pulseless VT", "Asystole", "PEA", "Sinus bradycardia"], 0, "Ventricular fibrillation and pulseless ventricular tachycardia are shockable arrest rhythms.", "2025 AHA ALS"),
    q("Which rhythms are nonshockable in the adult cardiac arrest algorithm?", ["PEA and asystole", "VF and pulseless VT", "SVT and AF", "Sinus tachycardia and sinus bradycardia"], 0, "PEA and asystole are treated as nonshockable rhythms in the adult arrest algorithm.", "2025 AHA ALS"),
    q("What should happen immediately after a defibrillation shock in a cardiac arrest?", ["Resume CPR promptly", "Stop all compressions for five minutes", "Check a blood pressure before CPR", "Wait for a pulse for two minutes"], 0, "CPR should be resumed promptly after a shock rather than delaying for an immediate prolonged pulse check.", "2025 AHA ALS"),
    q("Why is waveform capnography useful during cardiac arrest?", ["It can help assess ventilation, airway placement, and trends during CPR", "It replaces chest compressions", "It measures blood glucose", "It determines the patient’s blood type"], 0, "Waveform capnography provides information about ventilation, airway placement, and physiologic trends during resuscitation.", "2025 AHA ALS"),
    q("A sudden sustained increase in ETCO2 during CPR may indicate:", ["Return of spontaneous circulation or improved pulmonary blood flow", "Guaranteed asystole", "A disconnected airway in every case", "Hypoglycemia"], 0, "A sudden sustained ETCO2 rise can be a clue to ROSC and should prompt appropriate reassessment.", "Capnography in arrest"),
    q("What does ROSC stand for?", ["Return of spontaneous circulation", "Rate of spontaneous compression", "Respiratory oxygen saturation check", "Return of sinus conduction"], 0, "ROSC means return of spontaneous circulation.", "Post-cardiac arrest"),
    q("After ROSC, what is the priority?", ["Transition from arrest care to post-cardiac arrest assessment and management", "Immediately discharge the patient", "Stop all monitoring", "Remove all IV access"], 0, "ROSC begins a new phase of care focused on oxygenation, ventilation, circulation, neurologic status, and the underlying cause.", "2025 AHA post-cardiac arrest care"),
    q("What is the purpose of identifying reversible causes during cardiac arrest?", ["Treatable causes can be corrected while resuscitation continues", "It replaces CPR", "It guarantees ROSC", "It determines the patient’s insurance"], 0, "Reversible causes can contribute to arrest and may be treatable during resuscitation.", "2025 AHA ALS"),
    q("Which is a classic reversible cause category in cardiac arrest?", ["Hypovolemia", "Appendicitis only", "Migraine", "Otitis media"], 0, "Hypovolemia is one of the classic reversible cause categories considered during cardiac arrest.", "Reversible causes"),
    q("What does PEA mean in the context of arrest?", ["Organized electrical activity without a palpable pulse", "A shockable rhythm by definition", "A normal pulse with slow rate", "Atrial flutter"], 0, "PEA is electrical activity without effective mechanical circulation.", "Cardiac arrest rhythms"),
    q("Why should CPR quality be monitored continuously when possible?", ["Compression rate, depth, recoil, and interruptions directly affect resuscitation quality", "It is only for documentation", "CPR quality cannot be assessed", "Monitoring stops the need for defibrillation"], 0, "Feedback and observation can help rescuers maintain high-quality compressions and minimize interruptions.", "CPR quality"),
    q("What is full chest recoil?", ["Allowing the chest to return to its normal position after each compression", "Keeping pressure on the chest continuously", "Compressing only halfway", "Pausing after every compression"], 0, "Full recoil allows the chest to return to its normal position and supports venous return.", "High-quality CPR"),
    q("Why should excessive ventilation be avoided during CPR?", ["It can reduce venous return and impair circulation", "It always improves coronary perfusion", "It prevents all aspiration", "It is required after every compression"], 0, "Excessive ventilation can increase intrathoracic pressure and impair venous return and perfusion.", "CPR ventilation"),
    q("What is the purpose of an AED/defibrillator during cardiac arrest?", ["Identify shockable rhythms and deliver defibrillation when indicated", "Measure blood pressure only", "Provide oxygen", "Calculate GCS"], 0, "Defibrillators identify or allow assessment of shockable rhythms and deliver an electrical shock when indicated.", "Defibrillation"),
    q("Why is early defibrillation important in VF/pulseless VT?", ["Defibrillation can terminate a shockable ventricular rhythm and restore an organized rhythm", "It treats asystole", "It replaces CPR permanently", "It treats hypoglycemia"], 0, "Early defibrillation is a key intervention for shockable ventricular arrest rhythms.", "Defibrillation"),
    q("What should happen while a defibrillator is being prepared during VF/pulseless VT?", ["Continue high-quality CPR until the device is ready to analyze or shock", "Stop CPR immediately after seeing VF", "Give oral fluids", "Wait without intervention"], 0, "CPR should continue while the defibrillator is prepared to minimize interruptions.", "Defibrillation"),
    q("Why should rescuers rotate compressors during prolonged CPR when possible?", ["Fatigue can reduce compression quality", "It changes the rhythm", "It replaces defibrillation", "It eliminates the need for ventilation"], 0, "Compressor fatigue can reduce depth and quality, so planned rotation helps maintain effective CPR.", "CPR quality"),
    q("What is the purpose of a pulse check after a rhythm change or suspected ROSC?", ["Determine whether effective circulation is present", "Measure oxygen saturation", "Determine medication concentration", "Confirm blood type"], 0, "A pulse check is used when indicated to determine whether effective circulation has returned.", "ROSC"),
    q("What is the main goal of post-cardiac arrest oxygen management?", ["Avoid both hypoxemia and unnecessary excessive oxygen exposure while titrating appropriately", "Keep FiO2 at 100% forever", "Stop oxygen immediately", "Use room air regardless of saturation"], 0, "Post-arrest oxygen therapy should address hypoxemia while avoiding unnecessary hyperoxia according to current guidance and local protocol.", "2025 AHA post-cardiac arrest care"),
    q("Why is ventilation monitoring important after ROSC?", ["Both inadequate and excessive ventilation can affect physiology and neurologic outcome", "Ventilation no longer matters", "It only matters during CPR", "It determines blood type"], 0, "Post-arrest ventilation should be monitored and managed because both hypoventilation and excessive ventilation can be harmful.", "2025 AHA post-cardiac arrest care"),
    q("What is the purpose of identifying the cause of cardiac arrest after ROSC?", ["Treating the underlying cause can reduce the risk of recurrent instability", "The cause has no effect after ROSC", "It is only needed for billing", "It replaces neurologic assessment"], 0, "Finding and treating the underlying cause is essential to ongoing post-arrest care.", "Post-cardiac arrest"),
    q("Which is an example of a cardiac arrest special circumstance?", ["Hypothermia", "Simple abrasion", "Uncomplicated headache", "Chronic back pain"], 0, "Hypothermia is one of the special circumstances addressed in current resuscitation guidance.", "2025 AHA special circumstances"),
    q("Which poisoning category is specifically addressed in current AHA special-circumstance guidance?", ["Opioid poisoning", "Vitamin C overdose only", "Topical moisturizer exposure only", "Sunburn"], 0, "Current AHA special-circumstance guidance includes opioid poisoning among toxicologic emergencies.", "2025 AHA special circumstances"),
    q("Why should high-quality CPR continue even when medications are being prepared?", ["CPR remains a core intervention that maintains circulation during arrest", "Medication preparation replaces circulation", "CPR is optional after IV access", "CPR should stop during every medication administration"], 0, "Medication administration does not replace high-quality compressions during cardiac arrest.", "2025 AHA ALS"),
    q("What is the role of epinephrine in adult cardiac arrest under current AHA algorithms?", ["It is part of the medication strategy for cardiac arrest and is given according to the applicable rhythm pathway", "It replaces defibrillation for VF", "It is only for chest pain", "It is never used in arrest"], 0, "Epinephrine is part of the adult cardiac arrest algorithm and timing depends on the arrest rhythm.", "2025 AHA ALS"),
    q("Why should medication administration during arrest be documented with times?", ["Timing helps guide resuscitation and supports accurate clinical documentation", "Timing has no value", "It only matters for billing", "It determines the rhythm"], 0, "Accurate timing helps the team track interventions and supports post-event review.", "Resuscitation documentation"),
    q("What is the purpose of assigning clear team roles during a resuscitation?", ["It improves coordination and reduces confusion during time-critical care", "It eliminates the need for communication", "It guarantees ROSC", "It replaces clinical judgment"], 0, "Defined roles support coordinated, efficient resuscitation and reduce task confusion.", "Resuscitation team dynamics"),
    q("Why is closed-loop communication useful during a resuscitation?", ["It confirms that an instruction was heard and completed", "It prevents all medication errors automatically", "It replaces documentation", "It stops the need for leadership"], 0, "Closed-loop communication confirms that tasks are understood and completed, improving team coordination.", "Resuscitation team dynamics"),
    q("What should happen if a patient regains a pulse but remains unresponsive?", ["Transition to post-ROSC assessment and management while maintaining appropriate monitoring and support", "Stop all monitoring", "Assume the emergency is over", "Remove oxygen and IV access"], 0, "ROSC requires continued assessment and post-cardiac arrest management; it is not the end of the resuscitation.", "Post-cardiac arrest"),
    q("Why should rescuers reassess rhythm and patient status throughout cardiac arrest?", ["The rhythm and clinical condition can change during resuscitation", "The initial rhythm always remains unchanged", "Reassessment delays all care", "Only the hospital can reassess"], 0, "Cardiac arrest is dynamic, so rhythm and patient status must be reassessed at appropriate intervals.", "2025 AHA ALS"),
    q("What is a key principle of CPR quality?", ["Rate, depth, recoil, ventilation, and minimizing interruptions all matter", "Only rate matters", "Only depth matters", "Ventilation is never relevant"], 0, "High-quality CPR is a combination of effective compressions, appropriate ventilation, and minimizing interruptions.", "2025 AHA BLS"),
    q('What is the purpose of defibrillation pad contact with the skin?', ['Provide an effective path for electrical current through the chest','Measure blood pressure','Prevent all burns','Determine rhythm without a monitor'], 0, 'Good pad contact helps deliver electrical energy effectively and safely.', 'Defibrillation'),
    q('Why should rescuers avoid touching the patient during shock delivery?', ['To prevent rescuers from receiving the electrical shock','Because touching changes the ECG diagnosis','It improves CPR depth','It prevents ROSC'], 0, 'Everyone should be clear of the patient during defibrillation to avoid accidental shock to rescuers.', 'Defibrillation'),
    q('What is the purpose of a post-resuscitation team debrief?', ['Identify strengths, opportunities for improvement, and system issues','Assign blame automatically','Replace documentation','Determine the patient’s diagnosis after discharge'], 0, 'Structured debriefing can identify clinical and teamwork improvements after resuscitation.', 'Resuscitation education'),
];

  List<_AcademyQuestion> _strokeQuestions() => [
    q('What does LKW commonly mean in stroke assessment?', ['Last Known Well', 'Lowest Known Weight', 'Last Known Wound', 'Left Knee Weakness'], 0, 'LKW is commonly used for Last Known Well—the last time the patient was known to be at their baseline neurologic state.', 'Stroke assessment'),
    q('Why is the exact time of last known well important?', ['Stroke treatment and triage decisions are time dependent', 'It determines the patient\'s blood type', 'It replaces the neurologic exam', 'It determines the patient\'s height'], 0, 'The time course of symptoms is critical to time-sensitive stroke evaluation and treatment decisions.', '2026 AHA/ASA acute ischemic stroke guideline'),
    q('Which condition is an important stroke mimic that should be rapidly assessed in the field?', ['Hypoglycemia', 'Simple dehydration only', 'An isolated ankle sprain', 'Chronic arthritis'], 0, 'Hypoglycemia can produce neurologic deficits that mimic stroke and should be checked when clinically appropriate.', 'Stroke assessment'),
    q('What is the purpose of a prehospital stroke screening tool?', ['Identify patients with possible stroke and support timely triage/notification', 'Definitively diagnose the stroke subtype', 'Replace hospital imaging', 'Determine the patient\'s insurance status'], 0, 'Stroke scales help identify suspected stroke and can support destination and notification decisions; definitive diagnosis requires further evaluation.', 'Stroke systems of care'),
    q('A patient has sudden facial droop and unilateral arm weakness. What should the EMS clinician generally do?', ['Treat it as a time-sensitive neurologic emergency and determine LKW while continuing assessment', 'Wait several hours to see if it resolves', 'Assume it is anxiety', 'Delay glucose assessment until arrival'], 0, 'Sudden focal neurologic deficits require rapid stroke assessment, including LKW and appropriate point-of-care evaluation.', 'Stroke assessment'),
    q('Which finding can be especially useful when considering large-vessel occlusion screening?', ['A cortical neurologic deficit such as aphasia or neglect', 'Isolated chronic low back pain', 'A healed skin wound', 'Mild chronic knee pain'], 0, 'Cortical findings such as aphasia or neglect can raise concern for a large-vessel occlusion and may be incorporated into prehospital screening tools.', 'LVO assessment'),
    q('Why should EMS provide prehospital notification for suspected stroke when appropriate?', ['It can help the receiving system prepare for a time-sensitive evaluation', 'It replaces the need for transport', 'It guarantees a specific treatment', 'It determines the patient\'s insurance coverage'], 0, 'Early notification can help the receiving facility prepare for rapid stroke evaluation and treatment.', 'Stroke systems of care'),
    q('What is the safest way to document symptom onset when the patient woke with deficits?', ['Use the last time the patient was known to be normal before sleep', 'Use the time the patient woke up as the only onset time', 'Estimate a random time', 'Use the time EMS arrived'], 0, 'For wake-up stroke, the last time the patient was known to be well before sleep is important history.', 'Stroke history'),
    q('Should EMS assume every neurologic deficit is caused by ischemic stroke?', ['No; important mimics and alternative diagnoses must be considered', 'Yes, always', 'Only in patients over 65', 'Only when glucose is normal'], 0, 'Stroke is a clinical emergency, but mimics and alternative causes must remain part of the assessment.', 'Stroke differential'),
    q('What major update occurred in the 2026 AHA/ASA acute ischemic stroke guideline?', ['It refined EMS triage and broadened evidence-based treatment pathways', 'It eliminated the need for imaging', 'It removed EMS from stroke systems of care', 'It made stroke treatment independent of time'], 0, 'The 2026 guideline updates EMS triage and expands/refines several acute ischemic stroke treatment pathways.', '2026 AHA/ASA acute ischemic stroke guideline'),
  
    q("What does the B in BE-FAST represent?", ["Balance", "Breathing", "Blood pressure", "Bleeding"], 0, "B represents sudden balance or coordination problems.", "CDC stroke recognition"),
    q("What does the E in BE-FAST represent?", ["Eyes/vision changes", "Epinephrine", "Edema", "Exhalation"], 0, "E represents sudden vision changes.", "CDC stroke recognition"),
    q("What does the F in BE-FAST represent?", ["Face", "Fever", "Fluid", "Fracture"], 0, "F represents facial weakness or droop.", "CDC stroke recognition"),
    q("What does the A in BE-FAST represent?", ["Arm weakness or drift", "Airway obstruction", "Auscultation", "Allergy"], 0, "A represents sudden arm weakness or drift.", "CDC stroke recognition"),
    q("What does the S in BE-FAST represent?", ["Speech changes", "Skin temperature", "Seizure only", "Systolic pressure"], 0, "S represents sudden speech difficulty or abnormal speech.", "CDC stroke recognition"),
    q("What does the T in BE-FAST emphasize?", ["Time", "Temperature", "Trauma", "Triage only"], 0, "T emphasizes that time matters and emergency activation should not be delayed.", "CDC stroke recognition"),
    q("Why is last known well important in suspected stroke?", ["It helps establish the timing of symptoms for treatment and triage decisions", "It determines blood type", "It replaces neurologic assessment", "It is only used for billing"], 0, "The time the patient was last known to be at baseline is important for time-sensitive stroke treatment and triage.", "Stroke assessment"),
    q("Which is a common sudden stroke symptom?", ["One-sided weakness or numbness", "Gradual toenail pain", "Chronic back stiffness", "Isolated dry skin"], 0, "Sudden unilateral weakness or numbness is a classic stroke warning sign.", "CDC stroke recognition"),
    q("Which symptom can also occur with stroke?", ["Sudden trouble seeing", "Only chronic cough", "Only isolated ankle pain", "Only rash"], 0, "Sudden vision changes can be a symptom of stroke.", "CDC stroke recognition"),
    q("Why should blood glucose be checked in a patient with altered neurologic status when appropriate?", ["Hypoglycemia can mimic neurologic deficits and is treatable", "Glucose determines the stroke subtype", "Glucose replaces a neurologic exam", "Glucose is unrelated to mental status"], 0, "Hypoglycemia can cause altered mental status and focal-appearing deficits and should be considered during assessment.", "Stroke mimics"),
    q("What is a stroke mimic?", ["A condition that produces symptoms resembling stroke without being an acute stroke", "A confirmed ischemic stroke", "A normal neurologic exam", "A type of ECG artifact"], 0, "Stroke mimics are non-stroke conditions that can produce similar neurologic findings.", "Stroke assessment"),
    q("Why should seizure be considered in the differential diagnosis of sudden neurologic deficits?", ["Postictal deficits can resemble stroke", "Seizures never cause neurologic changes", "Seizure history rules out stroke", "They are identical diagnoses"], 0, "Postictal deficits can mimic stroke, but stroke can also provoke seizures; clinical context matters.", "Stroke mimics"),
    q("Why should stroke patients generally not be given food or drink before swallowing safety is established?", ["Dysphagia can increase aspiration risk", "It always lowers blood pressure", "It improves cerebral perfusion", "It prevents all vomiting"], 0, "Stroke can impair swallowing and increase aspiration risk, so oral intake should be handled appropriately.", "Stroke assessment"),
    q("What is the main reason to avoid delaying transport while completing a prolonged field stroke assessment?", ["Stroke treatment is time-sensitive and definitive evaluation occurs at the receiving facility", "Transport has no effect on stroke care", "Longer scene time always improves outcomes", "Stroke symptoms resolve with rest"], 0, "Time-sensitive evaluation and treatment make efficient assessment and transport important.", "Stroke systems of care"),
    q("What is a large vessel occlusion (LVO)?", ["An occlusion of a major intracranial artery that may be amenable to endovascular treatment", "Any headache", "A blocked peripheral IV", "A normal carotid pulse"], 0, "LVO refers to occlusion of a major intracranial artery and can be relevant to thrombectomy triage.", "2026 AHA/ASA acute ischemic stroke guideline"),
    q("Why can an LVO screen be useful in EMS?", ["It can help identify patients who may benefit from transport to a capable stroke center according to regional systems", "It confirms the exact vessel in every patient", "It replaces imaging", "It determines blood glucose"], 0, "Prehospital severity tools can support destination decisions within the local stroke system, although they do not replace definitive imaging.", "Stroke triage"),
    q("Why is a 12-lead ECG sometimes useful in stroke assessment?", ["Cardiac disease and arrhythmias can coexist and may be relevant to the cause or management", "It diagnoses all strokes", "It replaces the neurologic exam", "It measures cerebral blood flow directly"], 0, "ECG assessment can identify arrhythmias and cardiac conditions that may be relevant to the patient.", "Stroke assessment"),
    q("What does aphasia describe?", ["Impaired language production or comprehension", "Weakness of both legs only", "Loss of hearing only", "A low oxygen saturation"], 0, "Aphasia is a language disorder affecting expression, comprehension, or both.", "Neurologic assessment"),
    q("What does dysarthria describe?", ["Impaired speech articulation", "Loss of vision only", "Loss of sensation in both feet only", "A heart rhythm"], 0, "Dysarthria is impaired articulation of speech, often due to motor control problems.", "Neurologic assessment"),
    q("Why is distinguishing aphasia from dysarthria useful?", ["They reflect different neurologic deficits and can provide different localization clues", "They are identical terms", "Neither affects stroke assessment", "Only dysarthria can occur in stroke"], 0, "Aphasia reflects language impairment, while dysarthria reflects impaired speech motor articulation.", "Neurologic assessment"),
    q("What is hemiparesis?", ["Weakness on one side of the body", "Complete loss of consciousness", "Weakness of both eyes", "A heart rhythm abnormality"], 0, "Hemiparesis means weakness affecting one side of the body.", "Neurologic assessment"),
    q("What is hemiplegia?", ["Paralysis affecting one side of the body", "Mild bilateral weakness", "A seizure aura only", "A respiratory pattern"], 0, "Hemiplegia refers to paralysis affecting one side of the body.", "Neurologic assessment"),
    q("Which headache pattern is concerning for subarachnoid hemorrhage?", ["Sudden severe headache reaching maximal intensity rapidly", "Mild chronic headache unchanged for years", "Headache only after exercise with no other symptoms", "A headache that is always relieved by food"], 0, "A sudden severe headache that reaches maximal intensity rapidly is a classic warning pattern for subarachnoid hemorrhage.", "Hemorrhagic stroke"),
    q("Why is anticoagulant use important in a stroke history?", ["It can affect bleeding risk and treatment decisions", "It rules out ischemic stroke", "It confirms hemorrhage", "It has no relevance"], 0, "Anticoagulant and antiplatelet use can influence bleeding risk and acute treatment decisions.", "Stroke history"),
    q("Why should the exact medication name and timing be obtained when possible?", ["It can affect eligibility and risk assessment for acute stroke treatment", "Medication history is irrelevant", "Only the pill color matters", "It replaces imaging"], 0, "Medication exposure and timing can affect acute stroke treatment decisions and risk assessment.", "Stroke history"),
    q("What is the purpose of obtaining the patient\u2019s baseline neurologic status?", ["It helps distinguish new deficits from preexisting impairment", "It confirms the stroke subtype", "It replaces LKW", "It determines blood pressure goals"], 0, "Knowing baseline function helps identify which deficits are new and clinically significant.", "Stroke assessment"),
    q("Why should witnesses or family be asked about symptom onset?", ["The patient may not know or be able to communicate the exact timing", "Witnesses never provide useful information", "It only matters for billing", "It replaces the exam"], 0, "Witnesses may provide critical information about onset, baseline, and progression.", "Stroke history"),
    q("What is wake-up stroke?", ["Stroke symptoms first recognized after the patient awakens from sleep", "A stroke caused by waking up", "A stroke that occurs only during exercise", "A seizure during sleep"], 0, "Wake-up stroke refers to symptoms first recognized upon awakening, when the exact onset time is unknown.", "Stroke history"),
    q("What is the purpose of documenting symptom progression?", ["Worsening or evolving deficits can influence urgency and clinical interpretation", "Progression never matters", "It determines the patient’s insurance", "It replaces imaging"], 0, "Evolution of neurologic deficits provides important clinical information and may affect triage.", "Stroke assessment"),
    q("Why should hypotension be taken seriously in a suspected stroke patient?", ["Poor perfusion may worsen cerebral perfusion and can indicate another serious condition", "Hypotension always proves hemorrhage", "It has no clinical effect", "It confirms LVO"], 0, "Hypotension can compromise perfusion and may signal another critical process requiring treatment.", "Stroke assessment"),
    q("Why can severe hypertension accompany acute stroke?", ["It may reflect the physiologic response to acute neurologic injury and requires context-specific management", "It always means chronic hypertension only", "It confirms hemorrhage", "It should always be normalized immediately in the field"], 0, "Blood pressure may rise during acute stroke; management depends on stroke type, treatment pathway, and current guidance rather than reflexively normalizing it.", "Stroke assessment"),
    q("What is the role of EMS in stroke systems of care?", ["Recognize suspected stroke, establish timing/severity, provide supportive care, and transport according to the regional system", "Perform definitive cerebral imaging in the field in every system", "Administer all hospital stroke treatments", "Delay transport until symptoms resolve"], 0, "EMS recognition, timing, severity assessment, supportive care, and destination selection are key components of stroke systems of care.", "2026 AHA/ASA acute ischemic stroke guideline"),
    q("Why is destination selection important for suspected LVO?", ["Some patients may benefit from rapid access to endovascular-capable stroke care", "All hospitals have identical capabilities", "Destination never affects treatment", "Only trauma centers treat stroke"], 0, "Systems may direct suspected LVO patients to centers capable of advanced stroke intervention when appropriate.", "2026 AHA/ASA acute ischemic stroke guideline"),
    q("What is the main difference between ischemic and hemorrhagic stroke?", ["Ischemic stroke involves vessel occlusion while hemorrhagic stroke involves bleeding", "They are identical", "Ischemic stroke always causes bleeding", "Hemorrhagic stroke always causes vessel occlusion only"], 0, "Ischemic stroke results from arterial occlusion, whereas hemorrhagic stroke involves bleeding into or around the brain.", "Stroke fundamentals"),
    q("Why can stroke symptoms be transient?", ["Some ischemic events can cause temporary neurologic deficits without persistent infarction", "Transient symptoms cannot be vascular", "It always means seizure", "It means no evaluation is needed"], 0, "Transient neurologic symptoms can occur with transient ischemia and still require urgent evaluation.", "Stroke fundamentals"),
    q("What is a TIA?", ["A transient episode of neurologic dysfunction caused by focal brain, spinal cord, or retinal ischemia without acute infarction", "A type of seizure", "A chronic headache", "A traumatic brain injury"], 0, "TIA is transient neurologic dysfunction caused by focal ischemia without acute infarction.", "Stroke fundamentals"),
    q("Why should a patient with resolved stroke-like symptoms still receive urgent evaluation?", ["Transient symptoms can represent a high-risk ischemic event", "Resolution proves there was no vascular cause", "No further assessment is needed", "Only persistent symptoms matter"], 0, "Resolved focal neurologic symptoms can represent TIA or evolving stroke and warrant urgent evaluation.", "Stroke fundamentals"),
    q("What is one reason a stroke patient may have an unreliable history?", ["Aphasia, altered mental status, or cognitive impairment can limit communication", "Stroke always improves memory", "The patient is always fully oriented", "History is never useful"], 0, "Neurologic deficits can make history-taking difficult, increasing the importance of collateral information.", "Stroke assessment"),
    q("Why should glucose be checked before attributing altered mental status solely to stroke?", ["Hypoglycemia is a treatable stroke mimic", "Glucose confirms hemorrhage", "It replaces a neurologic exam", "It determines the LVO vessel"], 0, "Hypoglycemia can mimic stroke and should be identified promptly when appropriate.", "Stroke mimics"),
    q("What is the best general principle for prehospital stroke care?", ["Recognize rapidly, determine last known well, assess severity, support ABCs, and minimize avoidable delay", "Wait for symptoms to resolve", "Give oral fluids to every patient", "Complete every possible test before transport"], 0, "Rapid recognition, timing, supportive care, severity assessment, and efficient transport are core EMS principles.", "Stroke systems of care"),];

  List<_AcademyQuestion> _pediatricQuestions() => [
    q('Why are pediatric emergencies approached differently from adult emergencies?', ['Children have age- and size-dependent physiology and treatment considerations', 'Children are simply smaller adults', 'Pediatric patients never require weight-based dosing', 'Pediatric vital signs are identical at every age'], 0, 'Children are not simply small adults; normal physiology, anatomy, equipment, and treatment vary with age and size.', '2025 AHA/AAP pediatric guidelines'),
    q('What is especially useful for pediatric weight-based medication calculations?', ['An accurate measured weight when available', 'The parent\'s weight', 'The child\'s shoe size', 'The room number'], 0, 'Measured weight is preferred when it is available and reliable; length-based references can be useful when an actual weight is unavailable.', 'Pediatric medication safety'),
    q('Which is a concerning sign of pediatric respiratory distress?', ['Increased work of breathing', 'Normal work of breathing', 'Normal interaction only', 'Warm hands alone'], 0, 'Retractions, nasal flaring, abnormal respiratory effort, and other increased work of breathing are important pediatric findings.', 'Pediatric assessment'),
    q('In a child, worsening respiratory effort followed by decreasing effort can indicate:', ['Impending respiratory failure', 'Guaranteed improvement', 'Normal sleep', 'Hypertension only'], 0, 'A child who tires and develops decreasing respiratory effort may be progressing from distress toward respiratory failure.', 'Pediatric respiratory emergencies'),
    q('Why is a length-based pediatric reference useful when an actual weight is unavailable?', ['Length can provide an estimate of size for equipment and some weight-based decisions', 'Length gives an exact measured weight', 'Length replaces clinical assessment', 'Length determines the diagnosis'], 0, 'Length-based systems provide an estimate when an actual weight is unavailable; they do not replace clinical judgment or measured weight when available.', 'Pediatric emergency reference'),
    q('What is an important principle when treating pediatric shock?', ['Recognize shock early and reassess frequently because children can compensate before sudden deterioration', 'Wait for profound hypotension before acting', 'Assume normal blood pressure excludes shock', 'Avoid reassessment after treatment'], 0, 'Children may maintain blood pressure despite significant compromise, so early recognition and repeated reassessment matter.', 'Pediatric shock'),
    q('Which 2025 AHA/AAP update applies to infant chest compressions?', ['The two-finger technique was removed from the recommended infant compression techniques', 'Chest compressions are no longer recommended', 'Only adult-sized pads should be used', 'Infants should receive no ventilations'], 0, 'The 2025 pediatric basic life support guidance removed the two-finger technique and describes heel-of-one-hand or two-thumb techniques for infant compressions.', '2025 AHA/AAP pediatric BLS'),
    q('Why should pediatric medication calculations be checked carefully?', ['Small dosing errors can have a large effect because doses are often weight based', 'Children never receive medications', 'Weight never matters', 'Concentration is irrelevant'], 0, 'Weight-based dosing and small absolute volumes make careful calculation and verification especially important.', 'Pediatric medication safety'),
    q('Which assessment is especially important in a sick child with altered mental status?', ['Airway, breathing, circulation, glucose, and neurologic status', 'Only the temperature', 'Only the blood pressure', 'Only the pupil size'], 0, 'Altered mental status requires a broad ABC and neurologic assessment, including glucose when appropriate.', 'Pediatric assessment'),
    q('What is a key principle when using a pediatric reference tool?', ['Use it as a clinical aid and verify against current local protocol and authoritative guidance', 'Assume the tool is always correct regardless of version', 'Ignore the patient\'s measured weight', 'Never reassess after using it'], 0, 'Pediatric references can support calculations and preparation but should remain aligned with current approved protocols and guidance.', 'Pediatric reference safety'),
  
    q("Why can children compensate for shock before suddenly deteriorating?", ["They may maintain blood pressure through increased heart rate and vascular tone until compensation fails", "Children cannot compensate", "Blood pressure always falls first", "Heart rate never changes"], 0, "Children can maintain blood pressure despite significant physiologic stress until compensatory mechanisms fail.", "Pediatric assessment"),
    q("What is often an early sign of pediatric respiratory distress?", ["Increased work of breathing", "Cardiac arrest", "Fixed pupils", "Immediate hypotension in every case"], 0, "Increased work of breathing is a common early sign of pediatric respiratory distress.", "Pediatric respiratory assessment"),
    q("What can nasal flaring indicate in an infant?", ["Increased work of breathing", "Normal sleep", "Hypoglycemia only", "Bradycardia"], 0, "Nasal flaring is a sign of increased respiratory effort in infants.", "Pediatric respiratory assessment"),
    q("What can grunting in an infant indicate?", ["Respiratory distress and an attempt to maintain functional residual capacity", "Normal digestion", "Hypertension", "A normal airway reflex"], 0, "Grunting can indicate significant respiratory distress as the infant attempts to maintain airway pressure.", "Pediatric respiratory assessment"),
    q("Why can pediatric respiratory failure develop quickly?", ["Children have smaller airways and limited respiratory reserve", "Children have unlimited reserve", "Their airways are larger than adults", "Respiratory rate never changes"], 0, "Small airway caliber and limited reserve can allow respiratory compromise to progress rapidly.", "Pediatric respiratory failure"),
    q("What is a concerning sign of pediatric respiratory failure?", ["Decreasing respiratory effort with altered mental status after a period of distress", "Mild crying", "Normal interaction", "Normal work of breathing"], 0, "A child who becomes fatigued with decreasing effort and altered mental status may be progressing to respiratory failure.", "Pediatric respiratory failure"),
    q("Why is weight important in pediatric emergency care?", ["Many medications and interventions are weight based", "Weight is never used", "It determines only the child’s age", "It replaces assessment"], 0, "Pediatric medication and resuscitation calculations commonly depend on weight.", "Pediatric fundamentals"),
    q("Why can a length-based pediatric system be useful?", ["It can provide an estimate when an actual weight is unavailable", "It replaces every clinical assessment", "It guarantees the exact weight", "It determines diagnosis"], 0, "Length-based tools can provide an estimate when a measured weight is unavailable, but local/current tools should be followed.", "Pediatric tools"),
    q("Why should a measured weight override an estimated weight when an accurate weight is available and appropriate?", ["A measured weight is more patient-specific", "Estimated weight is always more accurate", "Weight is irrelevant", "Measured weight cannot be used in EMS"], 0, "An accurate measured weight is more patient-specific than a length-based estimate.", "Pediatric weight"),
    q("What is a key principle when calculating pediatric medication doses?", ["Use the patient’s current weight and the applicable medication reference/protocol", "Use adult dosing for every child", "Round every dose to the nearest adult dose", "Ignore maximum doses"], 0, "Pediatric dosing should be based on the applicable weight-based reference and any maximum dose limits.", "Pediatric medication safety"),
    q("What is the purpose of a pediatric Broselow-style tool?", ["Provide length-based estimates for equipment and weight when appropriate", "Replace medical direction", "Diagnose disease", "Provide a legally binding protocol"], 0, "Length-based pediatric tools can assist with estimated weight and equipment selection; they do not replace local protocols or clinical judgment.", "Pediatric tools"),
    q("Why are pediatric airway equipment sizes different from adult sizes?", ["Airway anatomy and patient size vary substantially with age and growth", "All children have adult-sized airways", "Airway size is unrelated to anatomy", "Only oxygen tubing changes"], 0, "Pediatric airway anatomy changes with growth, requiring appropriately sized equipment.", "Pediatric airway"),
    q("Why should a pediatric BVM be appropriately sized?", ["An appropriately sized mask and bag improve the ability to ventilate effectively", "Size never matters", "Adult bags cannot deliver oxygen", "Small masks always seal better"], 0, "Appropriate equipment size improves mask seal and ventilation effectiveness.", "Pediatric airway"),
    q("What is a common reason pediatric bradycardia is dangerous?", ["It can be associated with hypoxia and may precede cardiac arrest", "Bradycardia is always benign", "It proves the child is asleep", "It never affects perfusion"], 0, "Pediatric bradycardia is often associated with respiratory compromise and can progress to arrest.", "2025 AHA/AAP PALS"),
    q("What is an important first consideration in a critically ill child with bradycardia?", ["Assess and correct oxygenation and ventilation problems", "Immediately give oral medication", "Ignore airway status", "Wait for the child to improve"], 0, "Oxygenation and ventilation are key considerations in pediatric bradycardia, especially when respiratory compromise is present.", "2025 AHA/AAP PALS"),
    q("What is a common pediatric cardiac arrest rhythm pattern?", ["Asphyxial or respiratory causes are important contributors", "Every pediatric arrest is caused by primary VF", "Trauma is never relevant", "Bradycardia never occurs"], 0, "Respiratory compromise and hypoxia are important contributors to pediatric cardiac arrest.", "2025 AHA/AAP PALS"),
    q("Why is capnography useful in pediatric airway management?", ["It provides information about ventilation and can help confirm and monitor advanced airway placement", "It measures blood glucose", "It replaces pulse oximetry in all cases", "It determines weight"], 0, "Waveform capnography provides information about ventilation and airway placement when applicable.", "Pediatric airway"),
    q("What does retractions indicate in a child?", ["Increased work of breathing", "Improved ventilation", "Normal sleep", "Dehydration only"], 0, "Retractions indicate increased effort to breathe.", "Pediatric respiratory assessment"),
    q("Why should pediatric patients be kept warm during resuscitation and transport?", ["Children can lose heat rapidly and hypothermia can worsen physiologic stress", "Warmth has no effect", "Only adults lose heat", "It replaces oxygenation"], 0, "Children, especially infants, can lose heat rapidly and require attention to temperature control.", "Pediatric care"),
    q("What is a key sign of pediatric shock?", ["Poor perfusion such as delayed capillary refill, weak pulses, or altered mental status", "Normal interaction with strong pulses", "Only fever", "Normal urine output alone"], 0, "Poor perfusion findings can indicate pediatric shock even before profound hypotension develops.", "Pediatric shock"),
    q("Why is hypotension a late and concerning sign in pediatric shock?", ["Children may maintain blood pressure until compensatory mechanisms fail", "Children always become hypotensive first", "Hypotension is normal in children", "Blood pressure is never useful"], 0, "Pediatric patients may preserve blood pressure until significant decompensation occurs.", "Pediatric shock"),
    q("What is the purpose of reassessing a child after an intervention?", ["Pediatric physiology can change quickly and response guides ongoing care", "Reassessment is unnecessary", "It only matters after transport", "It replaces the initial assessment"], 0, "Frequent reassessment is essential because children can deteriorate or respond quickly to interventions.", "Pediatric reassessment"),
    q("What is a key pediatric airway difference compared with adults?", ["The airway is smaller and can become critically narrowed with relatively little edema", "The airway is always larger", "The larynx never changes with age", "Edema has no effect"], 0, "Small pediatric airway diameter means relatively small amounts of swelling can markedly increase resistance.", "Pediatric airway"),
    q("Why can croup produce stridor?", ["Upper-airway swelling narrows the airway", "Lower-airway mucus only", "The alveoli collapse in every case", "It is caused by hypertension"], 0, "Upper-airway narrowing in croup can produce inspiratory stridor.", "Pediatric respiratory illness"),
    q("Why is epiglottitis-like upper-airway disease potentially dangerous?", ["Rapid airway obstruction can occur", "It always resolves without care", "It only causes abdominal pain", "It cannot affect ventilation"], 0, "Severe upper-airway inflammation can progress rapidly to obstruction and respiratory failure.", "Pediatric airway"),
    q("What is bronchiolitis?", ["A lower respiratory illness involving small airways, usually in infants and young children", "A cardiac rhythm", "A bone injury", "A neurologic disorder"], 0, "Bronchiolitis is a lower respiratory tract illness affecting small airways, commonly in infants.", "Pediatric respiratory illness"),
    q("Why is a quiet chest in a severely distressed child concerning?", ["It may indicate severely reduced airflow rather than improvement", "It always means the child is recovering", "It proves normal ventilation", "It rules out respiratory failure"], 0, "A very quiet chest in severe distress can indicate critically poor airflow and impending or established respiratory failure.", "Pediatric respiratory failure"),
    q("What is the purpose of pediatric pain assessment?", ["Pain can affect physiology and treatment, and children may express it differently by developmental stage", "Pain cannot be assessed in children", "Only adults need pain assessment", "Pain assessment determines airway size"], 0, "Pain assessment should be developmentally appropriate and incorporated into pediatric care.", "Pediatric assessment"),
    q("Why should caregivers be included in pediatric assessment when appropriate?", ["They can provide baseline behavior, history, medications, and symptom timing", "Caregivers never know useful information", "It replaces the physical exam", "It prevents transport"], 0, "Caregivers often provide essential baseline and historical information for children.", "Pediatric assessment"),
    q("What is a pediatric dosing maximum?", ["A stated upper limit that should not be exceeded even when a weight-based calculation would produce a larger dose", "The minimum dose", "A route of administration", "A brand name"], 0, "Some medications have maximum doses that limit the weight-based calculation.", "Pediatric medication safety"),
    q("Why should pediatric medication concentrations be verified carefully?", ["Different concentrations can produce very different volumes for the same calculated dose", "Concentration never matters", "All pediatric drugs have one concentration", "It only affects packaging"], 0, "Concentration errors can cause large dosing errors, especially in small patients.", "Pediatric medication safety"),
    q("What is the purpose of a pediatric cardiac arrest energy calculation?", ["Defibrillation energy is weight based in pediatric patients under current resuscitation guidance", "It determines blood pressure", "It measures glucose", "It replaces CPR"], 0, "Pediatric defibrillation energy is based on patient weight under current PALS guidance.", "2025 AHA/AAP PALS"),
    q("Why should pediatric defibrillator pads be appropriately sized and positioned?", ["Proper pad size and placement improve effective current delivery and reduce complications", "Pad size never matters", "Adult pads always fit every infant", "Position has no effect"], 0, "Appropriate pad size and placement are part of effective pediatric defibrillation.", "2025 AHA/AAP PALS"),
    q("What is an important principle when treating pediatric respiratory distress?", ["Support oxygenation and ventilation while addressing the underlying cause", "Wait for fatigue before intervening", "Avoid reassessment", "Use adult settings automatically"], 0, "Pediatric respiratory care focuses on supporting oxygenation/ventilation while treating the cause and reassessing frequently.", "Pediatric respiratory care"),
    q("Why should pediatric patients be assessed for safeguarding concerns when appropriate?", ["Injury patterns and history may raise concerns for abuse or neglect", "Safeguarding is never part of EMS assessment", "Only police can recognize concerns", "It replaces medical treatment"], 0, "EMS clinicians should recognize and appropriately report safeguarding concerns according to law and policy.", "Pediatric assessment"),
    q("What is a key principle when a child has a severe foreign-body airway obstruction?", ["Follow the current age-appropriate FBAO sequence and reassess continuously", "Give oral fluids", "Perform a blind finger sweep routinely", "Delay intervention until transport"], 0, "Current AHA/AAP guidance provides age-appropriate sequences for severe foreign-body airway obstruction.", "2025 AHA/AAP pediatric BLS"),
    q("Why should blind finger sweeps be avoided in a child with suspected airway foreign body?", ["They can push the object deeper and cause injury", "They always remove the object", "They improve oxygenation", "They are required by all guidelines"], 0, "Blind sweeps can worsen obstruction or injure the airway and are not routinely recommended.", "2025 AHA/AAP pediatric BLS"),
    q("What is the purpose of obtaining a pediatric baseline mental status?", ["It helps detect subtle changes from the child’s normal behavior", "It determines medication concentration", "It replaces vital signs", "It confirms trauma"], 0, "Caregiver-reported baseline behavior can make changes in pediatric mental status easier to recognize.", "Pediatric assessment"),
    q("Why is respiratory rate interpretation in children age dependent?", ["Normal respiratory rates vary with age and developmental stage", "All ages have the same normal rate", "Respiratory rate never changes", "Only adults have age-dependent rates"], 0, "Normal pediatric respiratory rate varies substantially with age.", "Pediatric vital signs"),
    q('Why should pediatric pulse and respiratory findings be interpreted using age-appropriate references?', ['Normal values vary substantially with age','All children have identical vital signs','Age has no effect on heart rate','Adult ranges are always appropriate'], 0, 'Normal pediatric heart and respiratory rates vary with age, so age-appropriate references are important.', 'Pediatric vital signs'),
];

  List<_AcademyQuestion> _traumaQuestions() => [
    q('What is the primary goal of the trauma primary survey?', ['Rapidly identify and address immediate life threats', 'Complete a detailed past medical history first', 'Determine insurance status', 'Delay treatment until every injury is identified'], 0, 'The primary survey focuses on immediately life-threatening problems.', 'Trauma assessment'),
    q('Which finding is most concerning for major external hemorrhage?', ['Rapidly expanding blood loss with signs of shock', 'A small superficial abrasion', 'A healed scar', 'Mild chronic bruising'], 0, 'Major hemorrhage can rapidly cause shock and requires prompt recognition and control.', 'Hemorrhage control'),
    q('What is the general priority when severe external bleeding is identified?', ['Control the hemorrhage promptly while continuing the trauma assessment', 'Ignore it until after transport', 'Only document it', 'Wait for a full secondary survey'], 0, 'Life-threatening external hemorrhage should be addressed promptly while other life threats are evaluated.', 'Hemorrhage control'),
    q('Why is repeated reassessment important in trauma?', ['The patient\'s condition can change rapidly and injuries may evolve', 'Trauma patients never deteriorate', 'It replaces initial assessment', 'It is only needed after discharge'], 0, 'Trauma physiology can change quickly, making repeated assessment essential.', 'Trauma reassessment'),
    q('What does GCS assess?', ['Eye, verbal, and motor responses', 'Blood pressure, pulse, and respirations', 'Pain, temperature, and glucose', 'Pupils, skin, and capillary refill only'], 0, 'The Glasgow Coma Scale scores eye, verbal, and motor responses.', 'Neurologic assessment'),
    q('A patient with chest trauma has severe respiratory distress and signs of obstructive shock. What principle applies?', ['Identify and treat immediately life-threatening thoracic causes while supporting oxygenation/ventilation', 'Delay all treatment until CT imaging', 'Focus only on the extremity injury', 'Assume anxiety is the cause'], 0, 'Life-threatening chest injuries require rapid recognition, supportive care, and appropriate definitive interventions within scope/protocol.', 'Chest trauma'),
    q('What is the purpose of a secondary trauma survey?', ['Identify additional injuries after immediate life threats are addressed', 'Replace the primary survey', 'Delay treatment of life threats', 'Determine insurance information'], 0, 'The secondary survey is a systematic search for additional injuries after immediate threats are addressed.', 'Trauma assessment'),
    q('Why can a patient with significant hemorrhage have a normal blood pressure early in the course?', ['Compensatory mechanisms can temporarily maintain blood pressure', 'Hemorrhage always causes immediate hypotension', 'Blood pressure is unrelated to circulation', 'The monitor is always inaccurate'], 0, 'Compensation can preserve blood pressure despite significant blood loss until compensation fails.', 'Hemorrhagic shock'),
    q('What is an important principle when assessing a patient after a high-energy mechanism?', ['Consider occult injury even when external findings are limited', 'Assume no injury if there is no bleeding', 'Skip the history', 'Only assess the painful body part'], 0, 'High-energy mechanisms can produce significant internal injury without dramatic external findings.', 'Mechanism of injury'),
    q('Which statement best describes the trauma approach?', ['Treat immediate threats while continuously reassessing and transporting toward appropriate definitive care', 'Finish every exam before treating any life threat', 'Treat only visible injuries', 'Transport destination never matters'], 0, 'Trauma care is dynamic: address immediate threats, reassess, and select an appropriate destination based on the patient and system.', 'Trauma systems of care'),
  
    q("What is the primary goal of the trauma primary survey?", ["Rapidly identify and treat immediate life threats", "Complete a detailed past medical history", "Document every injury before treatment", "Determine insurance status"], 0, "The primary survey is designed to rapidly identify and address immediate threats to life.", "Trauma assessment"),
    q("What does the X in XABCDE commonly emphasize?", ["Exsanguinating hemorrhage", "X-ray interpretation", "Exposure only", "External temperature"], 0, "X is commonly used to emphasize catastrophic external hemorrhage that requires immediate control.", "Trauma primary survey"),
    q("What is the first priority with a life-threatening external hemorrhage?", ["Control the bleeding with appropriate hemorrhage-control measures", "Obtain a 12-lead first", "Give oral fluids", "Complete a full secondary survey"], 0, "Catastrophic bleeding should be controlled immediately using appropriate methods.", "Hemorrhage control"),
    q("When should a tourniquet be considered for severe extremity hemorrhage?", ["When life-threatening extremity bleeding requires rapid control and a tourniquet is appropriate", "Only after an hour of direct pressure", "Never in the field", "Only for minor bleeding"], 0, "Tourniquets are an important option for life-threatening extremity hemorrhage when appropriate.", "Hemorrhage control"),
    q("What is the purpose of direct pressure for external bleeding?", ["Compress the bleeding source to reduce blood loss", "Increase bleeding", "Lower body temperature", "Measure perfusion"], 0, "Direct pressure compresses the bleeding source and can control many external hemorrhages.", "Hemorrhage control"),
    q("Why should wound packing be considered for some junctional or deep wounds?", ["Packing can apply pressure to a bleeding source that cannot be controlled by a simple tourniquet", "It prevents all infection", "It replaces transport", "It is only cosmetic"], 0, "Packing can provide direct pressure to deep wounds in areas where a standard extremity tourniquet may not work.", "Hemorrhage control"),
    q("What is the purpose of a pelvic binder when indicated?", ["Reduce pelvic volume and stabilize certain suspected pelvic injuries", "Treat a forearm fracture", "Improve airway patency", "Replace hemorrhage control"], 0, "A pelvic binder can stabilize certain pelvic ring injuries and may reduce pelvic volume and bleeding.", "Pelvic trauma"),
    q("Why can pelvic fractures cause major blood loss?", ["The pelvis can contain significant vascular and tissue spaces that may bleed internally", "Pelvic fractures never bleed", "Only skin bleeding occurs", "They cannot affect circulation"], 0, "Pelvic injuries can cause substantial internal hemorrhage, sometimes without obvious external bleeding.", "Pelvic trauma"),
    q("What is tension pneumothorax?", ["Air under pressure in the pleural space causing impaired ventilation and circulation", "Blood in the stomach", "Fluid in the pericardium only", "A simple rib fracture"], 0, "Tension pneumothorax is a life-threatening accumulation of pleural air under pressure that can impair ventilation and hemodynamics.", "Chest trauma"),
    q("Which finding may raise concern for tension pneumothorax in the appropriate trauma context?", ["Severe respiratory compromise with obstructive shock physiology", "Isolated ankle pain", "Normal respiratory status", "Mild headache"], 0, "Severe respiratory compromise with hypotension or other obstructive physiology can raise concern for tension pneumothorax.", "Chest trauma"),
    q("What is an open pneumothorax?", ["A chest wall wound that allows air to communicate with the pleural space", "A closed abdominal injury", "A fractured wrist", "A pulmonary embolism"], 0, "An open pneumothorax involves an open chest wound that communicates with the pleural space.", "Chest trauma"),
    q("What is flail chest?", ["A segment of the chest wall with multiple rib fractures causing paradoxical movement", "A single rib fracture", "A penetrating abdominal wound", "A pelvic fracture"], 0, "Flail chest involves a segment of chest wall made unstable by multiple rib fractures.", "Chest trauma"),
    q("Why is traumatic brain injury concerning even when the patient initially looks well?", ["Neurologic deterioration can occur over time and intracranial bleeding may be occult", "Brain injuries always resolve spontaneously", "Normal appearance rules out bleeding", "Only external wounds matter"], 0, "Intracranial injury may be occult and patients can deteriorate, so serial neurologic assessment is important.", "Head trauma"),
    q("What does GCS primarily assess?", ["Eye, verbal, and motor responses", "Blood pressure and pulse", "Oxygen saturation only", "Pain score only"], 0, "The Glasgow Coma Scale assesses eye, verbal, and motor responses.", "Neurologic trauma assessment"),
    q("Why is a trend in GCS often more useful than a single isolated score?", ["A changing score can indicate neurologic deterioration or improvement", "GCS never changes", "Only the first score matters", "Trend has no clinical meaning"], 0, "Serial GCS assessment can identify changes in neurologic status over time.", "Neurologic trauma assessment"),
    q("What is the purpose of pupil assessment after head trauma?", ["Assess for neurologic abnormalities and changes over time", "Determine blood type", "Calculate fluid requirements", "Measure blood glucose"], 0, "Pupil size, symmetry, and reactivity can provide useful neurologic information.", "Head trauma"),
    q("What is a classic sign of spinal cord injury?", ["Motor or sensory deficits below the level of injury", "Only external bleeding", "Isolated nausea", "Normal neurologic function in every case"], 0, "Spinal cord injury can cause motor and sensory deficits below the injury level.", "Spinal trauma"),
    q("Why should spinal motion restriction be selective rather than automatic for every trauma patient?", ["Evidence and current guidance support identifying patients who actually need restriction while avoiding unnecessary immobilization", "All trauma patients have spinal injury", "Immobilization has no risks", "It replaces assessment"], 0, "Modern trauma care emphasizes selective spinal motion restriction based on mechanism, exam, and validated criteria rather than automatic immobilization.", "Spinal trauma"),
    q("What is a penetrating trauma mechanism?", ["An object enters the body and disrupts tissue along its path", "A blunt impact without tissue penetration", "A sprained ankle", "A thermal burn only"], 0, "Penetrating trauma involves an object entering the body and causing tissue injury along its path.", "Mechanism of injury"),
    q("Why should entry and exit wounds be considered with penetrating trauma?", ["An object can travel through tissue and create injuries at more than one site", "Exit wounds are always absent", "Only the entry wound matters", "Exit wounds are never clinically relevant"], 0, "Penetrating objects can create multiple injury sites and internal damage along their path.", "Penetrating trauma"),
    q("What is blunt trauma?", ["Injury caused by force without an object penetrating the body", "Only gunshot injury", "Only burns", "Only chemical exposure"], 0, "Blunt trauma results from impact or force without penetration.", "Mechanism of injury"),
    q("Why is mechanism of injury important?", ["It helps identify potential injuries that may not be obvious initially", "It replaces the physical exam", "It determines the exact diagnosis every time", "It only matters for billing"], 0, "Mechanism provides context for anticipating hidden injuries and guiding assessment.", "Mechanism of injury"),
    q("What is shock in trauma?", ["A state of inadequate tissue perfusion and oxygen delivery", "A normal response to pain only", "A type of fracture", "A skin condition"], 0, "Shock is inadequate tissue perfusion and oxygen delivery relative to metabolic needs.", "Traumatic shock"),
    q("What is hemorrhagic shock?", ["Shock caused by significant blood loss", "Shock caused only by fever", "Shock caused by a seizure", "A normal response to trauma"], 0, "Hemorrhagic shock results from blood loss sufficient to impair perfusion.", "Hemorrhagic shock"),
    q("Why can trauma patients have significant blood loss without obvious external bleeding?", ["Bleeding can occur internally in the chest, abdomen, pelvis, or soft tissues", "All bleeding is external", "Internal bleeding is impossible", "Only fractures bleed externally"], 0, "Major hemorrhage can occur in internal compartments and may not be visible.", "Hemorrhage"),
    q("What is the shock index?", ["Heart rate divided by systolic blood pressure", "Systolic pressure divided by respiratory rate", "GCS divided by pulse", "MAP divided by weight"], 0, "Shock index is commonly calculated as heart rate divided by systolic blood pressure.", "Trauma calculations"),
    q("Why can shock index be useful in trauma?", ["It provides a quick hemodynamic ratio that may help identify physiologic stress", "It diagnoses the bleeding location", "It replaces the physical exam", "It determines blood type"], 0, "Shock index can provide a quick indicator of circulatory stress when interpreted with the full clinical picture.", "Trauma calculations"),
    q("What is a burn involving the epidermis only commonly called?", ["Superficial burn", "Full-thickness burn", "Deep partial-thickness burn", "Electrical injury"], 0, "A superficial burn is limited to the epidermis.", "Burns"),
    q("What is a full-thickness burn?", ["A burn extending through the full thickness of the skin", "A minor sunburn only", "A superficial abrasion", "A bruise"], 0, "A full-thickness burn destroys the epidermis and dermis and may involve deeper tissue.", "Burns"),
    q("Why is burn size expressed as TBSA?", ["It estimates the percentage of body surface involved and helps guide assessment and treatment", "It determines blood type", "It replaces airway assessment", "It measures burn depth only"], 0, "Total body surface area helps quantify burn extent and can inform resuscitation decisions.", "Burns"),
    q("Why is inhalation injury a major concern in fire victims?", ["Airway edema and toxic inhalants can cause delayed or severe respiratory compromise", "It only causes skin burns", "It cannot worsen after arrival", "It is unrelated to smoke exposure"], 0, "Inhalation injury can produce airway edema, hypoxemia, and toxic effects that may evolve over time.", "Burns and inhalation injury"),
    q("What is a key concern with circumferential full-thickness burns of an extremity?", ["They can restrict circulation as swelling develops", "They always heal without treatment", "They only affect skin color", "They improve distal perfusion"], 0, "Circumferential deep burns can act like constricting bands as edema develops and may threaten distal perfusion.", "Burn complications"),
    q("Why should a trauma patient be exposed enough to assess for hidden injuries while preventing heat loss?", ["A complete assessment requires visualization, but hypothermia worsens trauma physiology", "Exposure is never needed", "Heat loss is beneficial", "Only the head should be assessed"], 0, "Trauma patients need adequate exposure for assessment while active warming helps prevent hypothermia.", "Trauma primary survey"),
    q("Why is hypothermia dangerous in major trauma?", ["It can worsen coagulopathy and other aspects of the trauma physiology", "It improves clotting", "It prevents bleeding", "It has no physiologic effect"], 0, "Hypothermia is associated with worse trauma outcomes and can worsen coagulation abnormalities.", "Trauma physiology"),
    q("What is the trauma triad of death commonly described as?", ["Hypothermia, acidosis, and coagulopathy", "Fever, alkalosis, and hypertension", "Bradycardia, hypoglycemia, and rash", "Pain, anxiety, and nausea"], 0, "The classic trauma triad is hypothermia, acidosis, and coagulopathy.", "Trauma physiology"),
    q("Why should pain be treated in trauma patients when appropriate?", ["Pain causes physiologic stress and treatment can improve comfort and sometimes facilitate care", "Pain has no physiologic effects", "Analgesia is never appropriate", "Pain treatment replaces hemorrhage control"], 0, "Appropriate analgesia can reduce suffering and physiologic stress while being balanced against airway, respiratory, and hemodynamic considerations.", "Trauma care"),
    q("What is a key reason to perform repeated vital signs in trauma?", ["The patient’s condition can deteriorate and trends may reveal worsening shock", "One set of vitals is always sufficient", "Vital signs never change", "It replaces reassessment"], 0, "Serial vital signs help identify trends and deterioration.", "Trauma reassessment"),
    q("Why is destination selection important in major trauma?", ["Patients may benefit from transport to a facility with appropriate trauma capabilities", "All hospitals have identical resources", "Destination never matters", "Only distance matters"], 0, "Trauma systems direct patients toward facilities with the capabilities appropriate to their injuries when feasible.", "Trauma systems of care"),
    q("What is a key principle when a trauma patient deteriorates during transport?", ["Reassess immediate life threats and intervene according to the applicable protocol", "Wait until arrival without reassessment", "Stop all monitoring", "Assume the original diagnosis was correct"], 0, "Deterioration requires renewed assessment for airway, breathing, circulation, and other life threats.", "Trauma reassessment"),
    q('Why is a focused secondary survey performed after immediate life threats are addressed?', ['To identify additional injuries and establish a more complete clinical picture','To delay transport','To replace the primary survey','To determine insurance coverage'], 0, 'The secondary survey looks for additional injuries after immediate life threats have been addressed.', 'Trauma assessment'),
];

  List<_AcademyQuestion> _obNeonatalQuestions() => [
    q('What is the first general priority after delivery when assessing a newborn?', ['Rapidly assess breathing, tone, and overall transition while providing appropriate initial care', 'Immediately obtain a 12-lead ECG', 'Delay assessment for 10 minutes', 'Separate the newborn from all caregivers regardless of condition'], 0, 'Initial newborn assessment focuses on transition, breathing, tone, and the need for resuscitative support.', '2025 neonatal resuscitation guidance'),
    q('What does APGAR stand for?', ['Appearance, Pulse, Grimace, Activity, Respiration', 'Airway, Perfusion, Glucose, Assessment, Response', 'Alertness, Pupils, Gait, Airway, Reflexes', 'None of the above'], 0, 'APGAR refers to Appearance, Pulse, Grimace, Activity, and Respiration.', 'APGAR assessment'),
    q('What is shoulder dystocia?', ['A delivery complication in which the fetal shoulders do not deliver normally after the head', 'A breech presentation', 'A postpartum infection', 'A neonatal arrhythmia'], 0, 'Shoulder dystocia occurs when the shoulders fail to deliver normally after the fetal head.', 'Obstetric emergencies'),
    q('What is a key principle during a suspected shoulder dystocia emergency?', ['Recognize it promptly and perform appropriate maneuvers according to current obstetric/EMS protocol', 'Apply excessive traction to the newborn\'s head', 'Wait for spontaneous resolution without assistance', 'Pull on the umbilical cord'], 0, 'Shoulder dystocia is an obstetric emergency; excessive traction should be avoided and trained maneuvers should follow current protocol.', 'Obstetric emergencies'),
    q('Which finding is concerning for postpartum hemorrhage?', ['Heavy ongoing vaginal bleeding with signs of maternal instability', 'A small amount of expected postpartum bleeding', 'Normal maternal vital signs with no bleeding', 'A normal fetal heart rate after delivery'], 0, 'Heavy bleeding accompanied by maternal instability is concerning for postpartum hemorrhage and requires rapid management.', 'Postpartum hemorrhage'),
    q('What is the general goal when a newborn is not transitioning adequately after birth?', ['Provide appropriate initial steps and respiratory support while reassessing continuously', 'Wait until the APGAR score is calculated at five minutes before intervening', 'Only dry the newborn', 'Transport without providing stabilization'], 0, 'Resuscitation is based on the newborn\'s condition and response, not on waiting for a later APGAR score.', '2025 neonatal resuscitation guidance'),
    q('Why is neonatal temperature control important?', ['Newborns can lose heat rapidly, and hypothermia can worsen physiologic stress', 'Temperature has no clinical relevance', 'Newborns cannot become cold', 'Only adults require warming'], 0, 'Newborns are vulnerable to heat loss, so maintaining a normal temperature is an important part of care.', 'Neonatal care'),
    q('Which presentation describes a breech birth?', ['The buttocks or feet present before the head', 'The head presents first', 'The placenta presents first', 'The shoulder presents after delivery'], 0, 'Breech presentation means the buttocks or feet present before the head.', 'Obstetric emergencies'),
    q('What is an important principle when managing an obstetric emergency in the field?', ['Follow current obstetric/EMS protocol, support the mother and fetus/newborn, and prepare for rapid transport when indicated', 'Focus only on the fetus', 'Ignore maternal vital signs', 'Delay transport until every issue is resolved'], 0, 'Maternal stabilization, fetal/newborn considerations, protocol-directed care, and appropriate transport are all important.', 'Obstetric assessment'),
    q('The 2025 neonatal resuscitation guidance increased the recommended delayed cord clamping interval for many newborns who do not need immediate resuscitation to:', ['At least 60 seconds', '5 seconds', '10 seconds', '30 minutes'], 0, 'The 2025 AHA/AAP neonatal guidance recommends at least 60 seconds of delayed cord clamping for most term and preterm infants not requiring immediate resuscitation.', '2025 AHA/AAP neonatal resuscitation'),
  
    q("What is the main priority during a normal delivery?", ["Support the mother and newborn while allowing the birth to progress safely", "Pull forcefully on the newborn", "Delay all assessment", "Ignore maternal vital signs"], 0, "Normal delivery care focuses on maternal support, controlled birth, and immediate newborn assessment.", "Obstetric assessment"),
    q("What is a sign that labor may be progressing toward delivery?", ["Strong regular contractions with cervical change and an urge to push", "A stable chronic headache", "Isolated ankle swelling", "Normal appetite"], 0, "Progressive contractions, cervical change, and an urge to push can indicate advanced labor.", "Labor assessment"),
    q("What is a crowning presentation?", ["The fetal head remains visible at the vaginal opening during a contraction", "The placenta is delivered first", "The feet are presenting", "The cord is wrapped around the neck"], 0, "Crowning means the fetal head is visible at the vaginal opening during a contraction.", "Normal delivery"),
    q("What is a breech presentation?", ["The buttocks or feet present before the head", "The head presents first", "The placenta presents first", "The shoulders always present first"], 0, "Breech presentation means the buttocks or feet are presenting before the head.", "Obstetric emergencies"),
    q("What is shoulder dystocia?", ["The shoulders fail to deliver normally after the fetal head", "A breech birth", "A postpartum infection", "A neonatal seizure"], 0, "Shoulder dystocia occurs when the fetal shoulders do not deliver normally after the head.", "Obstetric emergencies"),
    q("Why is shoulder dystocia an emergency?", ["Delay can compromise fetal oxygenation and increase maternal and neonatal complications", "It always resolves without intervention", "It affects only the placenta", "It is not time sensitive"], 0, "Shoulder dystocia can rapidly threaten fetal oxygenation and requires prompt, protocol-directed maneuvers.", "Obstetric emergencies"),
    q("What should be avoided during shoulder dystocia?", ["Excessive traction on the fetal head", "Calling for help", "Positioning maneuvers", "Following the applicable protocol"], 0, "Excessive traction on the fetal head can cause injury and should be avoided.", "Obstetric emergencies"),
    q("What is a nuchal cord?", ["Umbilical cord wrapped around the fetal neck", "Placenta covering the cervix", "A uterine rupture", "A breech presentation"], 0, "A nuchal cord is an umbilical cord loop around the fetal neck.", "Normal delivery"),
    q("What is postpartum hemorrhage?", ["Excessive bleeding after delivery that can cause maternal instability", "Normal lochia only", "A neonatal respiratory disorder", "A fetal presentation"], 0, "Postpartum hemorrhage is significant bleeding after delivery and can rapidly cause maternal shock.", "Postpartum hemorrhage"),
    q("What is a key assessment priority in postpartum hemorrhage?", ["Maternal circulation, bleeding severity, uterine tone, and rapid supportive management", "Only fetal heart rate", "Only the newborn’s weight", "Ignore vital signs"], 0, "Maternal hemodynamics and bleeding are central to postpartum hemorrhage assessment and management.", "Postpartum hemorrhage"),
    q("What can a boggy uterus after delivery suggest?", ["Uterine atony", "Normal uterine contraction", "A shoulder dystocia", "A neonatal airway problem"], 0, "A boggy uterus can indicate uterine atony, a common cause of postpartum hemorrhage.", "Postpartum hemorrhage"),
    q("What is placenta previa?", ["Placental tissue located over or near the cervical opening", "Premature placental separation", "A breech birth", "A neonatal infection"], 0, "Placenta previa involves placental implantation over or near the cervical opening.", "Obstetric bleeding"),
    q("Why can vaginal bleeding with placenta previa be dangerous?", ["Significant maternal hemorrhage can occur", "It never causes bleeding", "It always causes abdominal trauma", "It only affects the newborn"], 0, "Placenta previa can produce significant maternal bleeding.", "Obstetric bleeding"),
    q("What is placental abruption?", ["Premature separation of the placenta from the uterine wall", "Placenta covering the cervix", "A normal delivery stage", "A neonatal respiratory condition"], 0, "Placental abruption is premature separation of the placenta from the uterine wall.", "Obstetric bleeding"),
    q("Which finding can be concerning for placental abruption?", ["Painful vaginal bleeding with uterine tenderness or contractions", "Painless bleeding only in every case", "Normal pregnancy symptoms only", "An isolated sore throat"], 0, "Abruption can present with painful bleeding, uterine tenderness, contractions, or fetal distress.", "Obstetric bleeding"),
    q("What is eclampsia?", ["Seizure in a pregnant or postpartum patient associated with a hypertensive disorder of pregnancy", "Any seizure in a child", "A normal stage of labor", "A neonatal condition"], 0, "Eclampsia refers to seizures associated with preeclampsia or a related hypertensive disorder of pregnancy.", "Hypertensive disorders of pregnancy"),
    q("Why is severe hypertension during pregnancy concerning?", ["It can be associated with serious maternal and fetal complications", "It is always normal", "It rules out preeclampsia", "It has no neurologic significance"], 0, "Severe hypertension can accompany preeclampsia/eclampsia and requires urgent evaluation and protocol-directed management.", "Hypertensive disorders of pregnancy"),
    q("What is preeclampsia?", ["A hypertensive disorder of pregnancy with associated maternal organ involvement in severe disease", "A normal pregnancy change", "A neonatal infection", "A placental presentation"], 0, "Preeclampsia is a pregnancy-associated hypertensive disorder that can involve maternal organ dysfunction.", "Hypertensive disorders of pregnancy"),
    q("What is a key concern after an eclamptic seizure?", ["Airway, breathing, maternal safety, and recurrent seizure risk", "Only the newborn’s weight", "No further assessment", "Immediate oral fluids"], 0, "After a seizure, maternal airway, breathing, circulation, injury, and recurrence risk require attention.", "Eclampsia"),
    q("What is the APGAR score designed to assess?", ["A newborn’s condition and transition shortly after birth", "Maternal blood pressure", "Placental location", "Gestational age only"], 0, "APGAR assesses newborn appearance, pulse, grimace, activity, and respiration.", "APGAR assessment"),
    q("When is APGAR commonly assessed?", ["At 1 and 5 minutes after birth, with additional assessments when indicated", "Only before delivery", "Only 30 minutes after birth", "Only if the mother is unstable"], 0, "APGAR is commonly assessed at 1 and 5 minutes, with further scoring when indicated.", "APGAR assessment"),
    q("What does the A in APGAR represent?", ["Appearance", "Airway only", "Activity only", "Auscultation"], 0, "A represents appearance, referring to color in the traditional scoring system.", "APGAR assessment"),
    q("What does the P in APGAR represent?", ["Pulse", "Pupils", "Perfusion only", "Pain"], 0, "P represents pulse.", "APGAR assessment"),
    q("What does the G in APGAR represent?", ["Grimace", "Glucose", "Gait", "Gurgling"], 0, "G represents grimace or reflex irritability.", "APGAR assessment"),
    q("What does the second A in APGAR represent?", ["Activity", "Airway", "Auscultation", "Arterial pressure"], 0, "The second A represents activity or muscle tone.", "APGAR assessment"),
    q("What does the R in APGAR represent?", ["Respiration", "Reflexes only", "Rate of maternal pulse", "Rewarming"], 0, "R represents respiration.", "APGAR assessment"),
    q("Why should APGAR not be used to decide whether initial neonatal resuscitation should begin?", ["Resuscitation decisions are based on the newborn’s immediate condition and response", "APGAR is only used before birth", "APGAR is a maternal score", "APGAR replaces ventilation assessment"], 0, "Initial neonatal resuscitation is guided by immediate assessment and response; APGAR is not the trigger for beginning resuscitation.", "2025 AHA/AAP neonatal resuscitation"),
    q("What is the primary intervention for a newborn who is apneic or has inadequate breathing after initial steps?", ["Provide appropriate positive-pressure ventilation when indicated", "Wait for the 5-minute APGAR", "Give oral fluids", "Perform a 12-lead ECG first"], 0, "Effective ventilation is the key intervention when a newborn is apneic or not breathing effectively after initial steps.", "2025 AHA/AAP neonatal resuscitation"),
    q("Why is effective ventilation central to neonatal resuscitation?", ["Failure to establish breathing is a major contributor to neonatal compromise", "Newborn arrests are always primary VF", "Ventilation has no effect", "Only chest compressions matter"], 0, "The 2025 neonatal guidance emphasizes effective ventilation because inadequate respiration contributes significantly to newborn morbidity and mortality.", "2025 AHA/AAP neonatal resuscitation"),
    q("What is delayed cord clamping generally recommended for in many newborns who do not require immediate resuscitation?", ["At least 60 seconds", "5 seconds", "10 minutes in every case", "No delay is ever recommended"], 0, "The 2025 AHA/AAP guidance recommends delayed cord clamping for at least 60 seconds in most term and preterm infants who do not require immediate resuscitation.", "2025 AHA/AAP neonatal resuscitation"),
    q("Why is neonatal thermoregulation important?", ["Newborns can lose heat rapidly and hypothermia can worsen physiologic stress", "Temperature has no clinical impact", "Only adults require warming", "It replaces ventilation"], 0, "Newborns are vulnerable to heat loss, and maintaining temperature is an important part of neonatal care.", "2025 AHA/AAP neonatal resuscitation"),
    q("What is a key concern with meconium-stained amniotic fluid?", ["The newborn may require assessment and respiratory support if not transitioning normally", "It always requires routine deep suctioning", "It guarantees airway obstruction", "It rules out resuscitation"], 0, "Meconium exposure requires appropriate newborn assessment; routine invasive suctioning is not automatically indicated solely because meconium is present.", "2025 AHA/AAP neonatal resuscitation"),
    q("What is a normal general priority after a vigorous newborn is born?", ["Support normal transition, warmth, skin-to-skin care, and appropriate assessment", "Separate every newborn immediately", "Delay all assessment", "Perform chest compressions routinely"], 0, "Healthy newborns benefit from normal transition support including warmth, assessment, and skin-to-skin care when appropriate.", "2025 AHA/AAP neonatal resuscitation"),
    q("Why can a newborn become hypothermic quickly?", ["Large surface area relative to body mass and limited thermoregulatory reserve", "Newborns generate excessive heat", "Their skin prevents heat loss completely", "They cannot lose heat"], 0, "Newborns have limited thermoregulatory reserve and can lose heat rapidly.", "Neonatal thermoregulation"),
    q("What is the purpose of neonatal stimulation during initial care?", ["Encourage spontaneous breathing in a newborn who needs appropriate initial stimulation", "Cause crying in every newborn", "Replace positive-pressure ventilation when apnea persists", "Treat maternal hemorrhage"], 0, "Drying and appropriate tactile stimulation can help a newborn establish breathing when indicated, but persistent apnea requires ventilation support.", "2025 AHA/AAP neonatal resuscitation"),
    q("What is a key sign that a newborn may need more than routine transition support?", ["Apnea, gasping, or persistent inadequate breathing", "Strong cry and good tone", "Normal breathing and color", "Active movement"], 0, "Apnea, gasping, or inadequate breathing are signs that additional resuscitative support may be needed.", "2025 AHA/AAP neonatal resuscitation"),
    q("What is the purpose of assessing maternal vital signs after delivery?", ["Maternal deterioration can occur after birth and may be related to hemorrhage or hypertensive complications", "Maternal status is no longer important", "It only determines the newborn’s APGAR", "It replaces newborn assessment"], 0, "Maternal complications such as hemorrhage and hypertension can occur after delivery and require ongoing assessment.", "Postpartum assessment"),
    q("Why should EMS prepare for neonatal resuscitation when responding to an imminent delivery?", ["Newborn transition can be unpredictable and time-critical interventions may be needed", "All newborns require intubation", "It replaces maternal care", "It is only needed in the hospital"], 0, "Teams attending an imminent delivery should be prepared for newborn resuscitation because some infants require rapid intervention.", "2025 AHA/AAP neonatal resuscitation"),
    q("What is a key principle in an obstetric emergency?", ["Treat the mother while considering fetal/newborn needs and prepare for rapid transport when indicated", "Treat only the fetus", "Ignore maternal circulation", "Delay transport until every issue is resolved"], 0, "Maternal stabilization, fetal/newborn considerations, protocol-directed care, and appropriate transport all matter.", "Obstetric emergencies"),
    q("Why should the placenta be retained for transport when possible after delivery?", ["It may provide useful information for hospital evaluation", "It is never relevant", "It determines APGAR", "It replaces maternal assessment"], 0, "Retaining the placenta for hospital evaluation can provide clinically useful information in some delivery complications.", "Post-delivery care"),];

  Widget _questionView(BuildContext context) {
    final question = _currentQuestion!;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_rounded, color: primary),
                const SizedBox(width: 8),
                Text('Knowledge Check', style: TextStyle(fontWeight: FontWeight.w800, color: primary)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35),
            ),
            const SizedBox(height: 16),
            ...List.generate(question.options.length, (i) {
              final isCorrect = i == question.answerIndex;
              final isSelected = i == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: OutlinedButton(
                  onPressed: () => _selectAnswer(i),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(question.options[i], style: const TextStyle(fontSize: 15.5))),
                      if (_answered && isCorrect) const Icon(Icons.check_circle_rounded, color: Colors.green),
                      if (_answered && isSelected && !isCorrect) const Icon(Icons.cancel_rounded, color: Colors.red),
                    ],
                  ),
                ),
              );
            }),
            if (_answered) ...[
              const SizedBox(height: 8),
              Text(
                _selectedIndex == question.answerIndex ? 'Correct.' : 'Not quite.',
                style: TextStyle(
                  color: _selectedIndex == question.answerIndex ? Colors.green : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(question.explanation, style: TextStyle(fontSize: 15, color: onSurfaceVariant, height: 1.45)),
              const SizedBox(height: 10),
              Text('Reference: ${question.reference}', style: TextStyle(fontSize: 12.5, color: onSurfaceVariant)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _nextQuestion,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next Question'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final total = _academyQuestions(widget.academy).length;
    final accuracy = _answeredCount == 0 ? 0 : ((_score / _answeredCount) * 100).round();

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_rounded, color: primary, size: 30),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.academy, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Work through an endless pool of EMS knowledge questions. There is no final exam—answer a question, review the explanation, and keep going.',
                  style: TextStyle(fontSize: 15, color: onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _questionView(context),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: BaxterIconBadge(icon: Icons.insights_rounded, color: primary, size: 58, iconSize: 28),
                    title: const Text('Study Progress', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('$_score correct out of $_answeredCount answered • $accuracy% accuracy • ${total}-question pool'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Training content is intended for education and review. Always follow your current agency protocols, medical direction, and current authoritative guidance for patient care.',
                  style: TextStyle(fontSize: 13, color: onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;
  final String reference;

  const _AcademyQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    required this.reference,
  });
}

class _EducationProtocolSection {
  final String protocolTitle;
  final String label;
  final String text;

  const _EducationProtocolSection(this.protocolTitle, this.label, this.text);
}

class _EducationQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String reference;

  const _EducationQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.reference,
  });
}

class PlaceholderInfoPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const PlaceholderInfoPage({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(icon, size: 52, color: primary),
                        const SizedBox(height: 14),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class ProtocolCategoriesPage extends StatelessWidget {
  const ProtocolCategoriesPage({super.key});

  static const _categories = <_ProtocolCategoryItem>[
    _ProtocolCategoryItem('General', 'General patient care and core EMS procedures', Icons.description_rounded, Color(0xFF1976D2)),
    _ProtocolCategoryItem('Medications', 'Medication indications, dosing, and administration', Icons.medication_rounded, Color(0xFF7B1FA2)),
    _ProtocolCategoryItem('Procedures', 'Field procedures and treatment techniques', Icons.build_circle_rounded, Color(0xFF00897B)),
    _ProtocolCategoryItem('Cardiac', 'Cardiac arrest, ACS, dysrhythmias, and cardiac care', Icons.favorite_rounded, Color(0xFFD32F2F)),
    _ProtocolCategoryItem('Respiratory', 'Airway, ventilation, oxygenation, and respiratory emergencies', Icons.air_rounded, Color(0xFF00838F)),
    _ProtocolCategoryItem('Medical', 'Medical emergencies and system-specific conditions', Icons.medical_services_rounded, Color(0xFF388E3C)),
    _ProtocolCategoryItem('Trauma', 'Trauma assessment, injury care, and hemorrhage', Icons.healing_rounded, Color(0xFFEF6C00)),
    _ProtocolCategoryItem('OB/GYN', 'Obstetric and gynecologic emergencies', Icons.pregnant_woman_rounded, Color(0xFFD81B60)),
    _ProtocolCategoryItem('Pediatric', 'Pediatric medical and traumatic emergencies', Icons.child_care_rounded, Color(0xFF3949AB)),
    _ProtocolCategoryItem('Forms', 'Forms and documentation resources', Icons.assignment_rounded, Color(0xFF546E7A)),
  ];

  void _openCategory(BuildContext context, String category) {
    final results = allProtocols.where((p) => p.category == category).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProtocolsPage(protocols: results, title: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 88),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final item = _categories[index];
                return _ProtocolCategoryCard(
                  item: item,
                  onTap: () => _openCategory(context, item.title),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

class _ProtocolCategoryItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _ProtocolCategoryItem(this.title, this.subtitle, this.icon, this.color);
}

class _ProtocolBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ProtocolBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF131D28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5)),
          BoxShadow(color: Color(0x22025EFF), blurRadius: 6, offset: Offset(0, -1)),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF2F5F8), size: 19),
      ),
    );
  }
}

class _ProtocolCategoryCard extends StatelessWidget {
  final _ProtocolCategoryItem item;
  final VoidCallback onTap;
  const _ProtocolCategoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF182431),
            const Color(0xFF0E171F),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 7)),
          BoxShadow(color: Color(0x18025EFF), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                BaxterIconBadge(icon: item.icon, color: item.color, size: 66, iconSize: 34),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFF2F5F8))),
                      const SizedBox(height: 4),
                      Text(item.subtitle, style: const TextStyle(fontSize: 13, height: 1.25, color: Color(0xFFAEBED0))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFF2F5F8), size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProtocolsPage extends StatefulWidget {
  final List<Protocol> protocols;
  final String title;

  const ProtocolsPage({super.key, required this.protocols, this.title = 'All Protocols'});

  @override
  State<ProtocolsPage> createState() => _ProtocolsPageState();
}

class _ProtocolsPageState extends State<ProtocolsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
              itemCount: widget.protocols.length,
              itemBuilder: (context, i) {
          final p = widget.protocols[i];
          final fav = favorites.contains(p.title);
                return Card(
                  child: ListTile(
                    title: Text(p.title),
                    subtitle: Text(p.category),
                    trailing: IconButton(
                      icon: Icon(fav ? Icons.star : Icons.star_border),
                      onPressed: () {
                        setState(() {
                          fav ? favorites.remove(p.title) : favorites.add(p.title);
                        });
                      },
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProtocolDetailPage(protocol: p),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  final List<Protocol> protocols;

  const FavoritesPage({super.key, required this.protocols});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    final items = widget.protocols
        .where((p) => favorites.contains(p.title))
        .toList();

    return Scaffold(
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No favorites yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                final p = items[i];
                    return Card(
                      child: ListTile(
                        title: Text(p.title),
                        subtitle: Text(p.category),
                        trailing: IconButton(
                          icon: const Icon(Icons.star),
                          onPressed: () =>
                              setState(() => favorites.remove(p.title)),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProtocolDetailPage(protocol: p),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class WhatsNewPage extends StatefulWidget {
  const WhatsNewPage({super.key});

  @override
  State<WhatsNewPage> createState() => _WhatsNewPageState();
}

class _WhatsNewPageState extends State<WhatsNewPage> {
  static const _feedKey = 'aha_updates_feed';
  static const _appFeedKey = 'app_updates_feed';
  static const _lastCheckedKey = 'aha_updates_last_checked';
  static const _appLastCheckedKey = 'app_updates_last_checked';

  List<Map<String, dynamic>> _updates = const [];
  List<Map<String, dynamic>> _appUpdates = const [];
  bool _loading = true;
  bool _checking = false;
  DateTime? _lastChecked;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCachedAndRefresh();
  }

  Future<void> _loadCachedAndRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_feedKey);
    final appCached = prefs.getString(_appFeedKey);
    final checked = prefs.getString(_lastCheckedKey);

    if (appCached != null) {
      try {
        final decoded = jsonDecode(appCached);
        if (decoded is List) {
          _appUpdates = decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }

    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is List) {
          _updates = decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }
    if (checked != null) _lastChecked = DateTime.tryParse(checked);
    if (mounted) setState(() => _loading = false);
    await _refreshFeed(silent: true);
  }

  Future<void> _refreshFeed({bool silent = false}) async {
    if (_checking) return;
    if (mounted) setState(() { _checking = true; _error = null; });
    try {
      final ahaUri = Uri.base.resolve('updates.json');
      final appUri = Uri.base.resolve('app_updates.json');
      final results = await Future.wait([
        http.get(ahaUri).timeout(const Duration(seconds: 10)),
        http.get(appUri).timeout(const Duration(seconds: 10)),
      ]);

      final ahaResponse = results[0];
      final appResponse = results[1];
      if (ahaResponse.statusCode != 200) throw Exception('AHA HTTP ${ahaResponse.statusCode}');
      if (appResponse.statusCode != 200) throw Exception('APP HTTP ${appResponse.statusCode}');

      final ahaDecoded = jsonDecode(ahaResponse.body);
      final appDecoded = jsonDecode(appResponse.body);
      if (ahaDecoded is! List || appDecoded is! List) {
        throw const FormatException('Invalid update feed');
      }

      final ahaUpdates = ahaDecoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final appUpdates = appDecoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_feedKey, jsonEncode(ahaUpdates));
      await prefs.setString(_appFeedKey, jsonEncode(appUpdates));
      final now = DateTime.now();
      await prefs.setString(_lastCheckedKey, now.toIso8601String());
      await prefs.setString(_appLastCheckedKey, now.toIso8601String());

      if (mounted) {
        setState(() {
          _updates = ahaUpdates;
          _appUpdates = appUpdates;
          _lastChecked = now;
        });
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _error = 'Unable to check for online updates. Showing the last saved update feed.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openUpdate(String? url) async {
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    final sourceUpdates = _updates.where((u) => u['source'] == 'AHA').toList();

    return Scaffold(
      appBar: BaxterAppBar(
        actions: [
          IconButton(
            tooltip: 'Check for updates',
            onPressed: _checking ? null : () => _refreshFeed(),
            icon: _checking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text("What's New", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: onSurface)),
                const SizedBox(height: 6),
                Text(
                  'Recent AHA changes are checked online and saved for offline viewing.',
                  style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant, height: 1.35),
                ),
                if (_lastChecked != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Last checked: ${_formatDateTime(_lastChecked!)}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 18),
                _sectionHeader(context, 'App Updates', Icons.system_update_rounded),
                const SizedBox(height: 8),
                if (_appUpdates.isEmpty)
                  Card(
                    child: ListTile(
                      leading: BaxterIconBadge(icon: Icons.info_outline_rounded, color: scheme.primary, size: 54, iconSize: 26),
                      title: const Text('No app updates loaded', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('App feature changes are published with each updated build.'),
                    ),
                  )
                else
                  ..._appUpdates.map((update) => _AppUpdateCard(update: update)),
                const SizedBox(height: 20),
                _sectionHeader(context, 'AHA Updates', Icons.favorite_rounded),
                const SizedBox(height: 8),
                if (_loading && sourceUpdates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (sourceUpdates.isEmpty)
                  Card(
                    child: ListTile(
                      leading: BaxterIconBadge(icon: Icons.cloud_off_rounded, color: scheme.primary, size: 54, iconSize: 26),
                      title: const Text('No AHA updates loaded', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Connect to the internet and tap refresh to check the AHA update feed.'),
                    ),
                  )
                else
                  ...sourceUpdates.map((update) => _UpdateCard(
                        update: update,
                        onTap: () => _openUpdate(update['url'] as String?),
                      )),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: scheme.error, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                _sectionHeader(context, 'Current Protocol Set', Icons.library_books_rounded),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: BaxterIconBadge(icon: Icons.verified_rounded, color: scheme.primary, size: 54, iconSize: 26),
                    title: const Text('Baxter Regional Medical Center Ambulance Protocols — 2021', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('No newer Baxter protocol set has been loaded into this app.'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'App changes are generated from the project update feed whenever a new build is published.',
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: scheme.onSurface)),
      ],
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.month}/${local.day}/${local.year} $hour:$minute $suffix';
  }
}

class _AppUpdateCard extends StatelessWidget {
  final Map<String, dynamic> update;

  const _AppUpdateCard({required this.update});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = update['date'] as String? ?? '';
    final title = update['title'] as String? ?? 'App Update';
    final description = update['description'] as String? ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(Icons.new_releases_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.primary)),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(description, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant, height: 1.35)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  final Map<String, dynamic> update;
  final VoidCallback onTap;

  const _UpdateCard({required this.update, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = update['date'] as String? ?? '';
    final title = update['title'] as String? ?? 'AHA Update';
    final description = update['description'] as String? ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.new_releases_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.primary)),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(description, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant, height: 1.35)),
                    ],
                    const SizedBox(height: 8),
                    Text('Open official AHA update  ›', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.primary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsNewFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _WhatsNewFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 5,
        ),
        leading: BaxterIconBadge(icon: icon, color: Theme.of(context).colorScheme.primary, size: 58, iconSize: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description),
        ),
      ),
    );
  }
}

class ProtocolDetailPage extends StatefulWidget {
  final Protocol protocol;

  const ProtocolDetailPage({super.key, required this.protocol});

  @override
  State<ProtocolDetailPage> createState() => _ProtocolDetailPageState();
}

class _ProtocolDetailPageState extends State<ProtocolDetailPage> {
  @override
  Widget build(BuildContext context) {
    final fav = favorites.contains(widget.protocol.title);

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: BaxterAppBar(
        actions: [
          IconButton(
            tooltip: 'Favorite',
            icon: Icon(fav ? Icons.star : Icons.star_border),
            onPressed: () {
              setState(() {
                fav
                    ? favorites.remove(widget.protocol.title)
                    : favorites.add(widget.protocol.title);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(child: TextOnlyProtocolPage(protocol: widget.protocol)),
        ],
      ),
    );
  }
}

/// Clean, fully native text presentation.
///
/// There are deliberately no PDF pages, images, boxes, borders, or page
/// numbers here. The source wording remains in the protocol data; this widget
/// only controls typography, hierarchy, spacing, and wrapping.
class TextOnlyProtocolPage extends StatelessWidget {
  final Protocol protocol;

  const TextOnlyProtocolPage({super.key, required this.protocol});

  static const _serif = 'Times New Roman';

  TextStyle _textStyle(BuildContext context, {
    bool bold = false,
    double size = 16,
    double height = 1.35,
  }) {
    return TextStyle(
      fontFamily: _serif,
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: Theme.of(context).colorScheme.onSurface,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parseSections(protocol.content);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 96),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    protocol.title,
                    textAlign: TextAlign.center,
                    style: _textStyle(context, bold: true, size: 25, height: 1.15),
                  ),
                ),
                const SizedBox(height: 30),
                ...sections.map((section) => _buildSection(context, section)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, _ProtocolSection section) {
    if (section.label.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(section.body, style: _textStyle(context)),
      );
    }

    final blocks = section.body.split('\n\n');

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: RichText(
        text: TextSpan(
          style: _textStyle(context),
          children: [
            TextSpan(
              text: '${section.label}:\n',
              style: _textStyle(context, bold: true, size: 16),
            ),
            for (int i = 0; i < blocks.length; i++) ...[
              TextSpan(text: blocks[i]),
              if (i < blocks.length - 1) const TextSpan(text: '\n\n'),
            ],
          ],
        ),
      ),
    );
  }

  List<_ProtocolSection> _parseSections(String source) {
    final lines = source.replaceAll('\r', '').split('\n');
    final labels = <String>[
      'Effects',
      'Effect',
      'Indications',
      'Contraindications',
      'Contraindication',
      'Adverse Reactions',
      'Precautions',
      'Side Effects',
      'Dose',
      'Dosage',
      'Adult Dose',
      'Pedi Dose',
      'Pediatric Dose',
      'Procedure',
      'Procedures',
      'Actions',
      'Considerations',
      'Medical Control',
      'Guidelines of Care',
      'Notes',
      'Note',
      'Competency',
      'Quality Improvement/Key Documentation Elements',
      'Performance Measures (Process, Structure, and Outcomes)',
      'Treatment',
      'Treatment and Interventions',
    ];

    final result = <_ProtocolSection>[];
    String? currentLabel;
    final current = <String>[];

    void flush() {
      if (currentLabel == null) return;
      final body = _reflow(current);
      if (body.isNotEmpty) {
        result.add(_ProtocolSection(currentLabel!, body));
      }
      current.clear();
    }

    for (final raw in lines.skip(1)) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        if (current.isNotEmpty && current.last.isNotEmpty) {
          current.add('');
        }
        continue;
      }

      String? matched;
      String remainder = '';
      for (final label in labels) {
        final lower = trimmed.toLowerCase();
        final target = label.toLowerCase();
        if (lower == target ||
            lower == '$target:' ||
            lower.startsWith('$target:') ||
            lower.startsWith('$target ')) {
          matched = label;
          remainder = trimmed.substring(label.length).replaceFirst(':', '').trim();
          break;
        }
      }

      if (matched != null) {
        flush();
        currentLabel = matched;
        if (remainder.isNotEmpty) current.add(remainder);
      } else {
        current.add(trimmed);
      }
    }
    flush();

    if (result.isEmpty) {
      final body = _reflow(lines.skip(1).toList());
      return [if (body.isNotEmpty) _ProtocolSection('', body)];
    }

    return result;
  }

  String _reflow(List<String> lines) {
    final paragraphs = <String>[];
    var buffer = StringBuffer();

    void flushBuffer() {
      final value = buffer.toString().trim();
      if (value.isNotEmpty) paragraphs.add(value);
      buffer = StringBuffer();
    }

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        flushBuffer();
        continue;
      }

      final isBullet = RegExp(r'^(?:[•▪◦]|[-*])\s*').hasMatch(line);
      final isNumbered = RegExp(r'^\d+[\.)]\s+').hasMatch(line);
      final isIndentedList = RegExp(r'^[a-zA-Z][\.)]\s+').hasMatch(line);

      if (isBullet || isNumbered || isIndentedList) {
        flushBuffer();
        paragraphs.add(_cleanInline(line));
      } else {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(_cleanInline(line));
      }
    }
    flushBuffer();

    return paragraphs.join('\n\n');
  }

  String _cleanInline(String text) {
    return text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll('', '•')
        .replaceAll('', '•')
        .trim();
  }
}

class _ProtocolSection {
  final String label;
  final String body;

  const _ProtocolSection(this.label, this.body);
}

class SettingsPage extends StatelessWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const SettingsPage({
    super.key,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const BaxterAppBar(),
        body: Column(
          children: [
            const TopSearchBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                children: [
                  Card(
                    child: SwitchListTile(
                      secondary: Icon(
                        darkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: const Color(0xFF025EFF),
                      ),
                      title: const Text(
                        'Dark Mode',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        darkMode ? 'Enabled' : 'Disabled',
                      ),
                      value: darkMode,
                      onChanged: onDarkModeChanged,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Protocol Information',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Protocol Version',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text('2021'),
                          SizedBox(height: 12),
                          Text(
                            'Source',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text('Baxter Regional Medical Center'),
                          SizedBox(height: 12),
                          Text(
                            'Last Updated',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text('Not specified in the source protocol set'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: BaxterIconBadge(icon: Icons.library_books_rounded, color: const Color(0xFF025EFF), size: 54, iconSize: 26),
                      title: Text(
                        'Protocol Set: 2021',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'This identifies the protocol set currently loaded in the prototype.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}


class _MedicationIndexEntry {
  final String generic;
  final List<String> brands;
  const _MedicationIndexEntry(this.generic, this.brands);
}

const List<_MedicationIndexEntry> _medicationIndex = [
  _MedicationIndexEntry('Apixaban', ['Eliquis']),
  _MedicationIndexEntry('Amiodarone', ['Cordarone', 'Pacerone']),
  _MedicationIndexEntry('Amlodipine', ['Norvasc']),
  _MedicationIndexEntry('Amoxicillin', ['Amoxil']),
  _MedicationIndexEntry('Atorvastatin', ['Lipitor']),
  _MedicationIndexEntry('Azithromycin', ['Zithromax', 'Z-Pak']),
  _MedicationIndexEntry('Clopidogrel', ['Plavix']),
  _MedicationIndexEntry('Diltiazem', ['Cardizem', 'Tiazac']),
  _MedicationIndexEntry('Escitalopram', ['Lexapro']),
  _MedicationIndexEntry('Furosemide', ['Lasix']),
  _MedicationIndexEntry('Gabapentin', ['Neurontin']),
  _MedicationIndexEntry('Hydrochlorothiazide', ['Microzide']),
  _MedicationIndexEntry('Lisinopril', ['Prinivil', 'Zestril']),
  _MedicationIndexEntry('Losartan', ['Cozaar']),
  _MedicationIndexEntry('Metformin', ['Glucophage']),
  _MedicationIndexEntry('Metoprolol', ['Lopressor', 'Toprol-XL']),
  _MedicationIndexEntry('Montelukast', ['Singulair']),
  _MedicationIndexEntry('Naloxone', ['Narcan']),
  _MedicationIndexEntry('Nitroglycerin', ['Nitrostat']),
  _MedicationIndexEntry('Ondansetron', ['Zofran']),
  _MedicationIndexEntry('Pantoprazole', ['Protonix']),
  _MedicationIndexEntry('Prednisone', []),
  _MedicationIndexEntry('Sertraline', ['Zoloft']),
  _MedicationIndexEntry('Simvastatin', ['Zocor']),
  _MedicationIndexEntry('Spironolactone', ['Aldactone']),
  _MedicationIndexEntry('Tamsulosin', ['Flomax']),
  _MedicationIndexEntry('Tramadol', ['Ultram']),
  _MedicationIndexEntry('Warfarin', ['Coumadin', 'Jantoven']),
  _MedicationIndexEntry('Albuterol', ['Ventolin', 'ProAir', 'Proventil']),
  _MedicationIndexEntry('Alprazolam', ['Xanax']),
  _MedicationIndexEntry('Aspirin', ['Bayer']),
  _MedicationIndexEntry('Carvedilol', ['Coreg']),
  _MedicationIndexEntry('Citalopram', ['Celexa']),
  _MedicationIndexEntry('Doxycycline', ['Vibramycin']),
  _MedicationIndexEntry('Duloxetine', ['Cymbalta']),
  _MedicationIndexEntry('Fluoxetine', ['Prozac']),
  _MedicationIndexEntry('Hydroxyzine', ['Vistaril', 'Atarax']),
  _MedicationIndexEntry('Ibuprofen', ['Advil', 'Motrin']),
  _MedicationIndexEntry('Insulin glargine', ['Lantus', 'Basaglar', 'Semglee']),
  _MedicationIndexEntry('Insulin lispro', ['Humalog']),
  _MedicationIndexEntry('Levetiracetam', ['Keppra']),
  _MedicationIndexEntry('Levothyroxine', ['Synthroid']),
  _MedicationIndexEntry('Lorazepam', ['Ativan']),
  _MedicationIndexEntry('Meloxicam', ['Mobic']),
  _MedicationIndexEntry('Methylprednisolone', ['Medrol']),
  _MedicationIndexEntry('Mirtazapine', ['Remeron']),
  _MedicationIndexEntry('Naproxen', ['Aleve', 'Naprosyn']),
  _MedicationIndexEntry('Oxycodone', ['OxyContin', 'Roxicodone']),
  _MedicationIndexEntry('Paroxetine', ['Paxil']),
  _MedicationIndexEntry('Pregabalin', ['Lyrica']),
  _MedicationIndexEntry('Quetiapine', ['Seroquel']),
  _MedicationIndexEntry('Rivaroxaban', ['Xarelto']),
  _MedicationIndexEntry('Rosuvastatin', ['Crestor']),
  _MedicationIndexEntry('Trazodone', ['Desyrel']),
  _MedicationIndexEntry('Valacyclovir', ['Valtrex']),
  _MedicationIndexEntry('Valproic acid', ['Depakene']),
  _MedicationIndexEntry('Venlafaxine', ['Effexor']),
  _MedicationIndexEntry('Zolpidem', ['Ambien']),
  _MedicationIndexEntry('Acetaminophen', ['Tylenol']),
  _MedicationIndexEntry('Atenolol', ['Tenormin']),
  _MedicationIndexEntry('Clonazepam', ['Klonopin']),
  _MedicationIndexEntry('Clonidine', ['Catapres']),
  _MedicationIndexEntry('Digoxin', ['Lanoxin']),
  _MedicationIndexEntry('Dapagliflozin', ['Farxiga']),
  _MedicationIndexEntry('Empagliflozin', ['Jardiance']),
  _MedicationIndexEntry('Glipizide', ['Glucotrol']),
  _MedicationIndexEntry('Isosorbide mononitrate', ['Imdur']),
  _MedicationIndexEntry('Labetalol', ['Trandate']),
  _MedicationIndexEntry('Loratadine', ['Claritin']),
  _MedicationIndexEntry('Omeprazole', ['Prilosec']),
  _MedicationIndexEntry('Propranolol', ['Inderal']),
  _MedicationIndexEntry('Ropinirole', ['Requip']),
  _MedicationIndexEntry('Topiramate', ['Topamax']),
  _MedicationIndexEntry('Torsemide', ['Demadex']),
  _MedicationIndexEntry('Bupropion', ['Wellbutrin']),
  _MedicationIndexEntry('Buspirone', ['BuSpar']),
  _MedicationIndexEntry('Cyclobenzaprine', ['Flexeril']),
  _MedicationIndexEntry('Dexamethasone', ['Decadron']),
  _MedicationIndexEntry('Famotidine', ['Pepcid']),
  _MedicationIndexEntry('Lansoprazole', ['Prevacid']),
  _MedicationIndexEntry('Methocarbamol', ['Robaxin']),
  _MedicationIndexEntry('Methylphenidate', ['Ritalin', 'Concerta']),
  _MedicationIndexEntry('Ondansetron', ['Zofran ODT']),
  _MedicationIndexEntry('Risperidone', ['Risperdal']),
  _MedicationIndexEntry('Sildenafil', ['Viagra']),
  _MedicationIndexEntry('Tadalafil', ['Cialis']),
  _MedicationIndexEntry('Tizanidine', ['Zanaflex']),
  _MedicationIndexEntry('Acyclovir', ['Zovirax']),
  _MedicationIndexEntry('Baclofen', ['Lioresal']),
  _MedicationIndexEntry('Cefdinir', ['Omnicef']),
  _MedicationIndexEntry('Cephalexin', ['Keflex']),
  _MedicationIndexEntry('Ciprofloxacin', ['Cipro']),
  _MedicationIndexEntry('Clindamycin', ['Cleocin']),
  _MedicationIndexEntry('Fluticasone', ['Flonase']),
  _MedicationIndexEntry('Loperamide', ['Imodium']),
  _MedicationIndexEntry('Mupirocin', ['Bactroban']),
  _MedicationIndexEntry('Promethazine', ['Phenergan']),
  _MedicationIndexEntry('Ranitidine', ['Zantac']),
  _MedicationIndexEntry('Spironolactone', ['Aldactone']),
  _MedicationIndexEntry('Tretinoin', ['Retin-A']),
];

class MedicationReferencePage extends StatefulWidget {
  const MedicationReferencePage({super.key});

  @override
  State<MedicationReferencePage> createState() => _MedicationReferencePageState();
}

class _MedicationReferencePageState extends State<MedicationReferencePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  _DrugResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final term = _controller.text.trim();
    if (term.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final queries = <String>[
        'openfda.generic_name:"$term"',
        'openfda.brand_name:"$term"',
        'active_ingredient:"$term"',
      ];

      _DrugResult? selected;
      for (final search in queries) {
        final uri = Uri.https('api.fda.gov', '/drug/label.json', {
          'search': search,
          'limit': '1',
        });
        final response = await http.get(uri).timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) continue;

        final decoded = jsonDecode(response.body);
        final results = decoded['results'];
        if (results is! List || results.isEmpty) continue;

        final parsed = results
            .whereType<Map>()
            .map((item) => _DrugResult.fromJson(Map<String, dynamic>.from(item)))
            .where((drug) => drug.genericName.isNotEmpty || drug.brandName.isNotEmpty)
            .toList();
        if (parsed.isEmpty) continue;

        // The UI intentionally presents one medication reference. Prefer an
        // exact generic-name match, then an exact brand-name match.
        final normalized = term.toLowerCase().trim();
        for (final drug in parsed) {
          if (drug.genericName.toLowerCase() == normalized) {
            selected = drug;
            break;
          }
        }
        if (selected == null) {
          for (final drug in parsed) {
            if (drug.brandName.toLowerCase() == normalized) {
              selected = drug;
              break;
            }
          }
        }
        selected ??= parsed.first;
        break;
      }

      if (!mounted) return;
      setState(() {
        _result = selected;
        _loading = false;
        if (selected == null) {
          _error = 'No FDA label result found. Try the generic or brand name.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to reach the medication database. Check your internet connection and try again.';
      });
    }
  }

  List<String> _medicationSuggestions(String query) {
    final q = _normalizeMedicationText(query);
    final scored = <MapEntry<String, int>>[];

    for (final entry in _medicationIndex) {
      var best = _medicationMatchScore(q, _normalizeMedicationText(entry.generic));
      for (final brand in entry.brands) {
        final score = _medicationMatchScore(q, _normalizeMedicationText(brand));
        if (score > best) best = score;
      }
      if (best > 0) scored.add(MapEntry(entry.generic, best));
    }

    scored.sort((a, b) {
      final score = b.value.compareTo(a.value);
      return score != 0 ? score : a.key.compareTo(b.key);
    });
    return scored.take(8).map((item) => item.key).toList();
  }

  String _normalizeMedicationText(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  int _medicationMatchScore(String query, String candidate) {
    if (candidate == query) return 1000;
    if (candidate.startsWith(query)) return 900 - (candidate.length - query.length).clamp(0, 100);
    if (candidate.contains(query)) return 750 - (candidate.length - query.length).clamp(0, 100);
    if (query.length < 3) return 0;

    final distance = _levenshteinDistance(query, candidate);
    final allowed = query.length <= 4 ? 1 : (query.length <= 7 ? 2 : 3);
    if (distance <= allowed) return 650 - distance * 50;

    // Also compare against short candidate windows so common misspellings
    // can match the intended medication without requiring a full-name typo.
    if (candidate.length > query.length) {
      for (var i = 0; i <= candidate.length - query.length; i++) {
        final window = candidate.substring(i, i + query.length);
        final windowDistance = _levenshteinDistance(query, window);
        if (windowDistance <= allowed) return 600 - windowDistance * 50;
      }
    }
    return 0;
  }

  int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = [
          current[j - 1] + 1,
          previous[j] + 1,
          previous[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      previous = current;
    }
    return previous[b.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          const Text(
            'Medication Reference',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Search for an unfamiliar medication by generic or brand name.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          RawAutocomplete<String>(
            textEditingController: _controller,
            focusNode: _searchFocusNode,
            optionsBuilder: (value) {
              final query = value.text.trim();
              if (query.length < 2) return const Iterable<String>.empty();
              return _medicationSuggestions(query);
            },
            onSelected: (selection) {
              _controller.text = selection;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
              _search();
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onFieldSubmitted(),
                decoration: InputDecoration(
                  labelText: 'Medication name',
                  hintText: 'Start typing a generic or brand name',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: _search,
                  ),
                  border: const OutlineInputBorder(),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              final theme = Theme.of(context);
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10),
                  color: theme.cardColor,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280, minWidth: 320),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final entry = _medicationIndex.firstWhere(
                          (item) => item.generic == option,
                          orElse: () => _MedicationIndexEntry(option, const []),
                        );
                        return ListTile(
                          dense: true,
                          leading: BaxterIconBadge(icon: Icons.medication_outlined, color: theme.colorScheme.primary, size: 50, iconSize: 24),
                          title: Text(
                            entry.generic,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: entry.brands.isEmpty
                              ? null
                              : Text('Brand: ${entry.brands.join(', ')}'),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'For unfamiliar patient medications, confirm the exact drug, formulation, strength, and patient-reported use. This reference is educational and does not replace the medication label, pharmacy information, poison center guidance, or medical direction.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_error != null && !_loading) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ],
          if (result != null && !_loading) ...[
            const SizedBox(height: 16),
            _DrugResultCard(drug: result),
          ],
          const SizedBox(height: 18),
          const Text(
            'Source: U.S. FDA drug labeling via openFDA. Label content can change over time. Always verify the medication container, strength, formulation, and current clinical guidance.',
            style: TextStyle(fontSize: 12.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _DrugResult {
  final String genericName;
  final String brandName;
  final String route;
  final String dosageForm;
  final String indications;
  final String warnings;
  final String adverseReactions;
  final String contraindications;
  final String dosage;
  final String interactions;
  final String pregnancy;

  const _DrugResult({
    required this.genericName,
    required this.brandName,
    required this.route,
    required this.dosageForm,
    required this.indications,
    required this.warnings,
    required this.adverseReactions,
    required this.contraindications,
    required this.dosage,
    required this.interactions,
    required this.pregnancy,
  });

  static String _first(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first.toString().trim();
    if (value is String) return value.trim();
    return '';
  }

  factory _DrugResult.fromJson(Map<String, dynamic> json) {
    final openfda = json['openfda'] is Map
        ? Map<String, dynamic>.from(json['openfda'])
        : <String, dynamic>{};
    return _DrugResult(
      genericName: _first(openfda['generic_name']),
      brandName: _first(openfda['brand_name']),
      route: _first(openfda['route']),
      dosageForm: _first(openfda['dosage_form']),
      indications: _first(json['indications_and_usage']),
      warnings: _first(json['warnings_and_cautions']),
      adverseReactions: _first(json['adverse_reactions']),
      contraindications: _first(json['contraindications']),
      dosage: _first(json['dosage_and_administration']),
      interactions: _first(json['drug_interactions']),
      pregnancy: _first(json['pregnancy']),
    );
  }
}

String _quickMedicationDescription(_DrugResult drug) {
  final name = drug.genericName.isNotEmpty ? drug.genericName : drug.brandName;
  final normalized = name.toLowerCase().trim();

  const descriptions = <String, String>{
    'apixaban': 'An oral anticoagulant (blood thinner) that helps prevent and treat blood clots and reduce the risk of stroke.',
    'warfarin': 'An anticoagulant (blood thinner) that reduces the blood\'s ability to form clots.',
    'rivaroxaban': 'An oral anticoagulant (blood thinner) used to prevent and treat blood clots and reduce stroke risk.',
    'dabigatran': 'An oral anticoagulant (blood thinner) that helps prevent and treat blood clots and reduce stroke risk.',
    'clopidogrel': 'An antiplatelet medication that makes platelets less likely to stick together and form blood clots.',
    'aspirin': 'An antiplatelet medication that reduces platelet clotting; it is also used for pain, fever, and inflammation.',
    'metoprolol': 'A beta-blocker that slows the heart rate and lowers blood pressure, reducing the heart\'s workload.',
    'lisinopril': 'An ACE inhibitor that lowers blood pressure and reduces the workload on the heart.',
    'amlodipine': 'A calcium-channel blocker that relaxes blood vessels and lowers blood pressure.',
    'losartan': 'An angiotensin II receptor blocker (ARB) that relaxes blood vessels and lowers blood pressure.',
    'furosemide': 'A loop diuretic (water pill) that helps the body remove excess salt and fluid.',
    'spironolactone': 'A potassium-sparing diuretic that removes excess fluid while helping retain potassium.',
    'atorvastatin': 'A statin that lowers LDL cholesterol and helps reduce the risk of heart attack and stroke.',
    'rosuvastatin': 'A statin that lowers LDL cholesterol and helps reduce cardiovascular risk.',
    'levothyroxine': 'A thyroid hormone replacement medication used to treat an underactive thyroid.',
    'insulin': 'A hormone medication that lowers blood glucose by helping glucose move from the blood into cells.',
    'metformin': 'A diabetes medication that lowers blood glucose, primarily by reducing glucose production by the liver and improving insulin sensitivity.',
    'glipizide': 'A sulfonylurea diabetes medication that lowers blood glucose by increasing insulin release from the pancreas.',
    'gabapentin': 'A medication used for certain nerve pain conditions and as an anticonvulsant.',
    'pregabalin': 'A medication used for certain nerve pain conditions and as an anticonvulsant.',
    'sertraline': 'An SSRI antidepressant used to treat depression and several anxiety-related disorders.',
    'fluoxetine': 'An SSRI antidepressant used to treat depression and several other mood and anxiety-related conditions.',
    'escitalopram': 'An SSRI antidepressant used primarily to treat depression and generalized anxiety disorder.',
    'alprazolam': 'A benzodiazepine that reduces anxiety and produces a calming effect.',
    'lorazepam': 'A benzodiazepine that produces a calming effect and is used for anxiety, seizures, and other indications.',
    'diazepam': 'A benzodiazepine with calming, muscle-relaxing, and anticonvulsant effects.',
    'hydrochlorothiazide': 'A thiazide diuretic that helps remove excess salt and water and lowers blood pressure.',
    'pantoprazole': 'A proton-pump inhibitor (PPI) that reduces stomach acid production.',
    'omeprazole': 'A proton-pump inhibitor (PPI) that reduces stomach acid production.',
    'famotidine': 'An H2 blocker that reduces stomach acid production and is used for acid-related conditions.',
    'ondansetron': 'An antiemetic that helps prevent and treat nausea and vomiting.',
    'albuterol': 'A short-acting bronchodilator that relaxes airway muscles and improves airflow during bronchospasm.',
    'montelukast': 'A leukotriene receptor antagonist used to help control asthma and allergy symptoms.',
    'prednisone': 'A corticosteroid that reduces inflammation and suppresses the immune response.',
    'methylprednisolone': 'A corticosteroid that reduces inflammation and suppresses the immune response.',
    'amoxicillin': 'A penicillin-type antibiotic used to treat a variety of bacterial infections.',
    'azithromycin': 'A macrolide antibiotic used to treat certain bacterial infections.',
    'cephalexin': 'A cephalosporin antibiotic used to treat certain bacterial infections.',
    'doxycycline': 'A tetracycline antibiotic used to treat a variety of bacterial infections and other conditions.',
    'ciprofloxacin': 'A fluoroquinolone antibiotic used to treat certain bacterial infections.',
    'tramadol': 'An opioid pain medication used to treat moderate to moderately severe pain.',
    'hydrocodone': 'An opioid pain medication used to treat moderate to severe pain; some products are combined with acetaminophen.',
    'oxycodone': 'An opioid pain medication used to treat moderate to severe pain.',
    'morphine': 'An opioid analgesic used to relieve moderate to severe pain.',
    'fentanyl': 'A potent opioid analgesic used to treat severe pain and for anesthesia and sedation in appropriate settings.',
    'ketamine': 'A dissociative anesthetic used for anesthesia, sedation, and pain management in appropriate clinical settings.',
    'epinephrine': 'A sympathomimetic medication that increases heart rate and vascular tone and relaxes bronchial smooth muscle.',
    'naloxone': 'An opioid antagonist that rapidly reverses opioid effects, including respiratory depression.',
    'nitroglycerin': 'A nitrate that relaxes vascular smooth muscle and reduces cardiac workload, commonly used for angina.',
    'digoxin': 'A cardiac glycoside that increases cardiac contractility and slows conduction through the AV node.',
    'amiodarone': 'An antiarrhythmic medication used to treat certain abnormal heart rhythms.',
    'adenosine': 'A short-acting antiarrhythmic medication that temporarily slows AV-node conduction and can terminate certain SVTs.',
    'diltiazem': 'A calcium-channel blocker that slows AV-node conduction and lowers heart rate and blood pressure.',
    'verapamil': 'A calcium-channel blocker that slows AV-node conduction and lowers heart rate and blood pressure.',
  };

  final known = descriptions[normalized];
  if (known != null) return known;

  final indication = drug.indications.trim();
  if (indication.isEmpty) {
    return 'A medication with uses and precautions that should be verified against the current drug label.';
  }

  var text = indication.replaceAll(RegExp(r'<[^>]*>'), ' ');
  text = text.replaceAll(RegExp(r'\\s+'), ' ').trim();
  // Keep the quick-reference summary short. Prefer the first sentence, then
  // cap the fallback so the detailed sections remain the place for full label text.
  final sentenceEnd = text.indexOf(RegExp(r'[.!?]'));
  if (sentenceEnd > 0) text = text.substring(0, sentenceEnd + 1);
  if (text.length > 320) text = '${text.substring(0, 317).trimRight()}…';
  return 'Used to treat or manage: $text';
}

class _DrugResultCard extends StatelessWidget {
  final _DrugResult drug;
  const _DrugResultCard({required this.drug});

  Widget _section(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(_clean(value), style: const TextStyle(height: 1.35)),
        ),
      ],
    );
  }

  String _clean(String value) {
    var text = value.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length > 1800) text = '${text.substring(0, 1800)}…';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final title = drug.genericName.isNotEmpty ? drug.genericName : drug.brandName;
    final subtitleParts = <String>[];
    if (drug.brandName.isNotEmpty && drug.brandName.toLowerCase() != title.toLowerCase()) {
      subtitleParts.add('Brand: ${drug.brandName}');
    }
    if (drug.dosageForm.isNotEmpty) subtitleParts.add(drug.dosageForm);
    if (drug.route.isNotEmpty) subtitleParts.add(drug.route);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (subtitleParts.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                subtitleParts.join(' • '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What is it?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _quickMedicationDescription(drug),
                    style: const TextStyle(fontSize: 15.5, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _section('Indications & usage', drug.indications),
            _section('Warnings & precautions', drug.warnings),
            _section('Contraindications', drug.contraindications),
            _section('Adverse reactions', drug.adverseReactions),
            _section('Dosage & administration', drug.dosage),
            _section('Drug interactions', drug.interactions),
            _section('Pregnancy / lactation', drug.pregnancy),
          ],
        ),
      ),
    );
  }
}

class LabReferencePage extends StatefulWidget {
  const LabReferencePage({super.key});

  @override
  State<LabReferencePage> createState() => _LabReferencePageState();
}

class _LabReferencePageState extends State<LabReferencePage> {
  String _category = 'All';
  final TextEditingController _searchController = TextEditingController();

  static const List<_LabRange> _ranges = [
    _LabRange('WBC', 'CBC', '4.0–11.0', '×10³/µL', 'Adults'),
    _LabRange('RBC — male', 'CBC', '4.5–5.9', '×10⁶/µL', 'Adults'),
    _LabRange('RBC — female', 'CBC', '4.1–5.1', '×10⁶/µL', 'Adults'),
    _LabRange('Hemoglobin — male', 'CBC', '13.5–17.5', 'g/dL', 'Adults'),
    _LabRange('Hemoglobin — female', 'CBC', '12.0–16.0', 'g/dL', 'Adults'),
    _LabRange('Hematocrit — male', 'CBC', '41–53', '%', 'Adults'),
    _LabRange('Hematocrit — female', 'CBC', '36–46', '%', 'Adults'),
    _LabRange('MCV', 'CBC', '80–100', 'fL', 'Adults'),
    _LabRange('Platelets', 'CBC', '150–400', '×10³/µL', 'Adults'),
    _LabRange('Sodium', 'BMP/CMP', '135–145', 'mEq/L', 'Adults'),
    _LabRange('Potassium', 'BMP/CMP', '3.5–5.0', 'mEq/L', 'Adults'),
    _LabRange('Chloride', 'BMP/CMP', '98–106', 'mEq/L', 'Adults'),
    _LabRange('CO₂ / bicarbonate', 'BMP/CMP', '22–29', 'mEq/L', 'Adults'),
    _LabRange('BUN', 'BMP/CMP', '7–20', 'mg/dL', 'Adults'),
    _LabRange('Creatinine', 'BMP/CMP', '0.6–1.3', 'mg/dL', 'Adults'),
    _LabRange('Glucose — fasting', 'BMP/CMP', '70–99', 'mg/dL', 'Adults'),
    _LabRange('Calcium', 'BMP/CMP', '8.5–10.5', 'mg/dL', 'Adults'),
    _LabRange('Magnesium', 'BMP/CMP', '1.7–2.2', 'mg/dL', 'Adults'),
    _LabRange('Phosphorus', 'BMP/CMP', '2.5–4.5', 'mg/dL', 'Adults'),
    _LabRange('AST', 'Liver', '10–40', 'U/L', 'Adults'),
    _LabRange('ALT', 'Liver', '7–56', 'U/L', 'Adults'),
    _LabRange('Alkaline phosphatase', 'Liver', '44–147', 'U/L', 'Adults'),
    _LabRange('Total bilirubin', 'Liver', '0.1–1.2', 'mg/dL', 'Adults'),
    _LabRange('Albumin', 'Liver', '3.5–5.0', 'g/dL', 'Adults'),
    _LabRange('PT', 'Coagulation', '11–13.5', 'sec', 'Adults'),
    _LabRange('INR', 'Coagulation', '0.8–1.1', '', 'Adults, not anticoagulated'),
    _LabRange('aPTT', 'Coagulation', '25–35', 'sec', 'Adults'),
    _LabRange('pH', 'ABG', '7.35–7.45', '', 'Arterial blood gas'),
    _LabRange('PaCO₂', 'ABG', '35–45', 'mmHg', 'Arterial blood gas'),
    _LabRange('PaO₂', 'ABG', '80–100', 'mmHg', 'Arterial blood gas, room air'),
    _LabRange('HCO₃⁻', 'ABG', '22–26', 'mEq/L', 'Arterial blood gas'),
    _LabRange('Lactate', 'Critical care', '0.5–2.2', 'mmol/L', 'Adults'),
    _LabRange('Troponin', 'Cardiac', 'Assay-specific', '', 'Use the reporting lab’s reference interval'),
    _LabRange('BNP', 'Cardiac', '<100', 'pg/mL', 'Adults; assay dependent'),
    _LabRange('NT-proBNP', 'Cardiac', 'Age-dependent', 'pg/mL', 'Use assay-specific reference interval'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final categories = <String>{'All', ..._ranges.map((r) => r.category)}.toList();
    final filtered = _ranges.where((r) {
      final categoryMatch = _category == 'All' || r.category == _category;
      final searchMatch = query.isEmpty ||
          r.name.toLowerCase().contains(query) ||
          r.category.toLowerCase().contains(query);
      return categoryMatch && searchMatch;
    }).toList();

    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          const Text(
            'Lab / Medical Reference',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Common adult laboratory reference ranges for quick field reference.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search labs',
              hintText: 'e.g. potassium, INR, hemoglobin',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _category = value);
            },
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Reference ranges vary by laboratory, assay, patient age, sex, pregnancy status, and clinical context. When available, use the reference interval printed on the patient’s actual lab report.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...filtered.map((range) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(range.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${range.category} • ${range.population}'),
                  trailing: SizedBox(
                    width: 155,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          range.range,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (range.unit.isNotEmpty)
                          Text(range.unit, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('No matching laboratory reference found.')),
            ),
          const SizedBox(height: 12),
          const Text(
            'Reference basis: common adult intervals summarized from standard clinical references. Merck Manual notes that reference intervals vary with population and laboratory method; MedlinePlus recommends using the reference range reported by the testing laboratory when interpreting a result.',
            style: TextStyle(fontSize: 12.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _LabRange {
  final String name;
  final String category;
  final String range;
  final String unit;
  final String population;

  const _LabRange(this.name, this.category, this.range, this.unit, this.population);
}
