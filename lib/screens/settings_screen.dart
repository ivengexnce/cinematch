import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController _urlCtrl;
  bool _forceOffline = false;
  Map<String, dynamic>? _health;
  bool _isPinging = false;
  String? _pingError;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: _apiService.baseUrl);
    _forceOffline = _apiService.forceOffline;
    _runPing();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _runPing() async {
    setState(() { _isPinging = true; _pingError = null; });
    try {
      final res = await _apiService.checkHealth();
      if (mounted) setState(() { _health = res; _isPinging = false; });
    } catch (e) {
      if (mounted) setState(() { _pingError = e.toString(); _isPinging = false; });
    }
  }

  Future<void> _resetCatalog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: const RoundedRectangleBorder(side: BorderSide(color: AppTheme.borderLight)),
        title: Text('RESET DATABASE?', style: AppTheme.monoTag.copyWith(color: AppTheme.accentVermilion)),
        content: const Text('Reset the movie list back to the original 1,000 Kaggle IMDB movies? Custom added movies will be cleared.', style: AppTheme.bodyRegular),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentVermilion), onPressed: () => Navigator.pop(ctx, true), child: const Text('RESET')),
        ],
      ),
    );

    if (ok == true) {
      await _apiService.resetCatalog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Database reset to original 1,000 movies.', style: AppTheme.monoTag)));
        _runPing();
      }
    }
  }

  Widget _section(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.monoTag),
        const SizedBox(height: 4),
        const Divider(color: AppTheme.borderLight, height: 1),
      ],
    );
  }

  Widget _presetBtn(String label, String url) {
    return InkWell(
      onTap: () {
        setState(() { _urlCtrl.text = url; _apiService.baseUrl = url; });
        _runPing();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.borderLight)),
        child: Text(label, style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10, color: AppTheme.textPrimary)),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 11))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS & SERVER STATUS', style: AppTheme.monoTag)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _section('1. BACKEND SERVER CONNECTION'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SERVER URL', style: TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 0.6)),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlCtrl,
                  style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check, color: AppTheme.accentVermilion, size: 18),
                      tooltip: 'Save URL',
                      onPressed: () {
                        _apiService.baseUrl = _urlCtrl.text;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Saved: ${_apiService.baseUrl}', style: AppTheme.monoTag)));
                        _runPing();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetBtn('LOCALHOST (127.0.0.1:8000)', 'http://127.0.0.1:8000'),
                    _presetBtn('ANDROID (10.0.2.2:8000)', 'http://10.0.2.2:8000'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: _isPinging ? null : _runPing,
                    child: _isPinging
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.textPrimary))
                        : const Text('TEST CONNECTION (GET /api/health)', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11)),
                  ),
                ),
                if (_health != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.background, border: Border.all(color: AppTheme.accentVermilion)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _health!['is_remote'] == true ? '● STATUS: SERVER ONLINE' : '○ STATUS: OFFLINE LOCAL ENGINE',
                          style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text('SERVICE: ${_health!['service'] ?? "N/A"}  •  TOTAL MOVIES: ${_health!['total_movies'] ?? "N/A"}', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
                if (_pingError != null) ...[
                  const SizedBox(height: 10),
                  Text('ERROR: $_pingError', style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.accentVermilion, fontSize: 11)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          _section('2. OFFLINE & DATABASE OPTIONS'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              children: [
                SwitchListTile(
                  activeTrackColor: AppTheme.accentVermilion,
                  inactiveTrackColor: AppTheme.background,
                  title: const Text('OFFLINE MODE', style: TextStyle(fontFamily: AppTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textPrimary)),
                  subtitle: const Text('Calculate recommendations in-app without server calls.', style: TextStyle(fontFamily: AppTheme.fontText, color: AppTheme.textSecondary, fontSize: 12)),
                  value: _forceOffline,
                  onChanged: (v) {
                    setState(() => _forceOffline = v);
                    _apiService.forceOffline = v;
                    _runPing();
                  },
                ),
                const Divider(color: AppTheme.borderLight, height: 1),
                ListTile(
                  title: const Text('RESET DATABASE', style: TextStyle(fontFamily: AppTheme.fontMono, fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.accentVermilion)),
                  subtitle: const Text('Restores original 1,000 Kaggle IMDB movies.', style: TextStyle(fontFamily: AppTheme.fontText, color: AppTheme.textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.refresh, color: AppTheme.accentVermilion, size: 18),
                  onTap: _resetCatalog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _section('3. ABOUT CINEMATCH (PRACTICAL 12)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('DATASET', 'Kaggle IMDB 1,000 Movies'),
                _infoRow('FRONTEND', 'Flutter 3 (Models, Services, Screens, Widgets)'),
                _infoRow('BACKEND', 'Python FastAPI Backend (:8000)'),
                _infoRow('STORAGE', 'Firebase Cloud Storage (Posters)'),
                _infoRow('SCORING', 'Mood, genre, and rating match formula'),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
