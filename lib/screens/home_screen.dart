import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car.dart';
import 'car_detail_screen.dart';
import 'cars_screen.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/header_clipper.dart';
import 'dart:io' show File;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  String _selectedCategory = 'All';
  int _bannerCount = 2; 

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'sw': 'Zote', 'icon': Icons.apps_rounded},
    {'name': 'Luxury', 'sw': 'Luxury', 'icon': Icons.star_rounded},
    {'name': 'Sports', 'sw': 'Sports', 'icon': Icons.speed_rounded},
    {'name': 'SUV', 'sw': 'SUV', 'icon': Icons.terrain_rounded},
    {'name': 'Bus', 'sw': 'Bus/Costa', 'icon': Icons.directions_bus_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_pageController.hasClients && _bannerCount > 0) {
        if (_currentPage < _bannerCount - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _getGreeting(LanguageProvider lang) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return lang.translate('Good Morning', 'Habari za Asubuhi');
    } else if (hour >= 12 && hour < 17) {
      return lang.translate('Good Afternoon', 'Habari za Mchana');
    } else if (hour >= 17 && hour < 21) {
      return lang.translate('Good Evening', 'Habari za Jioni');
    } else {
      return lang.translate('Good Night', 'Habari za Usiku');
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return Icons.wb_sunny_outlined;
    if (hour >= 12 && hour < 17) return Icons.wb_sunny;
    if (hour >= 17 && hour < 21) return Icons.wb_twilight;
    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildDrawer(context, userProvider, lang),
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipPath(
                clipper: HeaderClipper(),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1D275F), Color(0xFF003399)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white60, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Dar es Salaam, TZ', style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(_getGreetingIcon(), color: Colors.orangeAccent.withOpacity(0.8), size: 16),
                                  const SizedBox(width: 6),
                                  Text('${_getGreeting(lang)}, ${userProvider.name.split(' ')[0]}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1.5)),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white12,
                          backgroundImage: userProvider.imagePath != null
                              ? (userProvider.imagePath!.startsWith('http')
                                  ? NetworkImage(userProvider.imagePath!)
                                  : (!kIsWeb ? FileImage(File(userProvider.imagePath!)) : const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png')) as ImageProvider)
                              : const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -25, left: 25, right: 25,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, 
                    borderRadius: BorderRadius.circular(18), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))]
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: lang.translate('Find the best car for you...', 'Tafuta gari bora kwako...'),
                      hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF003399), size: 24),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 45),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.translate('Exclusive Offers', 'Ofa za Kipekee'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1D275F))),
                        Text('${_currentPage + 1}/$_bannerCount', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  SizedBox(
                    height: 170,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          _bannerCount = 2;
                          return _buildDefaultBanners();
                        }
                        
                        final banners = snapshot.data!.docs;
                        _bannerCount = banners.length;
                        return PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentPage = index),
                          itemCount: banners.length,
                          itemBuilder: (context, index) {
                            var bData = banners[index].data() as Map<String, dynamic>;
                            return _buildBannerCard(bData['title'] ?? '', bData['subtitle'] ?? '', bData['image'] ?? '', bData['offer'] ?? '');
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 95,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _categories.length,
                      itemBuilder: (ctx, i) {
                        bool isSelected = _selectedCategory == _categories[i]['name'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = _categories[i]['name']),
                          child: Container(
                            width: 75,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF003399) : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF003399).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))] : null,
                                  ),
                                  child: Icon(_categories[i]['icon'], color: isSelected ? Colors.white : Colors.blueGrey),
                                ),
                                const SizedBox(height: 8),
                                Text(lang.translate(_categories[i]['name'], _categories[i]['sw']), style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF003399) : Colors.blueGrey), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 15),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang.translate('Popular Choice', 'Chaguo Maarufu'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1D275F))),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const CarsScreen(type: 'all'))),
                          child: Row(
                            children: [
                              Text(lang.translate('View All', 'Ona Zote'), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.blueAccent),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('cars').limit(10).snapshots(),
                    builder: (context, snapshot) {
                      List<Car> cars = [];
                      if (snapshot.hasData) {
                        cars = snapshot.data!.docs.map((doc) => Car.fromFirestore(doc)).toList();
                      }
                      
                      if (_searchQuery.isNotEmpty) {
                        cars = cars.where((c) => c.brand.toLowerCase().contains(_searchQuery.toLowerCase()) || c.model.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                      } else if (_selectedCategory != 'All') {
                        cars = cars.where((c) => c.category.name.toLowerCase() == _selectedCategory.toLowerCase()).toList();
                      }

                      if (cars.isEmpty && _searchQuery.isEmpty && _selectedCategory == 'All') {
                        cars = dummyCars.take(4).toList();
                      }

                      if (cars.isEmpty) {
                        return Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Text(lang.translate('No cars available', 'Hakuna magari yaliyopo'))));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 40),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 18, childAspectRatio: 0.72),
                        itemCount: cars.length,
                        itemBuilder: (ctx, i) => _buildModernCarCard(cars[i], lang),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, UserProvider userProvider, LanguageProvider lang) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userProvider.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(userProvider.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: userProvider.imagePath != null
                  ? (userProvider.imagePath!.startsWith('http')
                      ? NetworkImage(userProvider.imagePath!)
                      : (!kIsWeb ? FileImage(File(userProvider.imagePath!)) : const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png')) as ImageProvider)
                  : const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
            ),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1D275F), Color(0xFF003399)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF1D275F)),
            title: Text(lang.translate('My Profile', 'Profaili Yangu')),
            onTap: () { 
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: Icon(themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined, color: const Color(0xFF1D275F)),
            title: Text(themeProvider.isDarkMode ? lang.translate('Light Mode', 'Njia ya Mwanga') : lang.translate('Dark Mode', 'Njia ya Giza')),
            trailing: Switch(value: themeProvider.isDarkMode, onChanged: (val) => themeProvider.toggleTheme()),
            onTap: () => themeProvider.toggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF1D275F)),
            title: Text(lang.translate('Language', 'Lugha')),
            onTap: () { Navigator.pop(context); _showLanguageDialog(context); },
          ),
          const Divider(),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(lang.translate('Logout', 'Toka'), style: const TextStyle(color: Colors.redAccent)),
            onTap: () => _handleLogout(context, lang),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate('Logout', 'Toka')),
        content: Text(lang.translate('Are you sure you want to logout?', 'Je, una uhakika unataka kutoka?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('Cancel', 'Ghairi'))),
          ElevatedButton(onPressed: () async { await FirebaseAuth.instance.signOut(); if (!mounted) return; Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (ctx) => const AuthScreen()), (route) => false); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: Text(lang.translate('Logout', 'Toka'), style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(langProvider.translate('Select Language', 'Chagua Lugha')), content: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(title: const Text('English'), onTap: () { langProvider.setLanguage('en'); Navigator.pop(ctx); }), ListTile(title: const Text('Kiswahili'), onTap: () { langProvider.setLanguage('sw'); Navigator.pop(ctx); })])));
  }

  Widget _buildBannerCard(String title, String subtitle, String image, String offer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            image.isNotEmpty 
                ? (image.startsWith('http') 
                    ? Image.network(image, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.blueGrey, child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white70))))
                    : Image.asset(image, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.blueGrey, child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white70))))) 
                : Container(color: Colors.blueGrey),
            Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.85), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (offer.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)), child: Text(offer, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9))),
                  const SizedBox(height: 6),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBanners() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      children: [
        _buildBannerCard('Wildlife Safari', 'Explore Tanzania like a pro', 'assets/poster2.png', '35% OFF'),
        _buildBannerCard('VIP Airport Transfer', 'Travel in style and comfort', 'assets/poster3.png', '20% OFF'),
      ],
    );
  }

  Widget _buildModernCarCard(Car car, LanguageProvider lang) {
    final currencyFormat = NumberFormat.decimalPattern();
    bool isUnavailable = car.status == 'unavailable';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(22), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => CarDetailScreen(car: car))),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(8), 
                    width: double.infinity, 
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF1F4F9), 
                      borderRadius: BorderRadius.circular(18)
                    ), 
                    child: Padding(
                      padding: const EdgeInsets.all(12), 
                      child: Hero(
                        tag: car.id, 
                        child: car.imageUrl.startsWith('http')
                          ? Image.network(car.imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.car_rental, color: Colors.blueGrey))
                          : Image.asset(car.imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.car_rental, color: Colors.blueGrey))
                      )
                    )
                  ),
                  Positioned(top: 15, right: 15, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, color: Colors.orange, size: 10), const SizedBox(width: 3), Text(car.rating.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black))]))),
                  if (isUnavailable)
                    Positioned(
                      bottom: 15, left: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                        child: Text(lang.translate('Unavailable', 'Haipatikani'), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 2, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.brand, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(car.model, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF1D275F)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(lang.translate('Per Day', 'Kwa Siku'), style: const TextStyle(color: Colors.grey, fontSize: 9)), Text('${currencyFormat.format(car.pricePerDay)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF003399)))])),
                      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF1D275F), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white)),
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
}
