import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/workers_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/price_helpers.dart';
import '../../../data/models/service_models.dart';

class WorkerPricesScreen extends ConsumerWidget {
  const WorkerPricesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerProfile = ref.watch(currentWorkerProfileProvider).value;
    if (workerProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pricesAsync = ref.watch(workerPricesProvider(workerProfile.uid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mis Precios', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEdit(context, ref, workerProfile.uid, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Agregar precio',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: pricesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (prices) {
          if (prices.isEmpty) {
            return _EmptyPrices(
              onAdd: () => _openAddEdit(context, ref, workerProfile.uid, null),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: prices.length,
            itemBuilder: (context, i) => _PriceCard(
              price: prices[i],
              index: i,
              onEdit: () => _openAddEdit(context, ref, workerProfile.uid, prices[i]),
              onDelete: () => _confirmDelete(context, ref, workerProfile.uid, prices[i]),
            ),
          );
        },
      ),
    );
  }

  void _openAddEdit(
    BuildContext context,
    WidgetRef ref,
    String workerUid,
    PriceModel? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: AddEditPriceSheet(
          workerUid: workerUid,
          existing: existing,
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String workerUid,
    PriceModel price,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar precio'),
        content: Text(
          '¿Seguro que quieres eliminar "${price.serviceName}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(workerRepositoryProvider)
                  .deletePrice(workerUid, price.priceId);
              // Invalidar para refrescar la lista
              ref.invalidate(workerPricesProvider(workerUid));
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de precio ────────────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.price,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final PriceModel price;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final priceText = price.priceMax != null
        ? '${formatCOP(price.priceMin.toInt())} – ${formatCOP(price.priceMax!.toInt())}'
        : formatCOP(price.priceMin.toInt());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.attach_money_rounded, color: AppColors.primary, size: 24),
        ),
        title: Text(
          price.serviceName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priceText,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  price.unit.label,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (price.notes != null && price.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                price.notes!,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: AppColors.primary,
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.error,
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    ).animate().slideX(begin: 0.15, duration: 400.ms, delay: Duration(milliseconds: index * 60)).fade();
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────
class _EmptyPrices extends StatelessWidget {
  const _EmptyPrices({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.price_change_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'Sin precios aún',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 200.ms).fade(),
          const SizedBox(height: 8),
          Text(
            'Agrega tus precios para que los clientes\nsepan cuánto cobras.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 300.ms).fade(),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Agregar mi primer precio',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 400.ms).fade(),
        ],
      ),
    );
  }
}

// ─── Bottom Sheet: Agregar / Editar precio ────────────────────────────────────
class AddEditPriceSheet extends ConsumerStatefulWidget {
  const AddEditPriceSheet({
    super.key,
    required this.workerUid,
    this.existing,
  });

  final String workerUid;
  final PriceModel? existing;

  @override
  ConsumerState<AddEditPriceSheet> createState() => _AddEditPriceSheetState();
}

class _AddEditPriceSheetState extends ConsumerState<AddEditPriceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  PriceUnit _unit = PriceUnit.porHora;
  bool _isLoading = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final p = widget.existing!;
      _nameCtrl.text = p.serviceName;
      _minCtrl.text = p.priceMin.toInt().toString();
      _maxCtrl.text = p.priceMax?.toInt().toString() ?? '';
      _notesCtrl.text = p.notes ?? '';
      _unit = p.unit;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workerRepositoryProvider);
      final priceMin = double.parse(_minCtrl.text.replaceAll('.', ''));
      final priceMaxRaw = _maxCtrl.text.trim().replaceAll('.', '');
      final priceMax = priceMaxRaw.isNotEmpty ? double.tryParse(priceMaxRaw) : null;

      if (priceMax != null && priceMax < priceMin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El precio máximo debe ser mayor al mínimo.'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final workerProfile = ref.read(currentWorkerProfileProvider).value!;
      final priceId = isEditing
          ? widget.existing!.priceId
          : '${DateTime.now().millisecondsSinceEpoch}';

      final newPrice = PriceModel(
        priceId: priceId,
        serviceName: _nameCtrl.text.trim(),
        category: workerProfile.category.name,
        unit: _unit,
        priceMin: priceMin,
        priceMax: priceMax,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        isActive: true,
      );

      if (isEditing) {
        await repo.updatePrice(widget.workerUid, newPrice);
      } else {
        await repo.addPrice(widget.workerUid, newPrice);
      }

      ref.invalidate(workerPricesProvider(widget.workerUid));

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Precio actualizado.' : 'Precio agregado.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final workerProfile = ref.watch(currentWorkerProfileProvider).value;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              // ── Handle ──
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Row(
                    children: [
                      Text(
                        isEditing ? 'Editar precio' : 'Nuevo precio',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Precios sugeridos ──
              if (workerProfile != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _SuggestedPrices(
                      category: workerProfile.category.name,
                      onSelect: (name, min, max) {
                        _nameCtrl.text = name;
                        _minCtrl.text = min.toString();
                        _maxCtrl.text = max.toString();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              // ── Formulario ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Nombre del servicio
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del servicio',
                        prefixIcon: Icon(Icons.build_outlined),
                        hintText: 'Ej: Instalación eléctrica residencial',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Describe el servicio'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Unidad
                    DropdownButtonFormField<PriceUnit>(
                      value: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unidad de cobro',
                        prefixIcon: Icon(Icons.straighten_rounded),
                      ),
                      items: PriceUnit.values
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.label),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                    const SizedBox(height: 20),

                    // Precios
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Precio mínimo (COP)',
                              prefixIcon: Icon(Icons.currency_exchange_rounded),
                              prefixText: '\$ ',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requerido';
                              if (double.tryParse(v.replaceAll('.', '')) == null) {
                                return 'Número inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _maxCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Máximo (opcional)',
                              prefixIcon: Icon(Icons.currency_exchange_rounded),
                              prefixText: '\$ ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notas
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        prefixIcon: Icon(Icons.note_outlined),
                        hintText: 'Ej: Incluye materiales básicos',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Botón guardar
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Icon(Icons.save_rounded, color: Colors.white),
                        label: Text(
                          _isLoading
                              ? 'Guardando...'
                              : isEditing
                                  ? 'Actualizar precio'
                                  : 'Agregar precio',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Precios sugeridos por categoría ─────────────────────────────────────────
class _SuggestedPrices extends StatelessWidget {
  const _SuggestedPrices({
    required this.category,
    required this.onSelect,
  });

  final String category;
  final void Function(String name, int min, int max) onSelect;

  static const _suggestions = <String, List<(String, int, int)>>{
    'plomeria': [
      ('Destape de tuberías', 60000, 150000),
      ('Instalación de sanitario', 80000, 200000),
      ('Revisión de fugas', 50000, 120000),
    ],
    'electricidad': [
      ('Instalación de tomacorriente', 40000, 80000),
      ('Revisión de tablero eléctrico', 80000, 180000),
      ('Instalación de luminaria', 30000, 70000),
    ],
    'cerrajeria': [
      ('Cambio de chapa', 60000, 150000),
      ('Apertura de puerta', 50000, 120000),
      ('Duplicado de llave', 10000, 30000),
    ],
    'aseo': [
      ('Aseo general', 80000, 200000),
      ('Lavado de muebles', 60000, 150000),
      ('Limpieza de ventanas', 40000, 100000),
    ],
    'pintura': [
      ('Pintura de habitación', 150000, 400000),
      ('Pintura de fachada', 300000, 800000),
      ('Estuco y pintura', 200000, 600000),
    ],
    'computadores': [
      ('Mantenimiento preventivo', 60000, 120000),
      ('Instalación de software', 40000, 80000),
      ('Recuperación de datos', 100000, 250000),
    ],
    'camaras': [
      ('Instalación cámara', 150000, 300000),
      ('Mantenimiento DVR', 80000, 180000),
      ('Configuración acceso remoto', 60000, 120000),
    ],
    'enchape': [
      ('Enchape de baño', 200000, 500000),
      ('Enchape de cocina', 250000, 600000),
      ('Instalación de piso', 180000, 400000),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = _suggestions[category] ?? [];
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(
              'Precios sugeridos para tu categoría:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: suggestions.map((s) {
            final (name, min, max) = s;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onSelect(name, min, max),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sugerido: ${formatCOP(min)} – ${formatCOP(max)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Usar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
