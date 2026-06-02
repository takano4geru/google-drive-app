import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/drive_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _editingFileId;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _clearEditor() {
    setState(() {
      _titleController.clear();
      _contentController.clear();
      _editingFileId = null;
    });
  }

  void _startEditing(String fileId, String title, String cachedContent) {
    setState(() {
      _editingFileId = fileId;
      _titleController.text = title;
      _contentController.text = cachedContent;
    });
  }

  Future<void> _saveFile() async {
    if (!_formKey.currentState!.validate()) return;

    final driveState = ref.read(driveProvider.notifier);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    try {
      if (_editingFileId != null) {
        await driveState.updateFile(_editingFileId!, content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File updated successfully!')),
          );
        }
      } else {
        await driveState.createFile(title, content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File created successfully!')),
          );
        }
      }
      _clearEditor();
    } catch (e) {
      // Error is caught here, success snackbar will not be shown.
      // The error itself is already reported to the user via the DriveState listener.
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final driveState = ref.watch(driveProvider);

    // Watch for error messages and display them
    ref.listen<DriveState>(driveProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    final isAuthorized = authState.user != null || authState.isOfflineMode;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate
      body: SafeArea(
        child: !isAuthorized
            ? _buildLoginScreen(context, authState, driveState)
            : _buildDashboard(context, authState, driveState),
      ),
    );
  }

  Widget _buildLoginScreen(BuildContext context, AuthState authState, DriveState driveState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: const Color(0x1F334155), // Translucent slate
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: const Color(0x3394A3B8), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.cloud_sync,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // App Title
              Text(
                'CloudSync Docs',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                'Sync your private notes seamlessly and securely inside your personal Google Drive account. No third-party servers.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Google Login Button
              if (authState.isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                )
              else ...[
                ElevatedButton(
                  onPressed: () => ref.read(authProvider.notifier).signIn(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Logo Icon (drawn customly or with text)
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                        height: 22,
                        width: 22,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.login,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sign In with Google',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (driveState.files.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).enterOfflineMode(),
                    icon: const Icon(Icons.offline_pin_outlined, color: Color(0xFF06B6D4)),
                    label: Text(
                      'Continue Offline (View Cache)',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF06B6D4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, AuthState authState, DriveState driveState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;

        return CustomScrollView(
          slivers: [
            // Header Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildHeader(context, authState, driveState),
              ),
            ),
            // Body Grid/List
            if (isLargeScreen)
              SliverFillRemaining(
                hasScrollBody: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: _buildFileEditor(context, driveState),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 6,
                        child: _buildFileExplorer(context, driveState),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildFileEditor(context, driveState),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      height: 500,
                      child: _buildFileExplorer(context, driveState),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AuthState authState, DriveState driveState) {
    final user = authState.user;
    final isOffline = authState.isOfflineMode;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0x12334155),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0x1A94A3B8), width: 1),
      ),
      child: Row(
        children: [
          // App logo/sync indicator
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOffline
                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                        : [const Color(0xFF6366F1), const Color(0xFF06B6D4)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOffline ? Icons.cloud_off : Icons.cloud_done,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (driveState.isLoading && !isOffline)
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CloudSync Docs',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isOffline
                      ? 'Offline Mode (Viewing Cache)'
                      : (driveState.isLoading
                          ? 'Syncing with Google Drive...'
                          : 'Connected securely'),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isOffline
                        ? const Color(0xFFF59E0B)
                        : (driveState.isLoading
                            ? const Color(0xFF06B6D4)
                            : const Color(0xFF10B981)),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // User Card & Logout
          if (user != null || isOffline)
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.displayName ?? 'Offline User',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user?.email ?? 'Local Cache',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                if (user?.photoUrl != null)
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(user!.photoUrl!),
                  )
                else
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF6366F1),
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    isOffline ? Icons.exit_to_app : Icons.logout,
                    color: const Color(0xFFEF4444),
                    size: 20,
                  ),
                  tooltip: isOffline ? 'Exit Offline Mode' : 'Logout',
                  onPressed: isOffline
                      ? () => ref.read(authProvider.notifier).exitOfflineMode()
                      : () => ref.read(authProvider.notifier).signOut(),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildFileEditor(BuildContext context, DriveState driveState) {
    final isEditing = _editingFileId != null;
    final isOffline = ref.watch(authProvider).isOfflineMode;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0x1F334155),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0x2294A3B8), width: 1),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Document' : 'Create New Document',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (isEditing)
                  TextButton.icon(
                    onPressed: _clearEditor,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Title Input
            TextFormField(
              controller: _titleController,
              enabled: !isEditing && !isOffline, // Title cannot be modified on Drive easily, disabled if offline
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Document Title',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                hintText: 'e.g. todo_list.txt',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF475569)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x3394A3B8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x1194A3B8)),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Content Input
            TextFormField(
              controller: _contentController,
              maxLines: 8,
              enabled: !isOffline, // Disabled if offline
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Content',
                labelStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                hintText: 'Type your secure note here...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF475569)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x3394A3B8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x1194A3B8)),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter some content';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Submit Button
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x11EF4444),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x22EF4444)),
                ),
                child: Text(
                  'Creating and editing notes is disabled in offline guest mode. Log in with internet connection to modify notes.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFFCA5A5),
                  ),
                ),
              )
            else if (driveState.isLoading &&
                (driveState.operationType == 'create' || driveState.operationType == 'update'))
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              )
            else
              ElevatedButton(
                onPressed: _saveFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Save to Google Drive',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileExplorer(BuildContext context, DriveState driveState) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0x1F334155),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0x2294A3B8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synced Files',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 20),
                tooltip: 'Refresh list',
                onPressed: () => ref.read(driveProvider.notifier).loadFiles(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: driveState.files.isEmpty &&
                    driveState.isLoading &&
                    driveState.operationType == 'list'
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                    ),
                  )
                : driveState.files.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: driveState.files.length,
                        itemBuilder: (context, index) {
                          final file = driveState.files[index];
                          return _buildFileItem(context, file, driveState);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: const Color(0xFF475569),
          ),
          const SizedBox(height: 16),
          Text(
            'No files found',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first file using the panel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, var file, DriveState driveState) {
    final isOffline = ref.watch(authProvider).isOfflineMode;
    final fileId = file.id ?? '';
    final fileName = file.name ?? 'Untitled';
    final modifiedTime = file.modifiedTime != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(file.modifiedTime!.toLocal())
        : 'Unknown Date';

    final isCached = driveState.fileContents.containsKey(fileId);
    final isCurrentFileActive = driveState.activeFileId == fileId;
    final isReading = driveState.isLoading &&
        driveState.operationType == 'read' &&
        isCurrentFileActive;
    final isDeleting = driveState.isLoading &&
        driveState.operationType == 'delete' &&
        isCurrentFileActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF0F172A),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _editingFileId == fileId
                ? const Color(0xFF6366F1)
                : const Color(0x1194A3B8),
            width: _editingFileId == fileId ? 1.5 : 1,
          ),
        ),
        child: ExpansionTile(
          key: PageStorageKey<String>(fileId),
          iconColor: const Color(0xFF06B6D4),
          collapsedIconColor: const Color(0xFF94A3B8),
          textColor: Colors.white,
          collapsedTextColor: Colors.white,
          title: Text(
            fileName,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Modified: $modifiedTime',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF475569),
            ),
          ),
          onExpansionChanged: (expanded) {
            if (expanded && !isCached) {
              ref.read(driveProvider.notifier).readFile(fileId);
            }
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File content view
                  if (isReading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1A334155),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x1194A3B8)),
                      ),
                      child: Text(
                        driveState.fileContents[fileId] ?? 'No content loaded.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFFE2E8F0),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Edit Button
                      TextButton.icon(
                        onPressed: isReading || isDeleting || isOffline
                            ? null
                            : () {
                                final content = driveState.fileContents[fileId] ?? '';
                                _startEditing(fileId, fileName, content);
                              },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF06B6D4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete Button
                      if (isDeleting)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        TextButton.icon(
                          onPressed: isOffline
                              ? null
                              : () => _confirmDelete(context, fileId, fileName),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String fileId, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Delete Document',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete "$fileName" from your Google Drive?',
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(driveProvider.notifier).deleteFile(fileId);
            },
          ),
        ],
      ),
    );
  }
}
