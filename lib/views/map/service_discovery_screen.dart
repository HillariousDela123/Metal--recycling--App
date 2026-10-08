import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/helpers.dart';
import '../../models/service_model.dart';
import '../../viewmodels/service_provider.dart';
import '../service/service_detail_screen.dart';

class ServiceDiscoveryScreen extends StatefulWidget {
  const ServiceDiscoveryScreen({super.key});

  @override
  State<ServiceDiscoveryScreen> createState() => _ServiceDiscoveryScreenState();
}

class _ServiceDiscoveryScreenState extends State<ServiceDiscoveryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceProvider = context.watch<ServiceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final services = serviceProvider.filteredServices;
    final selectedMetal = serviceProvider.selectedMetalCategory;
    final isMapView = serviceProvider.isMapView;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.discoveryTitle),
        actions: [
          // Toggle between List and Map view
          IconButton(
            tooltip: isMapView ? 'Switch to List View' : 'Switch to Map View',
            icon: Icon(isMapView ? Icons.view_list_rounded : Icons.map_rounded),
            onPressed: () {
              serviceProvider.toggleMapView(!isMapView);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: isDark ? AppColors.surfaceDark : Colors.white,
              child: Column(
                children: [
                  // Search Input
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => serviceProvider.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                serviceProvider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text(AppStrings.filterAll),
                          selected: selectedMetal == null,
                          onSelected: (_) => serviceProvider.selectMetalCategory(null),
                          selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                          checkmarkColor: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        ...AppConstants.metalCategories.map((metal) {
                          final isSelected = selectedMetal?.toLowerCase() == metal.name.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(metal.icon, size: 14, color: isSelected ? Colors.white : metal.color),
                                  const SizedBox(width: 4),
                                  Text(metal.name),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (_) => serviceProvider.selectMetalCategory(metal.name),
                              selectedColor: AppColors.primaryGreen,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content: List or Map View
            Expanded(
              child: serviceProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : services.isEmpty
                      ? _buildEmptyState(isDark)
                      : isMapView
                          ? _buildMapView(services, serviceProvider, isDark)
                          : _buildListView(services, serviceProvider, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 64, color: isDark ? AppColors.textSecondaryDark : Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Recycling Centers Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try clearing your search query or selecting a different metal filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<ServiceModel> services, ServiceProvider provider, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final distanceMeters = provider.getDistanceToService(service);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              provider.selectService(service);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(service: service),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppColors.primaryGreen, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service.address,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.copperLight.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.copper, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${service.rating}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.bronze),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Distance badge
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded, size: 14, color: AppColors.primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            AppHelpers.formatDistance(distanceMeters),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.schedule_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.openNow,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Accepted Metals Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: service.acceptedMetals.map((metal) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          metal,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView(List<ServiceModel> services, ServiceProvider provider, bool isDark) {
    // Interactive location radar / visual map placeholder for desktop/simulator preview
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFE2E8F0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    border: BorderSide(color: AppColors.primaryGreen.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.explore_rounded, size: 54, color: AppColors.primaryGreen),
                ),
                const SizedBox(height: 16),
                Text(
                  'Showing ${services.length} Recycling Center Pins',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'GPS Location Active • Tap a pin card below to view details',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Carousel preview cards at bottom of map
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final s = services[index];
                final dist = provider.getDistanceToService(s);

                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Text(
                            AppHelpers.formatDistance(dist),
                            style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                      Text(
                        s.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 36),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          provider.selectService(s);
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: s)),
                          );
                        },
                        child: const Text('View Center Details', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
