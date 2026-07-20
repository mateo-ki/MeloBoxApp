import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/category_provider.dart';
import '../providers/site_provider.dart';
import '../providers/video_provider.dart';

class CategoryFilter extends StatelessWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoCategoryProvider>(
      builder: (context, categoryProvider, child) {
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          height: 52,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categoryProvider.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              final isSelected = category.id == categoryProvider.selectedCategoryId;

              return FilterChip(
                label: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) {
                    return;
                  }

                  categoryProvider.selectCategory(category.id);

                  final siteProvider = context.read<SiteProvider>();
                  final videoProvider = context.read<VideoProvider>();
                  final site = siteProvider.currentSite;
                  if (site == null) {
                    return;
                  }

                  if (category.id.isEmpty) {
                    videoProvider.loadVideoList(site.baseUrl);
                  } else {
                    videoProvider.loadVideoListByCategory(
                      site.baseUrl,
                      category.id,
                    );
                  }
                },
                selectedColor: colorScheme.primaryContainer,
                backgroundColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: isSelected ? 1.5 : 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: isSelected ? 2 : 0,
                shadowColor: colorScheme.primary.withValues(alpha: 0.3),
              );
            },
          ),
        );
      },
    );
  }
}
