import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/workers_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/service_models.dart';

const _maxPhotos = 12;

class WorkerGalleryScreen extends ConsumerWidget {
  const WorkerGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(currentWorkerProfileProvider);

    return workerAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (worker) {
        if (worker == null) {
          return const Scaffold(body: Center(child: Text('Perfil no encontrado')));
        }
        return _GalleryBody(workerUid: worker.uid);
      },
    );
  }
}

// ─── Cuerpo principal ─────────────────────────────────────────────────────────
class _GalleryBody extends ConsumerWidget {
  const _GalleryBody({required this.workerUid});
  final String workerUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryAsync = ref.watch(workerGalleryProvider(workerUid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Mi Galería',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: galleryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(onRetry: () => ref.invalidate(workerGalleryProvider(workerUid))),
        data: (photos) => _GalleryGrid(
          workerUid: workerUid,
          photos: photos,
          onPhotoAdded: () => ref.invalidate(workerGalleryProvider(workerUid)),
          onPhotoDeleted: () => ref.invalidate(workerGalleryProvider(workerUid)),
        ),
      ),
    );
  }
}

// ─── Grid de fotos ─────────────────────────────────────────────────────────────
class _GalleryGrid extends ConsumerStatefulWidget {
  const _GalleryGrid({
    required this.workerUid,
    required this.photos,
    required this.onPhotoAdded,
    required this.onPhotoDeleted,
  });

  final String workerUid;
  final List<GalleryPhotoModel> photos;
  final VoidCallback onPhotoAdded;
  final VoidCallback onPhotoDeleted;

  @override
  ConsumerState<_GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends ConsumerState<_GalleryGrid> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    if (widget.photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo $_maxPhotos fotos permitidas.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final photoId = const Uuid().v4();
      final file = File(picked.path);

      // Comprimir imagen principal (800px, calidad 80)
      final compressed = await FlutterImageCompress.compressWithFile(
        file.path,
        quality: 80,
        minWidth: 800,
        minHeight: 800,
      );
      if (compressed == null) throw Exception('No se pudo comprimir la imagen.');

      // Subir imagen principal
      final storageRef = FirebaseStorage.instance.ref('gallery/${widget.workerUid}/$photoId.jpg');
      await storageRef.putData(compressed);
      final url = await storageRef.getDownloadURL();

      // Thumbnail (150px, calidad 50)
      final thumb = await FlutterImageCompress.compressWithList(
        compressed,
        quality: 50,
        minWidth: 150,
        minHeight: 150,
      );
      final thumbRef = FirebaseStorage.instance
          .ref('gallery/${widget.workerUid}/thumb_$photoId.jpg');
      await thumbRef.putData(thumb);
      final thumbUrl = await thumbRef.getDownloadURL();

      // Guardar en Firestore vía repositorio
      final order = widget.photos.isEmpty
          ? 0
          : widget.photos.map((p) => p.order).reduce((a, b) => a > b ? a : b) + 1;

      final photo = GalleryPhotoModel(
        photoId: photoId,
        url: url,
        thumbnailUrl: thumbUrl,
        uploadedAt: DateTime.now(),
        order: order,
      );

      await ref.read(workerRepositoryProvider).addPhoto(widget.workerUid, photo);

      if (!mounted) return;
      widget.onPhotoAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto agregada a tu galería ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir foto: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(GalleryPhotoModel photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Seguro que quieres eliminar esta foto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(workerRepositoryProvider).deletePhoto(widget.workerUid, photo.photoId);
      // Intentar borrar del Storage (best-effort)
      try {
        await FirebaseStorage.instance
            .ref('gallery/${widget.workerUid}/${photo.photoId}.jpg')
            .delete();
        await FirebaseStorage.instance
            .ref('gallery/${widget.workerUid}/thumb_${photo.photoId}.jpg')
            .delete();
      } catch (_) {}
      widget.onPhotoDeleted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GalleryViewer(
          photos: widget.photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd = widget.photos.length < _maxPhotos;

    if (widget.photos.isEmpty && !_isUploading) {
      return _EmptyGallery(onAdd: _pickAndUpload);
    }

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header informativo ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.photos.length}/$_maxPhotos fotos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (widget.photos.length < 3)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 13, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              'Sube ${3 - widget.photos.length} más para completar tu perfil',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Grid ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final photo = widget.photos[i];
                    return _PhotoTile(
                      photo: photo,
                      index: i,
                      onTap: () => _openViewer(i),
                      onDelete: () => _deletePhoto(photo),
                    );
                  },
                  childCount: widget.photos.length,
                ),
              ),
            ),
          ],
        ),

        // ── Upload overlay ──
        if (_isUploading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Subiendo foto...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        // ── FAB ──
        if (canAdd && !_isUploading)
          Positioned(
            bottom: 24,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _pickAndUpload,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
              label: const Text(
                'Agregar foto',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          ),
      ],
    );
  }
}

// ─── Tile de foto ─────────────────────────────────────────────────────────────
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final GalleryPhotoModel photo;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showMenu(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen
            Image.network(
              photo.thumbnailUrl ?? photo.url,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: const Icon(Icons.broken_image_rounded,
                    color: AppColors.primary),
              ),
            ),
            // Overlay con número de orden (sutil)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Caption si existe
            if (photo.caption != null && photo.caption!.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Text(
                    photo.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.85, 0.85),
          duration: 350.ms,
          delay: Duration(milliseconds: index * 40),
          curve: Curves.easeOutBack,
        );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.fullscreen_rounded),
                title: const Text('Ver en pantalla completa'),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Eliminar foto',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ─── Viewer full-screen ───────────────────────────────────────────────────────
class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({
    required this.photos,
    required this.initialIndex,
  });

  final List<GalleryPhotoModel> photos;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── PageView de imágenes con zoom ──
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.photos[i].url,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white54, size: 64),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Caption abajo ──
          if (photo.caption != null && photo.caption!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Text(
                  photo.caption!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ── Flechas de navegación ──
          if (_currentIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left_rounded,
                      color: Colors.white, size: 36),
                  onPressed: () => _pageCtrl.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
          if (_currentIndex < widget.photos.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white, size: 36),
                  onPressed: () => _pageCtrl.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),

          // ── Puntos indicadores ──
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.photos.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────
class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 60,
                color: AppColors.secondary,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Tu galería está vacía',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 150.ms).fade(),
            const SizedBox(height: 10),
            Text(
              'Sube fotos de tus trabajos para que\nlos clientes vean tu calidad.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 250.ms).fade(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Text(
                '💡 Perfiles con 3+ fotos reciben 4× más contactos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fade(delay: 350.ms),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
              label: const Text(
                'Subir primera foto',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 6,
                shadowColor: AppColors.secondary.withValues(alpha: 0.4),
              ),
            ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 400.ms).fade(),
          ],
        ),
      ),
    );
  }
}

// ─── Estado de error ──────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Error al cargar la galería',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
