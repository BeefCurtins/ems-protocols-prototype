import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    };

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 76,
        title: Image.asset(
          'assets/baxter_wordmark.png',
          height: 54,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProtocolsPage(
                      protocols: allProtocols
                          .where((p) => p.category == category)
                          .toList(),
                      title: category,
                    ),
                  ),
                ),
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
      appBar: AppBar(title: Text(widget.title)),
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
      appBar: AppBar(title: const Text('Favorites')),
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
      appBar: AppBar(
        title: Text(widget.protocol.title),
        actions: [
          IconButton(
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
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
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
                ],
              ),
            ),
          ],
        ),
      );
}
