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
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _themeMode = prefs.getBool('dark_mode') == true
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
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 10),
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
        scaffoldBackgroundColor: const Color(0xFF111315),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111315),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1B1E21),
          elevation: 0,
          margin: EdgeInsets.only(bottom: 10),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF17191C),
          indicatorColor: Color(0x38025EFF),
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
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      toolbarHeight: 92,
      title: Image.asset(
        'assets/baxter_wordmark.png',
        height: 72,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
      actions: actions,
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
      SettingsPage(
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
      const WhatsNewPage(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.new_releases_outlined),
            selectedIcon: Icon(Icons.new_releases),
            label: "What's New",
          ),
        ],
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

  @override
  void dispose() {
    super.dispose();
  }

  List<Protocol> _suggestions(String value) {
    final q = value.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final results = <Protocol>[];
    final seen = <String>{};

    // Prioritize title matches, then category/content matches.
    final titleMatches = allProtocols.where(
      (p) => p.title.toLowerCase().contains(q),
    );
    final otherMatches = allProtocols.where(
      (p) =>
          !p.title.toLowerCase().contains(q) &&
          '${p.category} ${p.content}'.toLowerCase().contains(q),
    );

    for (final p in [...titleMatches, ...otherMatches]) {
      if (seen.add(p.title)) {
        results.add(p);
      }
      if (results.length >= 8) break;
    }

    return results;
  }

  void _search(String value) {
    final q = value.trim().toLowerCase();
    if (q.isEmpty) return;

    final results = allProtocols.where((p) {
      final haystack = '${p.title} ${p.category} ${p.content}'.toLowerCase();
      return haystack.contains(q);
    }).toList();

    _focusNode?.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProtocolsPage(
          protocols: results,
          title: 'Search Results',
        ),
      ),
    );
  }

  void _selectSuggestion(Protocol protocol) {
    _controller?.text = protocol.title;
    _focusNode?.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProtocolDetailPage(protocol: protocol),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Autocomplete<Protocol>(
              optionsBuilder: (textEditingValue) {
                return _suggestions(textEditingValue.text);
              },
              displayStringForOption: (protocol) => protocol.title,
              onSelected: _selectSuggestion,
              fieldViewBuilder: (
                context,
                fieldController,
                fieldFocusNode,
                onFieldSubmitted,
              ) {
                // Keep our controller/focus node synchronized with Flutter's
                // autocomplete field.
                _controller = fieldController;
                _focusNode = fieldFocusNode;

                return TextField(
                  controller: fieldController,
                  focusNode: fieldFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    onFieldSubmitted();
                    if (value.trim().isNotEmpty) {
                      _search(value);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search protocols',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        fieldController.clear();
                        fieldFocusNode.requestFocus();
                        setState(() {});
                      },
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
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
                      constraints: const BoxConstraints(
                        maxWidth: 680,
                        maxHeight: 360,
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        itemBuilder: (context, index) {
                          final protocol = items[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.menu_book_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              protocol.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(protocol.category),
                            onTap: () => onSelected(protocol),
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

  @override
  Widget build(BuildContext context) {
    const categories = [
      'General',
      'Medications',
      'Cardiac',
      'Respiratory',
      'Medical',
      'Trauma',
      'OB/GYN',
      'Pediatric',
      'Tools',
      'Useful Information',
      'Education',
    ];

    const categoryIcons = {
      'General': Icons.menu_book_rounded,
      'Medications': Icons.medication_rounded,
      'Cardiac': Icons.favorite_rounded,
      'Respiratory': Icons.air_rounded,
      'Medical': Icons.medical_services_rounded,
      'Trauma': Icons.healing_rounded,
      'OB/GYN': Icons.pregnant_woman_rounded,
      'Pediatric': Icons.child_care_rounded,
      'Tools': Icons.build_rounded,
      'Useful Information': Icons.info_rounded,
      'Education': Icons.school_rounded,
    };

    const categoryColors = {
      'General': Color(0xFF1976D2),
      'Medications': Color(0xFF7B1FA2),
      'Cardiac': Color(0xFFD32F2F),
      'Respiratory': Color(0xFF00897B),
      'Medical': Color(0xFF388E3C),
      'Trauma': Color(0xFFEF6C00),
      'OB/GYN': Color(0xFFD81B60),
      'Pediatric': Color(0xFF3949AB),
      'Tools': Color(0xFF00838F),
      'Useful Information': Color(0xFF5E35B1),
      'Education': Color(0xFF00695C),
    };

    return Scaffold(
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              children: [
          const Text(
            'Quick Access',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...categories.map(
            (category) => Card(
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                leading: Icon(
                  categoryIcons[category],
                  size: 32,
                  color: categoryColors[category],
                ),
                title: Text(
                  category,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (category == 'Tools') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ToolsPage()),
                    );
                    return;
                  }
                  if (category == 'Useful Information') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UsefulInformationPage(),
                      ),
                    );
                    return;
                  }
                  if (category == 'Education') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EducationPage()),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProtocolsPage(
                        protocols: allProtocols
                            .where((p) => p.category == category)
                            .toList(),
                        title: category,
                      ),
                    ),
                  );
                },
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
                    leading: Icon(
                      Icons.monitor_weight_rounded,
                      color: primary,
                      size: 32,
                    ),
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
                    leading: Icon(
                      Icons.hearing_disabled_rounded,
                      color: const Color(0xFF00897B),
                      size: 32,
                    ),
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
                    leading: Icon(
                      Icons.translate_rounded,
                      color: const Color(0xFF00897B),
                      size: 32,
                    ),
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
                    leading: Icon(
                      Icons.water_drop_rounded,
                      color: const Color(0xFF1565C0),
                      size: 32,
                    ),
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
                    leading: Icon(
                      Icons.psychology_rounded,
                      color: primary,
                      size: 32,
                    ),
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
                    leading: Icon(
                      Icons.local_fire_department_rounded,
                      color: const Color(0xFFEF6C00),
                      size: 32,
                    ),
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
                    leading: Icon(
                      Icons.favorite_border_rounded,
                      color: const Color(0xFFC62828),
                      size: 32,
                    ),
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
                    leading: Icon(
                      Icons.air_rounded,
                      color: const Color(0xFF00897B),
                      size: 32,
                    ),
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

  double get _total => _selected.entries.fold(0, (sum, entry) => sum + (entry.value ? _percent[entry.key]! : 0));

  void _clear() {
    setState(() {
      for (final key in _selected.keys) {
        _selected[key] = false;
      }
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
                    leading: Icon(
                      Icons.local_shipping_rounded,
                      color: primary,
                      size: 32,
                    ),
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
            leading: Icon(Icons.scoreboard_rounded, color: primary, size: 30),
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
    return Scaffold(
      floatingActionButton: const PersistentHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(child: _buildStudyView(context)),
        ],
      ),
    );
  }
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

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  static const String _tlcUrl =
      'https://login.healthstream.com/hstmsts/MobileLogin.aspx?ReturnUrl=%2fHSTMSTS%2fusers%2fissue.aspx%3fwa%3dwsignin1.0%26wtrealm%3dhttp%253a%252f%252fwww.healthstream.com%252fhlc%26wctx%3drm%253d0%2526id%3dpassive%26ru%3d%25252fHLC%25252fLogin%25252fLogin.aspx%25253forganizationID%25253de4b9e57c-0d7e-df11-98c2-00151729cb2f%26wct%3d2023-07-06T15%253a10%253a06Z%26wreply%3dhttps%253a%252f%252fwww.healthstream.com%252fHLC%252flogin%252flogin.aspx%26sts_OrgId%3de4b9e57c-0d7e-df11-98c2-00151729cb2f&sts_OrgId=e4b9e57c-0d7e-df11-98c2-00151729cb2f&sts_OrgNodeId=00000000-0000-0000-0000-000000000000&wtrealm=http%3a%2f%2fwww.healthstream.com%2fhlc';

  Future<void> _openTlc() async {
    final uri = Uri.parse(_tlcUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open TLC.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open TLC.')));
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
                    const Text('Education', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Study the current protocol set or access TLC training.',
                  style: TextStyle(fontSize: 15, color: onSurfaceVariant, height: 1.4),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 96),
              children: [
                _educationCard(
                  context,
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFF00695C),
                  title: 'Study the Current Protocol',
                  subtitle: 'Review and quiz yourself on the current protocol set.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProtocolStudyPage()),
                    );
                  },
                ),
                _educationCard(
                  context,
                  icon: Icons.verified_user_rounded,
                  iconColor: const Color(0xFF3949AB),
                  title: 'TLC',
                  subtitle: 'Access TLC training through HealthStream.',
                  onTap: _openTlc,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _educationCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 34),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
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
                      leading: Icon(Icons.info_outline_rounded, color: scheme.primary),
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
                      leading: Icon(Icons.cloud_off_rounded, color: scheme.primary),
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
                    leading: Icon(Icons.verified_rounded, color: scheme.primary, size: 30),
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
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
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
                      leading: Icon(
                        Icons.library_books_rounded,
                        color: Color(0xFF025EFF),
                      ),
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
