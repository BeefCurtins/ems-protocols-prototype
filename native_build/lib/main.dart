import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import 'data/source_pages.dart';

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

class EMSProtocolsApp extends StatelessWidget {
  const EMSProtocolsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMS Protocols',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(),
      ProtocolsPage(protocols: allProtocols),
      FavoritesPage(protocols: allProtocols),
      const SettingsPage(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Protocols'),
          NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    const categories = ['General','Medications','Cardiac','Respiratory','Medical','Trauma','OB/GYN','Pediatric'];
    return Scaffold(
      appBar: AppBar(title: const Text('EMS Protocols')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Search protocols', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onSubmitted: (query) {
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProtocolsPage(
                protocols: allProtocols.where((p) => '${p.title} ${p.category} ${p.content}'.toLowerCase().contains(q)).toList(),
                title: 'Search Results',
              )));
            },
          ),
          const SizedBox(height: 20),
          const Text('Quick Access', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...categories.map((category) => Card(child: ListTile(
            title: Text(category),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProtocolsPage(
              protocols: allProtocols.where((p) => p.category == category).toList(), title: category,
            ))),
          ))),
        ],
      ),
    );
  }
}

class ProtocolsPage extends StatefulWidget {
  final List<Protocol> protocols;
  final String title;
  const ProtocolsPage({super.key, required this.protocols, this.title = 'All Protocols'});
  @override State<ProtocolsPage> createState() => _ProtocolsPageState();
}
class _ProtocolsPageState extends State<ProtocolsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.protocols.length,
        itemBuilder: (context, i) {
          final p = widget.protocols[i];
          final fav = favorites.contains(p.title);
          return Card(child: ListTile(
            title: Text(p.title), subtitle: Text(p.category),
            trailing: IconButton(icon: Icon(fav ? Icons.star : Icons.star_border), onPressed: () {
              setState(() { fav ? favorites.remove(p.title) : favorites.add(p.title); });
            }),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProtocolDetailPage(protocol: p))),
          ));
        },
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  final List<Protocol> protocols;
  const FavoritesPage({super.key, required this.protocols});
  @override State<FavoritesPage> createState() => _FavoritesPageState();
}
class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    final items = widget.protocols.where((p) => favorites.contains(p.title)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: items.isEmpty ? const Center(child: Text('No favorites yet.')) : ListView.builder(
        padding: const EdgeInsets.all(12), itemCount: items.length,
        itemBuilder: (context, i) {
          final p=items[i];
          return Card(child: ListTile(title: Text(p.title), subtitle: Text(p.category),
            trailing: IconButton(icon: const Icon(Icons.star), onPressed: () => setState(() => favorites.remove(p.title))),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProtocolDetailPage(protocol: p))),
          ));
        },
      ),
    );
  }
}

class ProtocolDetailPage extends StatelessWidget {
  final Protocol protocol;
  const ProtocolDetailPage({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    final range = sourcePages[protocolKey(protocol)] ?? const SourcePageRange(1, 1);
    return Scaffold(
      appBar: AppBar(
        title: Text(protocol.title),
        actions: [
          StatefulBuilder(builder: (context, setLocal) {
            final fav = favorites.contains(protocol.title);
            return IconButton(
              icon: Icon(fav ? Icons.star : Icons.star_border),
              onPressed: () {
                setLocal(() {
                  fav ? favorites.remove(protocol.title) : favorites.add(protocol.title);
                });
              },
            );
          }),
        ],
      ),
      body: protocol.title.trim().toLowerCase() == 'fentanyl'
          ? const FentanylProtocolPage()
          : NativeProtocolViewer(range: range),
    );
  }
}

/// Native recreation of source page 35, with the administrative header and
/// INDEX tab removed. The clinical content is transcribed from the supplied
/// source page; the page geometry is deliberately fixed to the source's
/// 612 x 792 point coordinate system after removing the 151-point header.
class FentanylProtocolPage extends StatelessWidget {
  const FentanylProtocolPage({super.key});

  static const double pageWidth = 612.0;
  static const double pageHeight = 405.0;

  TextStyle _text({double size = 12, bool bold = false}) {
    return TextStyle(
      fontFamily: 'Times New Roman',
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: Colors.black,
      height: 1.05,
    );
  }

  TableRow _row(String label, Widget content, {required double height}) {
    return TableRow(
      children: [
        SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 3),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(label, style: _text(size: 12, bold: true)),
            ),
          ),
        ),
        SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(7, 4, 7, 3),
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _body(String text) {
    return Text(text, style: _text(size: 12), softWrap: true);
  }

  Widget _doseBody() {
    return Text.rich(
      TextSpan(
        style: _text(size: 12),
        children: const [
          TextSpan(text: 'Supplied 50mcg/ml for Pain control.\n\n'),
          TextSpan(text: 'Post RSI use 50mcg IV.\n\n'),
          TextSpan(
            text: '(IV/IO/ IM/IN) bolus 50 mcg over 5 min until pain improvement.\n'
                'IntraNasal Administration is the fastest and most effective means\n'
                'to use Fentanyl.\n'
                'Max of 150 mcg. PT sedation contact medical control if no\n'
                'improvement of pain. Post intubation bolus 50mcg over 5 min\n'
                'until desired sedation. Contact med control for further dose.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = math.max(280.0, constraints.maxWidth - 24.0);
        final width = math.min(pageWidth, available);
        final scale = width / pageWidth;
        final height = pageHeight * scale;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(80),
              child: SizedBox(
                width: width,
                height: height,
                child: FittedBox(
                  fit: BoxFit.fill,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: pageWidth,
                    height: pageHeight,
                    child: ColoredBox(
                      color: const Color(0xFFF4F4F4),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 41.62,
                            child: Center(
                              child: Text(
                                'Fentanyl',
                                style: _text(size: 15.96, bold: true),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 492.46,
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(161.81),
                                1: FixedColumnWidth(330.65),
                              },
                              border: TableBorder.all(
                                color: Colors.black,
                                width: 1.0,
                              ),
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.top,
                              children: [
                                _row(
                                  'Effects',
                                  _body('Narcotic Analgesic'),
                                  height: 22.46,
                                ),
                                _row(
                                  'Indications',
                                  _body('Analgesia Sedation During RSI\nPain Management'),
                                  height: 36.37,
                                ),
                                _row(
                                  'Contraindications',
                                  _body(
                                    'MAO Inhibitors Myasthenia Gravis Use with caution in head\n'
                                    'trauma and elderly (May consider half dose)',
                                  ),
                                  height: 39.50,
                                ),
                                _row(
                                  'Side Effects',
                                  _body(
                                    'Sedation, Nausea, Respiratory Depression, Meiosis, Hypotension.\n'
                                    'Rapid administration may result in chest wall rigidity that will\n'
                                    'not respond to neuromuscular blockade',
                                  ),
                                  height: 53.88,
                                ),
                                _row(
                                  'Dose',
                                  _doseBody(),
                                  height: 185.0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NativeProtocolViewer extends StatefulWidget {
  final SourcePageRange range;
  const NativeProtocolViewer({super.key, required this.range});
  @override State<NativeProtocolViewer> createState() => _NativeProtocolViewerState();
}
class _NativeProtocolViewerState extends State<NativeProtocolViewer> {
  late Future<Map<String,dynamic>> _future;
  @override void initState(){ super.initState(); _future = _load(); }
  Future<Map<String,dynamic>> _load() async {
    final raw = await rootBundle.loadString('assets/protocol_pages.json');
    return Map<String,dynamic>.from(jsonDecode(raw));
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String,dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final pages = Map<String,dynamic>.from(snap.data!['pages'] as Map);
        final pageNumbers = [for (int n=widget.range.start;n<=widget.range.end;n++) n];
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: pageNumbers.length,
          itemBuilder: (context,i) {
            final pno=pageNumbers[i];
            final data=Map<String,dynamic>.from(pages['$pno'] as Map);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NativeProtocolPage(data: data, pageNumber: pno),
            );
          },
        );
      },
    );
  }
}

class NativeProtocolPage extends StatelessWidget {
  final Map<String,dynamic> data;
  final int pageNumber;
  const NativeProtocolPage({super.key, required this.data, required this.pageNumber});

  Color _color(Map m) => Color.fromARGB(255, (m['r'] as num).round(), (m['g'] as num).round(), (m['b'] as num).round());

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = math.min(constraints.maxWidth - 24, 900.0);
      final scale = maxWidth / (data['width'] as num).toDouble();
      final h = (data['height'] as num).toDouble() * scale;
      final texts = List<Map<String,dynamic>>.from((data['texts'] as List).map((e)=>Map<String,dynamic>.from(e)));
      final shapes = List<Map<String,dynamic>>.from((data['shapes'] as List).map((e)=>Map<String,dynamic>.from(e)));
      final images = List<Map<String,dynamic>>.from((data['images'] as List).map((e)=>Map<String,dynamic>.from(e)));
      return Center(
        child: Container(
          width: maxWidth, height: h,
          color: Colors.white,
          child: Stack(children: [
            CustomPaint(size: Size(maxWidth,h), painter: _PageShapesPainter(shapes: shapes, scale: scale, colorFor: _color)),
            for (final im in images) Positioned(
              left:(im['x'] as num).toDouble()*scale,
              top:(im['y'] as num).toDouble()*scale,
              width:(im['w'] as num).toDouble()*scale,
              height:(im['h'] as num).toDouble()*scale,
              child: Image.asset(im['asset'] as String, fit: BoxFit.fill),
            ),
            for (final t in texts) Positioned(
              left:(t['x'] as num).toDouble()*scale,
              top:(t['y'] as num).toDouble()*scale,
              width: math.max(2,(t['w'] as num).toDouble()*scale + 2),
              height: math.max(2,(t['h'] as num).toDouble()*scale + 2),
              child: Text(
                t['text'] as String,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'Tinos',
                  fontSize:(t['size'] as num).toDouble()*scale,
                  fontWeight:(t['bold'] as bool)?FontWeight.bold:FontWeight.normal,
                  fontStyle:(t['italic'] as bool)?FontStyle.italic:FontStyle.normal,
                  color:_color(Map<String,dynamic>.from(t['color'] as Map)),
                  height: 1.0,
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class _PageShapesPainter extends CustomPainter {
  final List<Map<String,dynamic>> shapes;
  final double scale;
  final Color Function(Map) colorFor;
  _PageShapesPainter({required this.shapes,required this.scale,required this.colorFor});
  @override void paint(Canvas canvas, Size size) {
    for (final s in shapes) {
      final rect=Rect.fromLTWH((s['x'] as num).toDouble()*scale,(s['y'] as num).toDouble()*scale,(s['w'] as num).toDouble()*scale,(s['h'] as num).toDouble()*scale);
      final fill=s['fill']; final stroke=s['stroke'];
      if(fill!=null){ final p=Paint()..style=PaintingStyle.fill..color=colorFor(Map<String,dynamic>.from(fill)); canvas.drawRect(rect,p); }
      else if(stroke!=null){ final p=Paint()..style=PaintingStyle.stroke..strokeWidth=math.max(0.5,1*scale)..color=colorFor(Map<String,dynamic>.from(stroke)); canvas.drawRect(rect,p); }
    }
  }
  @override bool shouldRepaint(covariant _PageShapesPainter old)=>false;
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(padding: const EdgeInsets.all(16), children: const [
      ListTile(title: Text('Source format'), subtitle: Text('Protocol pages are recreated natively as Flutter text, tables, lines, and embedded source graphics. The PDF is not included in the app.')),
      ListTile(title: Text('Clinical use'), subtitle: Text('This app reproduces the supplied 2021 source material. Verify all protocols against current agency-approved guidance before clinical use.')),
    ]),
  );
}
