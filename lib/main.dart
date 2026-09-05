import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
    return const PlaceholderInfoPage(
      title: 'Useful Information',
      icon: Icons.info_rounded,
      message: 'Useful EMS information will be added here.',
    );
  }
}

class EducationPage extends StatefulWidget {
  const EducationPage({super.key});

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
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

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion!;
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
                  'Study the current protocol set with source-based review questions.',
                  style: TextStyle(
                    fontSize: 15,
                    color: onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
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
            ),
          ),
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

class WhatsNewPage extends StatelessWidget {
  const WhatsNewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: const BaxterAppBar(),
      body: Column(
        children: [
          const TopSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  "What's New",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Protocol updates and important changes will appear here.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.library_books_rounded,
                            color: primary,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Protocol Set',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Baxter Regional Medical Center Ambulance Protocols — 2021',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This prototype is currently using the 2021 protocol set. When an approved protocol update is added, the changes can be listed here for quick review.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  height: 1.4,
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
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: Icon(
                      Icons.check_circle_outline_rounded,
                      color: primary,
                      size: 30,
                    ),
                    title: const Text(
                      'No newer protocol updates loaded',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'When a new approved protocol set is added, this section can highlight what changed and where to find it.',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Prototype App Updates',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const _WhatsNewFeature(
                  icon: Icons.search_rounded,
                  title: 'Live Protocol Search',
                  description: 'Search suggestions appear as you type, with direct access to matching protocols.',
                ),
                const _WhatsNewFeature(
                  icon: Icons.star_rounded,
                  title: 'Favorites',
                  description: 'Keep frequently used protocols one tap away.',
                ),
                const _WhatsNewFeature(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  description: 'Switch between light and dark themes from Settings.',
                ),
              ],
            ),
          ),
        ],
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
