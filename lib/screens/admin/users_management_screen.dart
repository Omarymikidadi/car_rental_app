import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'driver_activities_screen.dart';
import 'send_notification_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  final int initialIndex;
  const UsersManagementScreen({super.key, this.initialIndex = 0});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D275F), size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: lang.translate('Search by name or email...', 'Tafuta kwa jina au barua pepe...'),
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              style: const TextStyle(fontSize: 16, color: Color(0xFF1D275F)),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            )
          : Text(lang.translate('User & Driver Management', 'Usimamizi wa Watumiaji'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D275F))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: const Color(0xFF1D275F)),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(lang.translate('No users found', 'Hakuna watumiaji bado')));
          }

          final allDocs = snapshot.data!.docs;

          List<Map<String, dynamic>> usersDataList = [];
          for (var doc in allDocs) {
            final Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
            data['id'] = doc.id;
            
            // Apply Search Filter
            final String name = (data['name'] ?? '').toString().toLowerCase();
            final String email = (data['email'] ?? '').toString().toLowerCase();
            
            if (_searchQuery.isEmpty || name.contains(_searchQuery) || email.contains(_searchQuery)) {
              usersDataList.add(data);
            }
          }

          usersDataList.sort((a, b) {
            final Timestamp? t1 = a['createdAt'] as Timestamp?;
            final Timestamp? t2 = b['createdAt'] as Timestamp?;
            if (t1 == null) return 1;
            if (t2 == null) return -1;
            return t2.compareTo(t1);
          });
          
          final drivers = usersDataList.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'driver').toList();
          final customers = usersDataList.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'customer').toList();
          final owners = usersDataList.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'owner').toList();

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1D275F),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1D275F),
                isScrollable: true,
                tabs: [
                  Tab(text: '${lang.translate('Drivers', 'Madereva')} (${drivers.length})'),
                  Tab(text: '${lang.translate('Owners', 'Wamiliki')} (${owners.length})'),
                  Tab(text: '${lang.translate('Customers', 'Wateja')} (${customers.length})'),
                  Tab(text: '${lang.translate('All', 'Wote')} (${usersDataList.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(drivers, lang),
                    _buildList(owners, lang),
                    _buildList(customers, lang),
                    _buildList(usersDataList, lang),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> users, LanguageProvider lang) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(lang.translate('No users match your search', 'Hakuna mtumiaji anayelingana na utafutaji wako')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      itemBuilder: (ctx, index) {
        final userData = users[index];
        final String userId = userData['id'] ?? '';
        final String role = (userData['role'] ?? '').toString().toLowerCase();
        final String status = (userData['status'] ?? 'active').toString().toLowerCase();
        final String? imageUrl = userData['profileImage'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: status == 'active' ? Colors.blue.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
              child: (imageUrl == null || imageUrl.isEmpty) ? Icon(role == 'driver' ? Icons.drive_eta : (role == 'owner' ? Icons.business : Icons.person)) : null,
            ),
            title: Row(
              children: [
                Expanded(child: Text(userData['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold))),
                _buildStatusBadge(status, lang),
              ],
            ),
            subtitle: Text(userData['email'] ?? ''),
            trailing: const Icon(Icons.more_vert),
            onTap: () => _showUserActions(context, userId, userData, lang),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, LanguageProvider lang) {
    final bool isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isActive ? lang.translate('Active', 'Hai') : lang.translate('Suspended', 'Amesimamishwa'),
        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showUserActions(BuildContext context, String userId, Map<String, dynamic> userData, LanguageProvider lang) {
    final String currentStatus = (userData['status'] ?? 'active').toString().toLowerCase();
    final bool isActive = currentStatus == 'active';
    final String role = (userData['role'] ?? '').toString().toLowerCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(userData['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 5),
            Text(userData['email'] ?? '', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            if (role == 'driver') ...[
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: Text(lang.translate('View Activities', 'Angalia Shughuli')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => DriverActivitiesScreen(driverId: userId, driverName: userData['name'] ?? 'Driver')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.message_outlined, color: Colors.teal),
                title: Text(lang.translate('Send Message', 'Tuma Ujumbe')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => SendNotificationScreen(targetDriverId: userId, targetDriverName: userData['name'])));
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.indigo),
                title: Text(lang.translate('Assign to Car', 'Pangia Gari')),
                onTap: () {
                  Navigator.pop(context);
                  _showAssignCarDialog(userId, userData, lang);
                },
              ),
            ],
            ListTile(
              leading: Icon(isActive ? Icons.block : Icons.check_circle, color: isActive ? Colors.orange : Colors.green),
              title: Text(isActive ? lang.translate('Suspend Account', 'Simamisha Akaunti') : lang.translate('Activate Account', 'Washa Akaunti')),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'status': isActive ? 'inactive' : 'active'
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(lang.translate('Delete Account', 'Futa Akaunti')),
              onTap: () async {
                Navigator.pop(context);
                _confirmDelete(context, userId, lang);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignCarDialog(String driverId, Map<String, dynamic> driverData, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${lang.translate('Assign Car to', 'Pangia Gari kwa')}: ${driverData['name']}'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('cars').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final cars = snapshot.data!.docs;
              if (cars.isEmpty) return Text(lang.translate('No cars found', 'Hakuna magari yaliyopatikana'));

              return ListView.builder(
                shrinkWrap: true,
                itemCount: cars.length,
                itemBuilder: (ctx, index) {
                  final carData = cars[index].data() as Map<String, dynamic>? ?? {};
                  return ListTile(
                    title: Text('${carData['brand'] ?? ''} ${carData['model'] ?? ''}'),
                    subtitle: Text(carData['vendorName'] ?? ''),
                    onTap: () async {
                      Navigator.pop(ctx);
                      
                      // Handle single assignment logic
                      final existingAssignments = await FirebaseFirestore.instance
                          .collection('cars')
                          .where('driverId', isEqualTo: driverId)
                          .get();

                      WriteBatch batch = FirebaseFirestore.instance.batch();

                      for (var doc in existingAssignments.docs) {
                        batch.update(doc.reference, {
                          'driverId': null,
                          'driverName': null,
                          'driverPhone': null,
                          'driverAge': null,
                          'driverImage': null,
                        });
                      }

                      batch.update(FirebaseFirestore.instance.collection('cars').doc(cars[index].id), {
                        'driverId': driverId,
                        'driverName': driverData['name'] ?? '',
                        'driverPhone': driverData['phone'] ?? '',
                        'driverAge': driverData['age'] ?? 0,
                        'driverImage': driverData['profileImage'] ?? 'assets/app_icon.png',
                      });

                      await batch.commit();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.translate('Car assigned successfully', 'Gari limepangwa kikamilifu')), backgroundColor: Colors.green));
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('Cancel', 'Ghairi'))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String userId, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate('Delete User?', 'Futa Mtumiaji?')),
        content: Text(lang.translate('Are you sure you want to delete this user?', 'Je, una uhakika unataka kufuta mtumiaji huyu?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(lang.translate('Cancel', 'Ghairi'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('users').doc(userId).delete();
            },
            child: Text(lang.translate('Delete', 'Futa'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
