import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/firebase_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';

class AddMovieScreen extends StatefulWidget {
  const AddMovieScreen({super.key});

  @override
  State<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController(text: 'Dune: Part Two');
  final _directorCtrl = TextEditingController(text: 'Denis Villeneuve');
  final _actorsCtrl = TextEditingController(text: 'Timothée Chalamet, Zendaya, Rebecca Ferguson');
  final _genreCtrl = TextEditingController(text: 'Action, Adventure, Sci-Fi');
  final _yearCtrl = TextEditingController(text: '2024');
  final _runtimeCtrl = TextEditingController(text: '166');
  final _ratingCtrl = TextEditingController(text: '8.6');
  final _synopsisCtrl = TextEditingController(
    text: 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.',
  );
  final _customUrlCtrl = TextEditingController();

  String _selectedMood = 'Adrenaline';
  final List<Map<String, String>> _moods = const [
    {'id': 'Adrenaline', 'name': 'Action & Energy'},
    {'id': 'Thrilled', 'name': 'Suspense & Thrill'},
    {'id': 'Mind-bent', 'name': 'Mind-Bending'},
    {'id': 'Chilled', 'name': 'Chill & Relaxed'},
    {'id': 'Romantic', 'name': 'Romantic'},
    {'id': 'Inspired', 'name': 'Inspiring'},
  ];

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _cloudPosterUrl;
  bool _isPublishing = false;

  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    for (final c in [_titleCtrl, _genreCtrl, _ratingCtrl, _yearCtrl, _customUrlCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _directorCtrl, _actorsCtrl, _genreCtrl, _yearCtrl, _runtimeCtrl, _ratingCtrl, _synopsisCtrl, _customUrlCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _effectivePosterUrl {
    final custom = _customUrlCtrl.text.trim();
    if (custom.isNotEmpty) return custom;
    return _cloudPosterUrl ?? 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800&q=80';
  }

  Movie get _previewMovie {
    final r = double.tryParse(_ratingCtrl.text.trim()) ?? 8.0;
    return Movie(
      id: 'NEW',
      title: _titleCtrl.text.trim().isEmpty ? 'Movie Title' : _titleCtrl.text.trim(),
      director: _directorCtrl.text.trim().isEmpty ? 'Director' : _directorCtrl.text.trim(),
      actors: _actorsCtrl.text.trim().isEmpty ? 'Cast' : _actorsCtrl.text.trim(),
      genre: _genreCtrl.text.trim().isEmpty ? 'Action' : _genreCtrl.text.trim(),
      mood: _selectedMood,
      year: int.tryParse(_yearCtrl.text.trim()) ?? 2024,
      runtime: int.tryParse(_runtimeCtrl.text.trim()) ?? 120,
      rating: r,
      synopsis: _synopsisCtrl.text.trim(),
      posterUrl: _effectivePosterUrl,
      recommendedScore: 80.0 + (r * 1.8),
    );
  }

  Future<void> _pickImage(ImageSource src) async {
    try {
      final img = await _picker.pickImage(source: src, imageQuality: 85, maxWidth: 1200);
      if (img != null) setState(() { _selectedImage = img; _cloudPosterUrl = null; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.accentVermilion, content: Text('Error: $e')));
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() { _isUploading = true; _uploadProgress = 0.0; });
    try {
      final url = await _storageService.uploadMoviePoster(
        imageFile: _selectedImage!,
        onProgress: (p) => mounted ? setState(() => _uploadProgress = p) : null,
      );
      if (mounted) {
        setState(() { _cloudPosterUrl = url; _isUploading = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Poster uploaded to Firebase Storage!', style: AppTheme.monoTag)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.accentVermilion, content: Text('Upload error: $e')));
      }
    }
  }

  Future<void> _submitMovie() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isPublishing = true);
    try {
      await _apiService.createMovie(_previewMovie);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppTheme.surfaceElevated, content: Text('Movie added successfully!', style: AppTheme.monoTag)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppTheme.accentVermilion, content: Text('Failed: $e')));
      }
    }
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, String? Function(String?)? validator, TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 0.6)),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(fontFamily: keyboardType != null ? AppTheme.fontMono : AppTheme.fontText, fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(hintText: hint),
          validator: validator,
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(title: const Text('ADD NEW MOVIE', style: AppTheme.monoTag)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildForm()),
                    const SizedBox(width: 32),
                    SizedBox(width: 260, child: _buildPreviewBox()),
                  ],
                )
              : Column(
                  children: [
                    _buildPreviewBox(),
                    const SizedBox(height: 24),
                    _buildForm(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPreviewBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        children: [
          const Text('LIVE PREVIEW', style: AppTheme.monoTag),
          const SizedBox(height: 14),
          SizedBox(width: 170, height: 250, child: MovieCard(movie: _previewMovie, showScore: true, onTap: () {})),
          const SizedBox(height: 10),
          const Text('Real-time preview of movie card on home feed.', textAlign: TextAlign.center, style: TextStyle(fontFamily: AppTheme.fontText, color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('1. MOVIE TITLE & CAST'),
        const SizedBox(height: 12),
        _field('MOVIE TITLE *', _titleCtrl, hint: 'e.g. Oppenheimer', validator: (v) => v?.trim().isEmpty == true ? 'Title is required' : null),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _field('DIRECTOR', _directorCtrl, hint: 'e.g. Christopher Nolan')),
            const SizedBox(width: 12),
            Expanded(child: _field('STARRING CAST', _actorsCtrl, hint: 'e.g. Cillian Murphy')),
          ],
        ),

        const SizedBox(height: 22),
        _section('2. GENRE & MOOD'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _field('GENRES (COMMA-SEPARATED) *', _genreCtrl, hint: 'Action, Sci-Fi, Drama', validator: (v) => v?.trim().isEmpty == true ? 'Genre required' : null),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MOOD CATEGORY', style: TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 0.6)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMood,
                    dropdownColor: AppTheme.surface,
                    style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 12),
                    items: _moods.map((m) => DropdownMenuItem(value: m['id'], child: Text(m['name']!))).toList(),
                    onChanged: (v) => v != null ? setState(() => _selectedMood = v) : null,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),
        _section('3. MOVIE DETAILS'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _field('YEAR', _yearCtrl, hint: '2024', keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field('RUNTIME (MINS)', _runtimeCtrl, hint: '120', keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field('RATING (0-10)', _ratingCtrl, hint: '8.5', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          ],
        ),

        const SizedBox(height: 22),
        _section('4. MOVIE POSTER (URL OR CLOUD UPLOAD)'),
        const SizedBox(height: 12),
        _buildPosterBox(),

        const SizedBox(height: 22),
        _section('5. STORYLINE & OVERVIEW *'),
        const SizedBox(height: 12),
        _field('STORYLINE DESCRIPTION', _synopsisCtrl, maxLines: 4, hint: 'Write a brief description...', validator: (v) => (v?.trim().length ?? 0) < 5 ? 'At least 5 characters required' : null),

        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _isPublishing ? null : _submitMovie,
            child: _isPublishing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 10),
                      Text('SAVING MOVIE...', style: AppTheme.monoTag),
                    ],
                  )
                : const Text('SAVE MOVIE TO DATABASE', style: AppTheme.monoTag),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPosterBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        children: [
          TextField(
            controller: _customUrlCtrl,
            style: const TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 12),
            decoration: const InputDecoration(hintText: 'Enter image URL or pick below...'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => _pickImage(ImageSource.gallery), child: const Text('CHOOSE FROM GALLERY', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10)))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => _pickImage(ImageSource.camera), child: const Text('TAKE PHOTO', style: TextStyle(fontFamily: AppTheme.fontMono, fontSize: 10)))),
            ],
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.borderLight)),
                  child: kIsWeb ? Image.network(_selectedImage!.path, fit: BoxFit.cover) : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceElevated, foregroundColor: AppTheme.textPrimary),
                    onPressed: _isUploading ? null : _uploadImage,
                    child: Text(_cloudPosterUrl != null ? 'RE-UPLOAD' : 'UPLOAD TO FIREBASE', style: const TextStyle(fontFamily: AppTheme.fontMono, fontSize: 11)),
                  ),
                ),
              ],
            ),
            if (_isUploading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress, backgroundColor: AppTheme.background, color: AppTheme.accentVermilion, minHeight: 2),
            ],
            if (_cloudPosterUrl != null) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check, size: 14, color: AppTheme.accentVermilion),
                  SizedBox(width: 6),
                  Text('POSTER UPLOADED TO CLOUD', style: TextStyle(fontFamily: AppTheme.fontMono, color: AppTheme.textPrimary, fontSize: 10)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
