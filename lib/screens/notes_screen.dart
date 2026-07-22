import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../widgets/pixel_container.dart';
import '../widgets/lily_snackbar.dart';
import '../main.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    globalRefreshTrigger.addListener(_fetchNotes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    globalRefreshTrigger.removeListener(_fetchNotes);
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    globalRefreshTrigger.value++;
    await _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('notes').select().order('created_at', ascending: false);
      setState(() {
        _notes = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        LilySnackBar.show(context, message: 'Gagal memuat catatan. Silakan coba lagi.', isSuccess: false);
      }
    }
  }

  Future<void> _deleteNote(String id) async {
    setState(() => _isLoading = true);
    try {
      await _supabase.from('notes').delete().eq('id', id);
      _fetchNotes();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        LilySnackBar.show(context, message: 'Gagal menghapus catatan. Silakan coba lagi.', isSuccess: false);
      }
    }
  }

  Future<void> _confirmDeleteNote(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.error, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text('HAPUS CATATAN?', style: GoogleFonts.silkscreen(color: AppColors.error, fontSize: 14)),
        content: Text('Catatan ini akan dihapus permanen.', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('BATAL', style: GoogleFonts.silkscreen(color: AppColors.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('HAPUS', style: GoogleFonts.silkscreen(color: AppColors.onError)),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteNote(id);
  }

  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppColors.primary, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          title: Text('NEW NOTE', style: GoogleFonts.silkscreen(color: AppColors.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.plusJakartaSans(),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 4)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                maxLines: 3,
                style: GoogleFonts.plusJakartaSans(),
                decoration: const InputDecoration(
                  labelText: 'Body',
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 4)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.silkscreen(color: AppColors.error)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () async {
                final title = titleController.text;
                final body = bodyController.text;
                if (title.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await _supabase.from('notes').insert({'title': title, 'body': body, 'user_id': _supabase.auth.currentUser!.id});
                    _fetchNotes();
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      LilySnackBar.show(context, message: 'Gagal menyimpan catatan. Silakan coba lagi.', isSuccess: false);
                    }
                  }
                }
              },
              child: Text('SAVE', style: GoogleFonts.silkscreen(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showEditNoteDialog(Map<String, dynamic> note) {
    final titleController = TextEditingController(text: note['title'] ?? '');
    final bodyController = TextEditingController(text: note['body'] ?? '');
    final noteId = note['id'].toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppColors.primary, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          title: Text('EDIT NOTE', style: GoogleFonts.silkscreen(color: AppColors.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.plusJakartaSans(),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 4)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                maxLines: 3,
                style: GoogleFonts.plusJakartaSans(),
                decoration: const InputDecoration(
                  labelText: 'Body',
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 4)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.silkscreen(color: AppColors.error)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () async {
                final title = titleController.text;
                final body = bodyController.text;
                if (title.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await _supabase.from('notes').update({'title': title, 'body': body}).eq('id', noteId);
                    _fetchNotes();
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      LilySnackBar.show(context, message: 'Gagal mengubah catatan. Silakan coba lagi.', isSuccess: false);
                    }
                  }
                }
              },
              child: Text('UPDATE', style: GoogleFonts.silkscreen(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.headerBg,
            border: Border(bottom: BorderSide(color: AppColors.headerBorder, width: 4)),
            boxShadow: [BoxShadow(color: AppColors.headerBorder, offset: Offset(0, 4), blurRadius: 0)],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.headerBorder), onPressed: () => Navigator.pop(context)),
                  const Text('LILYPAD', style: TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.headerBorder)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary, width: 4))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('MY NOTES', style: GoogleFonts.silkscreen(fontSize: 32, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text('Capture your thoughts, pixel by pixel.', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.onSurfaceVariant)),
                  ]),
                ),
                const SizedBox(height: 16),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: const [BoxShadow(color: AppColors.primary, offset: Offset(2, 2), blurRadius: 0)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Cari catatan...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.outline),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: AppColors.error),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Content Area (Loading, Empty, or List)
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.primaryContainer,
                          onRefresh: _handleRefresh,
                          child: Builder(
                            builder: (context) {
                              final filteredNotes = _searchQuery.isEmpty
                                ? _notes
                                : _notes.where((n) {
                                    final title = (n['title'] ?? '').toString().toLowerCase();
                                    final body = (n['body'] ?? '').toString().toLowerCase();
                                    return title.contains(_searchQuery) || body.contains(_searchQuery);
                                  }).toList();
                              
                              if (filteredNotes.isEmpty) {
                                return SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    alignment: Alignment.center,
                                    child: Text(
                                      _searchQuery.isEmpty
                                        ? 'Belum ada catatan.\nTekan + untuk menambah.'
                                        : 'Tidak ada catatan yang cocok\ndengan "$_searchQuery".',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.onSurfaceVariant),
                                    ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filteredNotes.length,
                                itemBuilder: (context, index) {
                                  final note = filteredNotes[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildNoteCard(
                                      note['title'] ?? 'No Title',
                                      note['body'],
                                      note['is_pinned'] == true,
                                      () => _showEditNoteDialog(note),
                                      () => _confirmDeleteNote(note['id'].toString()),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16, right: 16,
            child: GestureDetector(
              onTap: _showAddNoteDialog,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: AppColors.primaryContainer, border: Border.all(color: AppColors.primary, width: 4),
                  boxShadow: const [BoxShadow(color: AppColors.primary, offset: Offset(4, 4), blurRadius: 0)]),
                child: const Icon(Icons.add, color: AppColors.primary, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String title, String? body, bool isPinned, VoidCallback onEdit, VoidCallback onDelete) {
    return Stack(clipBehavior: Clip.none, children: [
      PixelContainer(
        padding: const EdgeInsets.all(16), 
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                if (body != null && body.isNotEmpty) ...[
                  const SizedBox(height: 8), 
                  Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.onSurfaceVariant))
                ],
              ]),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.secondary),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: onDelete,
                ),
              ],
            )
          ],
        )
      ),
      if (isPinned) Positioned(top: -8, right: -8, child: Transform.rotate(angle: 0.2, child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: AppColors.error, border: Border.all(color: AppColors.onSurface, width: 2),
          boxShadow: const [BoxShadow(color: AppColors.primary, offset: Offset(2, 2), blurRadius: 0)]),
        child: const Icon(Icons.push_pin, color: AppColors.onError, size: 14),
      ))),
    ]);
  }
}
