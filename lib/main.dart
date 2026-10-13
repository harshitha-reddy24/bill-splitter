import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const BillSplitterApp());

const _blue = Color(0xFF1D4ED8);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _surface = Color(0xFFF5F7FB);
const _rupee = '\u20B9';

class BillSplitterApp extends StatelessWidget {
  const BillSplitterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bill Splitter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: _blue),
          scaffoldBackgroundColor: _surface,
        ),
        home: const SplitterPage(),
      );
}

class SplitterPage extends StatefulWidget {
  const SplitterPage({super.key});

  @override
  State<SplitterPage> createState() => _SplitterPageState();
}

class _SplitterPageState extends State<SplitterPage> {
  final _billCtrl = TextEditingController();
  int _people = 2;
  double _tip = 10;
  bool _roundUp = false;

  @override
  void dispose() {
    _billCtrl.dispose();
    super.dispose();
  }

  double get _bill => double.tryParse(_billCtrl.text) ?? 0;

  // Live result: (tip amount, total, per person)
  (double, double, double) get _result {
    final bill = _bill;
    var tip = bill * _tip / 100;
    var total = bill + tip;
    var per = total / _people;
    if (_roundUp && bill > 0) {
      per = per.ceilToDouble();
      total = per * _people;
      tip = total - bill; // effective tip after rounding
    }
    return (tip, total, per);
  }

  void _reset() => setState(() {
        _billCtrl.clear();
        _people = 2;
        _tip = 10;
        _roundUp = false;
      });

  Future<void> _copy() async {
    final (tip, total, per) = _result;
    await Clipboard.setData(ClipboardData(
        text: 'Bill split between $_people\n'
            'Bill: $_rupee${_bill.toStringAsFixed(2)}\n'
            'Tip (${_tip.round()}%): $_rupee${tip.toStringAsFixed(2)}\n'
            'Total: $_rupee${total.toStringAsFixed(2)}\n'
            'Each pays: $_rupee${per.toStringAsFixed(2)}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Split copied')));
  }

  @override
  Widget build(BuildContext context) {
    final (tip, total, per) = _result;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _hero(context, tip, total, per),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Total bill'),
                TextField(
                  controller: _billCtrl,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}\.?\d{0,2}')),
                  ],
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w700, color: _ink),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '$_rupee ',
                    prefixStyle: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700, color: _muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                _label('Split between'),
                _card(Row(children: [
                  const Icon(Icons.people_alt_outlined, color: _muted),
                  const SizedBox(width: 12),
                  Text('$_people ${_people == 1 ? 'person' : 'people'}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton.filledTonal(
                      onPressed: _people > 1 ? () => setState(() => _people--) : null,
                      icon: const Icon(Icons.remove)),
                  const SizedBox(width: 8),
                  IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: _blue),
                      onPressed: _people < 50 ? () => setState(() => _people++) : null,
                      icon: const Icon(Icons.add)),
                ])),
                const SizedBox(height: 24),
                Row(children: [
                  _label('Tip'),
                  const Spacer(),
                  Text('${_tip.round()}%',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: _blue)),
                ]),
                _card(Column(children: [
                  Wrap(spacing: 8, children: [
                    for (final v in [0, 5, 10, 15, 20])
                      ChoiceChip(
                        label: Text('$v%'),
                        showCheckmark: false,
                        selected: _tip.round() == v,
                        selectedColor: _blue,
                        labelStyle: TextStyle(
                            color: _tip.round() == v ? Colors.white : _ink,
                            fontWeight: FontWeight.w600),
                        onSelected: (_) => setState(() => _tip = v.toDouble()),
                      ),
                  ]),
                  Slider(
                    value: _tip,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (v) => setState(() => _tip = v),
                  ),
                ])),
                const SizedBox(height: 12),
                _card(SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Round up each share',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Whole rupees, no loose change'),
                  value: _roundUp,
                  onChanged: (v) => setState(() => _roundUp = v),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    onPressed: per > 0 ? _copy : null,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy split',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, double tip, double total, double per) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 12, 24, 28),
      decoration: const BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Bill Splitter',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
              tooltip: 'Reset',
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt, color: Colors.white)),
        ]),
        const SizedBox(height: 16),
        const Text('Each person pays',
            style: TextStyle(color: Colors.white70, fontSize: 15)),
        TweenAnimationBuilder<double>(
          tween: Tween(end: per),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$_rupee${v.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()])),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          _stat('Bill', _bill),
          _stat('Tip', tip),
          _stat('Total', total),
        ]),
      ]),
    );
  }

  Widget _stat(String label, double value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 2),
          Text('$_rupee${value.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
      );

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: child,
      );
}
