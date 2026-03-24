import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/extensions.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../controllers/material_controller.dart';
import '../widgets/material_card.dart';

class MaterialListScreen extends ConsumerWidget {
  const MaterialListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark           = context.isDark;
    final isAdmin          = ref.watch(isAdminProvider);
    final allMatsAsync     = ref.watch(allMaterialsProvider);
    final filteredMats     = ref.watch(filteredMaterialsProvider);
    final subjects         = ref.watch(materialSubjectsProvider);
    final selectedSubject  = ref.watch(selectedSubjectProvider);

    // Listen for upload/delete outcomes
    ref.listen(materialControllerProvider, (_, next) {
      if (next.error != null) {
        context.showError(next.error!);
        ref.read(materialControllerProvider.notifier).resetState();
      }
      if (next.success) {
        context.showSuccess('Done!');
        ref.read(materialControllerProvider.notifier).resetState();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── SliverAppBar ───────────────────────────────────
          SliverAppBar(
            pinned:          true,
            floating:        true,
            snap:            true,
            expandedHeight:  100,
            backgroundColor: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            elevation:       0,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(
                  left: AppSizes.md, bottom: AppSizes.md),
              title: Text('📂  Study Materials',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            actions: [
              if (isAdmin)
                IconButton(
                  icon:    const Icon(Icons.add_rounded),
                  tooltip: 'Upload Material',
                  onPressed: () => context.push('/home/materials/add'),
                ),
              const SizedBox(width: AppSizes.xs),
            ],
            // ── Search & Filter ────────────────────────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110), // Increased height for search + chips
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    child: SizedBox(
                      height: 44,
                      child: TextField(
                        onChanged: (val) => ref.read(materialSearchProvider.notifier).state = val,
                        decoration: InputDecoration(
                          hintText: 'Search materials...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm),
                      children: [
                    _FilterChip(
                      label:    'All',
                      selected: selectedSubject.isEmpty,
                      onTap:    () => ref
                          .read(selectedSubjectProvider.notifier)
                          .state = '',
                    ),
                    ...subjects.map((s) => _FilterChip(
                          label:    s,
                          selected: selectedSubject == s,
                          onTap:    () => ref
                              .read(selectedSubjectProvider.notifier)
                              .state = s,
                        )),
                  ],
                ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () async {
            // Fake delay for UX (Firestore updates in realtime)
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: AppColors.primary,
          child: switch (allMatsAsync) {
            AsyncLoading() => const Center(child: CardShimmerList(count: 5)),
            AsyncError(:final error) => ErrorStateWidget(
                message: error.toString()),
          _ => filteredMats.isEmpty
              ? EmptyStateWidget(
                  icon:    Icons.folder_open_outlined,
                  title:   'No Materials',
                  message: selectedSubject.isEmpty
                      ? 'Study materials will appear here once uploaded.'
                      : 'No materials for "$selectedSubject" yet.',
                  actionLabel: isAdmin ? '+ Upload' : null,
                  onAction:    isAdmin
                      ? () => context.push('/home/materials/add')
                      : null,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.md, AppSizes.sm,
                      AppSizes.md, AppSizes.xxl),
                  physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even on short lists
                  itemCount: filteredMats.length,
                  itemBuilder: (_, i) => MaterialCard(
                    material: filteredMats[i],
                    index:    i,
                    isAdmin:  isAdmin,
                    onDelete: isAdmin
                        ? () => _confirmDelete(context, ref, filteredMats[i])
                        : null,
                  ),
                ),
          },
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag:   'fab_materials',
              onPressed: () => context.push('/home/materials/add'),
              child:     const Icon(Icons.upload_file_rounded),
            )
          : null,
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, material) async {
    final ok = await showConfirmationDialog(
      context:       context,
      title:         'Delete Material',
      message:       'Remove "${material.title}"? This will also delete the file from storage.',
      confirmLabel:  'Delete',
      isDestructive: true,
    );
    if (ok) {
      ref.read(materialControllerProvider.notifier).deleteMaterial(material);
    }
  }
}

// ── Subject filter chip ───────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String   label;
  final bool     selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: AppSizes.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      selected
                ? Colors.white
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize:   13,
          ),
        ),
      ),
    );
  }
}