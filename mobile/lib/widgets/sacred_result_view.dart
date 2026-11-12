import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_theme.dart';
import '../services/api_service.dart';
import '../utils/url_helper.dart';
import '../utils/voice_helper.dart';

class SacredResultView extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String content;
  final String iconEmoji;
  final String? language;
  final VoidCallback? onShare;

  const SacredResultView({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.iconEmoji = '🕉️',
    this.language,
    this.onShare,
  });

  @override
  State<SacredResultView> createState() => _SacredResultViewState();
}

class _SacredResultViewState extends State<SacredResultView> {
  double _fontScale = 1.0;
  bool _showRawText = false;
  bool _isDownloadingPdf = false;
  bool _isSpeaking = false;

  @override
  void dispose() {
    if (_isSpeaking) {
      VoiceHelper.stopSpeaking();
    }
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Report copied to clipboard!', style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_isDownloadingPdf) return;
    setState(() => _isDownloadingPdf = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('Preparing your VedaGuru PDF report...', style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
        backgroundColor: AppTheme.primaryDark,
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final bytes = await ApiService.downloadPdfReport(
        title: widget.title,
        content: widget.content,
        subtitle: widget.subtitle,
      );

      if (mounted) {
        setState(() => _isDownloadingPdf = false);
        if (bytes != null && bytes.isNotEmpty) {
          final cleanTitle = widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
          final filename = 'VedaGuru_$cleanTitle.pdf';
          downloadFile(bytes, filename);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Downloaded $filename successfully!', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not generate PDF report. Please verify backend server is running.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error generating PDF report. Please check server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primarySaffron.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sacred Header & Action Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: AppTheme.sacredGold.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                Text(widget.iconEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.cinzel(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                // Font Size Adjuster (A- / A+)
                IconButton(
                  icon: const Icon(Icons.text_decrease, size: 18),
                  tooltip: 'Decrease text size',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    if (_fontScale > 0.85) setState(() => _fontScale -= 0.1);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase, size: 18),
                  tooltip: 'Increase text size',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    if (_fontScale < 1.4) setState(() => _fontScale += 0.1);
                  },
                ),
                // Toggle Raw / Formatted
                IconButton(
                  icon: Icon(_showRawText ? Icons.auto_awesome : Icons.code, size: 18),
                  tooltip: _showRawText ? 'Show Formatted View' : 'Show Plain Text',
                  visualDensity: VisualDensity.compact,
                  color: AppTheme.primarySaffron,
                  onPressed: () => setState(() => _showRawText = !_showRawText),
                ),
                // PDF Download Button
                InkWell(
                  onTap: _isDownloadingPdf ? null : _downloadPdf,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isDownloadingPdf
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.red),
                              )
                            : Icon(Icons.picture_as_pdf_rounded, size: 15, color: Colors.red.shade800),
                        const SizedBox(width: 4),
                        Text(
                          'PDF',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Audio Readout Button (Listen / Stop)
                InkWell(
                  onTap: () {
                    if (_isSpeaking) {
                      VoiceHelper.stopSpeaking();
                      setState(() => _isSpeaking = false);
                    } else {
                      setState(() => _isSpeaking = true);
                      VoiceHelper.speakText(
                        text: widget.content,
                        language: widget.language ?? 'English',
                        onStart: () {
                          if (mounted) setState(() => _isSpeaking = true);
                        },
                        onComplete: () {
                          if (mounted) setState(() => _isSpeaking = false);
                        },
                        onError: (err) {
                          if (mounted) {
                            setState(() => _isSpeaking = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Audio: $err'), duration: const Duration(seconds: 2)),
                            );
                          }
                        },
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isSpeaking ? const Color(0xFFFFEBEE) : const Color(0xFFFFF7EB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isSpeaking ? Colors.red : AppTheme.sacredGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                          size: 15,
                          color: _isSpeaking ? Colors.red : AppTheme.primarySaffron,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isSpeaking ? 'Stop' : 'Audio',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isSpeaking ? Colors.red : AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Copy Button
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy Report',
                  visualDensity: VisualDensity.compact,
                  color: AppTheme.primaryDark,
                  onPressed: _copyToClipboard,
                ),
              ],
            ),
          ),

          // 2. Content Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: _showRawText
                ? SelectableText(
                    widget.content,
                    style: GoogleFonts.poppins(
                      fontSize: 13 * _fontScale,
                      height: 1.6,
                      color: AppTheme.textDark,
                    ),
                  )
                : _buildFormattedContent(widget.content),
          ),

          // 3. Footer Divine Blessing Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(top: BorderSide(color: AppTheme.sacredGold.withValues(alpha: 0.2))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, size: 12, color: AppTheme.primarySaffron),
                const SizedBox(width: 6),
                Text(
                  'VedaGuru AI Sanatana Knowledge Engine • Verified Vedic Guidance',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String rawText) {
    final lines = rawText.split('\n');
    final List<Widget> widgets = [];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i].trim();

      // Empty line -> spacing
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        i++;
        continue;
      }

      // 1. Detect Markdown Table
      if (line.startsWith('|') && line.endsWith('|')) {
        final tableLines = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('|') && lines[i].trim().endsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }
        widgets.add(_buildTableWidget(tableLines));
        continue;
      }

      // 2. Headings (#, ##, ###)
      if (line.startsWith('#')) {
        final headingText = line.replaceAll(RegExp(r'^#+\s*'), '').trim();
        final int level = RegExp(r'^#+').firstMatch(line)?.group(0)?.length ?? 1;
        widgets.add(_buildHeadingWidget(headingText, level));
        i++;
        continue;
      }

      // 3. Sanskrit Mantra / Shloka block
      if (line.contains('ॐ') || line.contains('||') || line.toLowerCase().startsWith('mantra:') || line.toLowerCase().startsWith('shloka:')) {
        widgets.add(_buildMantraBlock(line));
        i++;
        continue;
      }

      // 4. Inauspicious / Precaution / Rahu Kaal Alert
      if (_isInauspiciousLine(line)) {
        widgets.add(_buildAlertCard(line, isWarning: true));
        i++;
        continue;
      }

      // 5. Auspicious / Muhurat / Shubh Highlight Alert
      if (_isAuspiciousLine(line)) {
        widgets.add(_buildAlertCard(line, isWarning: false));
        i++;
        continue;
      }

      // 6. Bullet Points (- , * , • )
      if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('• ') || RegExp(r'^\d+\.\s').hasMatch(line)) {
        widgets.add(_buildBulletItem(line));
        i++;
        continue;
      }

      // 7. Key-Value Row (e.g. **Tithi**: Shukla Pratipada)
      if (line.contains(':') && line.contains('**')) {
        widgets.add(_buildKeyValueItem(line));
        i++;
        continue;
      }

      // 8. Standard Paragraph
      widgets.add(_buildParagraph(line));
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  bool _isInauspiciousLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('rahu kaal') ||
        lower.contains('yamaganda') ||
        lower.contains('varjya') ||
        lower.contains('inauspicious') ||
        lower.contains('avoid') ||
        lower.contains('dosha') ||
        lower.contains('precaution') ||
        lower.contains('defect in');
  }

  bool _isAuspiciousLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('abhijit') ||
        lower.contains('amrit kaal') ||
        lower.contains('shubh muhurat') ||
        lower.contains('auspicious timing') ||
        lower.contains('highly recommended') ||
        lower.contains('best window') ||
        lower.contains('favorable time');
  }

  Widget _buildHeadingWidget(String text, int level) {
    String emoji = '✨';
    final lower = text.toLowerCase();
    if (lower.contains('muhurat') || lower.contains('time') || lower.contains('timing')) {
      emoji = '🕰️';
    } else if (lower.contains('vastu') || lower.contains('direction') || lower.contains('home')) {
      emoji = '🧭';
    } else if (lower.contains('remedy') || lower.contains('upay') || lower.contains('solution')) {
      emoji = '🪔';
    } else if (lower.contains('mantra') || lower.contains('japa') || lower.contains('sloka')) {
      emoji = '📿';
    } else if (lower.contains('samagri') || lower.contains('item') || lower.contains('puja')) {
      emoji = '🌺';
    } else if (lower.contains('panchang') || lower.contains('nakshatra') || lower.contains('tithi')) {
      emoji = '🪐';
    } else if (lower.contains('precaution') || lower.contains('avoid') || lower.contains('warning')) {
      emoji = '⚠️';
    }

    final double fontSize = level == 1 ? 16.0 : (level == 2 ? 15.0 : 14.0);

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: fontSize)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.cinzel(
                    fontSize: fontSize * _fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primarySaffron, AppTheme.sacredGold]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String text, {required bool isWarning}) {
    final bgColor = isWarning ? const Color(0xFFFFF4F2) : const Color(0xFFF0FDF4);
    final borderColor = isWarning ? Colors.red.shade300 : Colors.green.shade300;
    final iconColor = isWarning ? Colors.red.shade700 : Colors.green.shade700;
    final iconData = isWarning ? Icons.warning_amber_rounded : Icons.auto_awesome;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: _buildRichText(text, baseStyle: TextStyle(
              fontSize: 13 * _fontScale,
              height: 1.5,
              color: isWarning ? Colors.red.shade900 : Colors.green.shade900,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildMantraBlock(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.6), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📿', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.replaceAll('**', ''),
              style: GoogleFonts.rozhaOne(
                fontSize: 14 * _fontScale,
                height: 1.6,
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String line) {
    String cleanLine = line;
    String bulletSymbol = '🪷';
    if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('• ')) {
      cleanLine = line.substring(2).trim();
    } else {
      final m = RegExp(r'^(\d+)\.\s').firstMatch(line);
      if (m != null) {
        bulletSymbol = '${m.group(1)}.';
        cleanLine = line.substring(m.group(0)!.length).trim();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 2),
            width: 22,
            child: Text(
              bulletSymbol,
              style: TextStyle(
                fontSize: bulletSymbol == '🪷' ? 12 : 11 * _fontScale,
                color: AppTheme.primarySaffron,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildRichText(cleanLine, baseStyle: TextStyle(
              fontSize: 13.5 * _fontScale,
              height: 1.5,
              color: AppTheme.textDark,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueItem(String line) {
    final parts = line.split(':');
    final keyPart = parts[0].replaceAll('**', '').trim();
    final valuePart = parts.sublist(1).join(':').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$keyPart:',
              style: GoogleFonts.poppins(
                fontSize: 12.5 * _fontScale,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRichText(valuePart, baseStyle: TextStyle(
                fontSize: 13 * _fontScale,
                color: AppTheme.textDark,
                height: 1.4,
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _buildRichText(line, baseStyle: TextStyle(
        fontSize: 13.5 * _fontScale,
        height: 1.6,
        color: AppTheme.textDark,
      )),
    );
  }

  Widget _buildRichText(String text, {required TextStyle baseStyle}) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*([^*]+)\*\*)|(\*([^*]+)\*)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(2) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: baseStyle.color == AppTheme.textDark ? AppTheme.primaryDark : baseStyle.color,
          ),
        ));
      } else if (match.group(4) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(4),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildTableWidget(List<String> tableLines) {
    if (tableLines.isEmpty) return const SizedBox.shrink();

    final List<List<String>> parsedRows = [];
    for (final raw in tableLines) {
      // Skip markdown divider line |---|---|
      if (raw.contains('---')) continue;
      final cells = raw.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
      if (cells.isNotEmpty) {
        parsedRows.add(cells);
      }
    }

    if (parsedRows.isEmpty) return const SizedBox.shrink();

    final headerRow = parsedRows.first;
    final dataRows = parsedRows.skip(1).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.sacredGold.withValues(alpha: 0.4)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.primaryDark),
            headingTextStyle: GoogleFonts.poppins(
              fontSize: 12 * _fontScale,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            dataTextStyle: GoogleFonts.poppins(
              fontSize: 12 * _fontScale,
              color: AppTheme.textDark,
            ),
            columns: headerRow.map((h) => DataColumn(label: Text(h.replaceAll('**', '')))).toList(),
            rows: dataRows.map((row) {
              return DataRow(
                cells: List.generate(headerRow.length, (colIdx) {
                  final text = colIdx < row.length ? row[colIdx].replaceAll('**', '') : '';
                  return DataCell(Text(text));
                }),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
