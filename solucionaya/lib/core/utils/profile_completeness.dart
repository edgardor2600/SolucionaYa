import '../../data/models/service_models.dart';
import '../../data/models/worker_profile_model.dart';

/// Calcula qué tan completo está el perfil de un trabajador (0–100).
/// Cada ítem faltante es un "to-do" que se muestra en el dashboard.
class ProfileCompleteness {
  const ProfileCompleteness._();

  static const _itemPhoto = _CompletenessItem(
    key: 'photo',
    label: 'Agrega una foto de perfil',
    icon: 'photo',
    points: 15,
  );
  static const _itemBio = _CompletenessItem(
    key: 'bio',
    label: 'Escribe una descripción breve',
    icon: 'bio',
    points: 15,
  );
  static const _itemExperience = _CompletenessItem(
    key: 'experience',
    label: 'Indica tus años de experiencia',
    icon: 'experience',
    points: 10,
  );
  static const _itemPrices = _CompletenessItem(
    key: 'prices',
    label: 'Agrega al menos un precio',
    icon: 'prices',
    points: 20,
  );
  static const _itemGallery = _CompletenessItem(
    key: 'gallery',
    label: 'Sube al menos 3 fotos de trabajos',
    icon: 'gallery',
    points: 20,
  );
  static const _itemSchedule = _CompletenessItem(
    key: 'schedule',
    label: 'Configura tu horario semanal',
    icon: 'schedule',
    points: 10,
  );
  static const _itemWhatsapp = _CompletenessItem(
    key: 'whatsapp',
    label: 'Agrega tu número de WhatsApp',
    icon: 'whatsapp',
    points: 10,
  );

  static final _allItems = [
    _itemPhoto,
    _itemBio,
    _itemExperience,
    _itemPrices,
    _itemGallery,
    _itemSchedule,
    _itemWhatsapp,
  ];

  /// Devuelve el resultado de completitud con porcentaje e ítems faltantes.
  static CompletenessResult calculate({
    required WorkerProfileModel profile,
    required List<PriceModel> prices,
    required List<GalleryPhotoModel> gallery,
  }) {
    final completed = <String>{};

    if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
      completed.add('photo');
    }
    if (profile.bio != null && profile.bio!.trim().length >= 20) {
      completed.add('bio');
    }
    if (profile.yearsExperience > 0) completed.add('experience');
    if (prices.isNotEmpty) completed.add('prices');
    if (gallery.length >= 3) completed.add('gallery');
    if (profile.availableSchedule.isNotEmpty) completed.add('schedule');
    if (profile.whatsappNumber != null && profile.whatsappNumber!.isNotEmpty) {
      completed.add('whatsapp');
    }

    final score = _allItems
        .where((item) => completed.contains(item.key))
        .fold(0, (sum, item) => sum + item.points);

    final missing = _allItems
        .where((item) => !completed.contains(item.key))
        .toList();

    return CompletenessResult(score: score.clamp(0, 100), missingItems: missing);
  }
}

class _CompletenessItem {
  const _CompletenessItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.points,
  });

  final String key;
  final String label;
  final String icon;
  final int points;
}

class CompletenessResult {
  const CompletenessResult({
    required this.score,
    required this.missingItems,
  });

  final int score;
  final List<_CompletenessItem> missingItems;

  bool get isComplete => score >= 100;
  String get missingLabel => missingItems.map((e) => e.label).join(', ');
}
