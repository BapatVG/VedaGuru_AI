import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/sacred_result_view.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedCategory = 'Bhagavad Gita';
  String _selectedBook = 'Bhagavad Gita';
  final _customBookController = TextEditingController();

  final _questionController = TextEditingController();

  bool _isExploring = false;
  String? _bookContent;
  String? _exploreError;

  bool _isAsking = false;
  String? _answerContent;
  String? _askError;

  final Map<String, List<String>> _categoryBooks = {
    'Bhagavad Gita': ['Bhagavad Gita'],
    'Upanishads': [
      'Isha Upanishad',
      'Kena Upanishad',
      'Katha Upanishad',
      'Mundaka Upanishad',
      'Mandukya Upanishad',
      'Chandogya Upanishad',
    ],
    'Vedas': ['Rigveda', 'Samaveda', 'Yajurveda', 'Atharvaveda'],
    'Puranas': [
      'Bhagavata Purana',
      'Shiva Purana',
      'Vishnu Purana',
      'Garuda Purana',
      'Skanda Purana',
      'Matsya Purana',
      'Kurma Purana',
    ],
    'Mahakavya (Epics)': ['Ramayana', 'Mahabharata'],
    'Other': ['Custom Text'],
  };

  @override
  void dispose() {
    _customBookController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  String get _actualBookName {
    if (_selectedBook == 'Custom Text') {
      return _customBookController.text.trim().isEmpty ? 'Sacred Granth' : _customBookController.text.trim();
    }
    return _selectedBook;
  }

  Future<void> _exploreBook() async {
    setState(() {
      _isExploring = true;
      _exploreError = null;
      _answerContent = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.exploreScripture(
      category: _selectedCategory,
      bookName: _actualBookName,
      language: lang,
      username: username,
    );

    setState(() {
      _isExploring = false;
      if (res['success'] == true) {
        _bookContent = res['content'];
      } else {
        _exploreError = res['error'] ?? 'Failed to explore scripture';
      }
    });
  }

  Future<void> _askQuestion() async {
    final query = _questionController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isAsking = true;
      _askError = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = auth.currentUser?.username;
    final lang = auth.currentUser?.preferredLanguage ?? 'English';

    final res = await ApiService.askScripture(
      bookName: _actualBookName,
      question: query,
      language: lang,
      username: username,
    );

    setState(() {
      _isAsking = false;
      if (res['success'] == true) {
        _answerContent = res['answer'];
      } else {
        _askError = res['error'] ?? 'Failed to get answer';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final books = _categoryBooks[_selectedCategory] ?? ['Custom Text'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vedic Scripture Library',
          style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📚', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text('Select Sacred Scripture', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categoryBooks.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                            _selectedBook = _categoryBooks[val]!.first;
                            _bookContent = null;
                            _answerContent = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.primarySaffron),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Text / Granth', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: books.contains(_selectedBook) ? _selectedBook : books.first,
                      items: books.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBook = val;
                            _bookContent = null;
                            _answerContent = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.menu_book_rounded, color: AppTheme.sacredGold),
                      ),
                    ),
                    if (_selectedBook == 'Custom Text') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customBookController,
                        decoration: InputDecoration(
                          hintText: 'Enter custom scripture or granth name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExploring ? null : _exploreBook,
                        icon: const Icon(Icons.explore_rounded),
                        label: Text(_isExploring ? 'Consulting Granth...' : 'Explore Scripture'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isExploring)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppTheme.primarySaffron),
                    const SizedBox(height: 16),
                    Text(
                      'Opening sacred pages of $_actualBookName...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(fontSize: 14, color: AppTheme.primaryDark),
                    ),
                  ],
                ),
              ),

            if (_exploreError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_exploreError!, style: const TextStyle(color: Colors.red)),
              ),

            // Book Content
            if (_bookContent != null) ...[
              SacredResultView(
                title: 'Granth Overview & Chapter Summary',
                subtitle: '$_actualBookName • Sacred Vedic Knowledge',
                content: _bookContent!,
                iconEmoji: '📜',
              ),
              const SizedBox(height: 20),

              // "Ask Granth" Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ask a Question to $_actualBookName',
                              style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _questionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g., What does this scripture say about Karma and Nishkama action?',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _isAsking ? null : _askQuestion,
                          icon: const Icon(Icons.psychology_rounded, size: 18),
                          label: Text(_isAsking ? 'Searching...' : 'Ask Granth'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryDark,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (_askError != null) ...[
                        const SizedBox(height: 10),
                        Text(_askError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      if (_answerContent != null) ...[
                        const Divider(height: 28),
                        Text('Answer & Scriptural Citation:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark)),
                        const SizedBox(height: 8),
                        SelectableText(
                          _answerContent!,
                          style: GoogleFonts.poppins(fontSize: 13.5, height: 1.5, color: AppTheme.textDark),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}
