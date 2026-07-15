import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import 'car_detail_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io' show File;

class CarsScreen extends StatefulWidget {
  final String type; // 'all', 'small', or 'bus'

  const CarsScreen({super.key, required this.type});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  CarCategory selectedCategory = CarCategory.all;
  String searchQuery = '';
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    if (widget.type == 'small') {
      selectedCategory = CarCategory.luxury;
    } else if (widget.type == 'bus') {
      selectedCategory = CarCategory.bus;
    } else {
      selectedCategory = CarCategory.all;
    }
  }

  List<Car> getFilteredCars(List<Car> allCars) {
    return allCars.where((car) {
      bool matchesType = false;
      if (widget.type == 'small') {
        matchesType = car.category != CarCategory.bus;
        if (selectedCategory != CarCategory.all) {
          matchesType = matchesType && car.category == selectedCategory;
        }
      } else if (widget.type == 'bus') {
        matchesType = car.category == CarCategory.bus;
      } else {
        if (selectedCategory != CarCategory.all) {
          matchesType = car.category == selectedCategory;
        } else {
          matchesType = true;
        }
      }

      final matchesSearch = car.brand.toLowerCase().contains(searchQuery.toLowerCase()) ||
          car.model.toLowerCase().contains(searchQuery.toLowerCase());
      
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. MODERN SLIVER APP BAR
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1D275F),
            leading: Navigator.canPop(context) 
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: userProvider.imagePath != null
                      ? ClipOval(
                          child: Image.network(userProvider.imagePath!, width: 36, height: 36, fit: BoxFit.cover, 
                            errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.white)),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D275F), Color(0xFF003399)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 100, left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPageTitle(lang),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.white.withOpacity(0.6), size: 14),
                              const SizedBox(width: 5),
                              Text('Dar es Salaam, Tanzania', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. SEARCH BAR & FILTERS
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => searchQuery = val),
                      decoration: InputDecoration(
                        hintText: lang.translate('Search for your favorite car...', 'Tafuta gari unalopenda...'),
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF1D275F)),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF1D275F), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.tune, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildCategoryList(lang, context),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // 3. CARS GRID
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('cars').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              List<Car> carsFromDb = [];
              if (snapshot.hasData) {
                carsFromDb = snapshot.data!.docs.map((doc) => Car.fromFirestore(doc)).toList();
              }
              final filteredCars = getFilteredCars([...carsFromDb]);

              if (filteredCars.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.car_crash_outlined, size: 80, color: Colors.grey[200]),
                        const SizedBox(height: 15),
                        Text(lang.translate('No cars available in this category', 'Hakuna magari kwenye kundi hili'), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildModernCarCard(filteredCars[i], lang, context),
                    childCount: filteredCars.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildCategoryList(LanguageProvider lang, BuildContext context) {
    List<Map<String, dynamic>> categories = [
      {'label': lang.translate('All', 'Yote'), 'category': CarCategory.all, 'icon': Icons.apps},
      {'label': lang.translate('SUV', 'SUV'), 'category': CarCategory.suv, 'icon': Icons.directions_car},
      {'label': lang.translate('Sedan', 'Sedan'), 'category': CarCategory.sedan, 'icon': Icons.directions_car_filled},
      {'label': lang.translate('Luxury', 'Luxury'), 'category': CarCategory.luxury, 'icon': Icons.auto_awesome},
      {'label': lang.translate('Sports', 'Sports'), 'category': CarCategory.sports, 'icon': Icons.speed},
      {'label': lang.translate('Bus', 'Bus'), 'category': CarCategory.bus, 'icon': Icons.directions_bus},
    ];

    // Filter categories based on screen type
    if (widget.type == 'small') {
      categories = categories.where((c) => c['category'] != CarCategory.bus).toList();
    } else if (widget.type == 'bus') {
      categories = categories.where((c) => c['category'] == CarCategory.bus || c['category'] == CarCategory.all).toList();
    }

    return SizedBox(
      height: 45,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isSelected = selectedCategory == cat['category'];
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat['category']),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1D275F) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSelected ? const Color(0xFF1D275F) : Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(cat['icon'], size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    cat['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernCarCard(Car car, LanguageProvider lang, BuildContext context) {
    bool isUnavailable = car.status == 'unavailable';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => CarDetailScreen(car: car))),
        borderRadius: BorderRadius.circular(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF1F3F6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      child: Hero(
                        tag: car.id,
                        child: car.imageUrl.startsWith('http') 
                          ? Image.network(car.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 50, color: Colors.grey))
                          : Image.asset(car.imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 50, color: Colors.grey)),
                      ),
                    ),
                  ),
                  if (isUnavailable)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                            child: Text(lang.translate('BOOKED', 'IMEPANGWA'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 12),
                          const SizedBox(width: 2),
                          Text(car.rating.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Details Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.brand,
                          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          car.model,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF1D275F)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickSpec(Icons.people_outline, '${car.seats}'),
                        _buildQuickSpec(Icons.settings_outlined, car.transmission == Transmission.automatic ? 'Auto' : 'Man'),
                      ],
                    ),

                    const Divider(height: 1, color: Color(0xFFEEEEEE)),

                    Row(
                      children: [
                        Text(
                          '${_currencyFormat.format(car.pricePerDay)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF003399)),
                        ),
                        const Text(
                          '/day',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSpec(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blueGrey[300]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10, color: Colors.blueGrey[400], fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getPageTitle(LanguageProvider lang) {
    if (widget.type == 'small') return lang.translate('Small Cars', 'Gari Ndogo');
    if (widget.type == 'bus') return lang.translate('Buss / Costa', 'Buss / Costa');
    return lang.translate('Premium Cars', 'Magari Bora');
  }
}
