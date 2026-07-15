import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car.dart';
import 'package:intl/intl.dart';
import 'payment_screen.dart';
import 'car_detail_screen.dart';
import '../providers/language_provider.dart';
import 'dart:math' show cos, sqrt, asin, pi;

class BookingScreen extends StatefulWidget {
  final Car car;
  final String? initialName;
  final String? initialPhone;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const BookingScreen({
    super.key,
    required this.car,
    this.initialName,
    this.initialPhone,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  String? _selectedPickUpStation;
  bool _isWithinDar = true;
  String? _selectedDropOffRegion;
  String? _selectedDropOffStation;
  bool _isLoadingAvailability = false;

  final Map<String, Map<String, double>> _locationCoords = {
    // --- DAR ES SALAAM COMPREHENSIVE LOCATIONS ---
    'Julius Nyerere Airport (JNIA)': {'lat': -6.8781, 'lng': 39.2026},
    'Mbezi Luis (Magufuli Terminal)': {'lat': -6.7686, 'lng': 39.1102},
    'Ubungo (Maziwa/Terminal)': {'lat': -6.7820, 'lng': 39.2155},
    'Kariakoo Market': {'lat': -6.8228, 'lng': 39.2749},
    'Posta / City Center': {'lat': -6.8161, 'lng': 39.2895},
    'Mwenge Bus Stand': {'lat': -6.7725, 'lng': 39.2272},
    'Morocco (Kinondoni)': {'lat': -6.7844, 'lng': 39.2631},
    'Sinza (Mori/Afrikana)': {'lat': -6.7797, 'lng': 39.2201},
    'Masaki / Slipway': {'lat': -6.7497, 'lng': 39.2743},
    'Oysterbay / Palm Village': {'lat': -6.7722, 'lng': 39.2861},
    'Mbezi Beach (Jogoo)': {'lat': -6.7025, 'lng': 39.2275},
    'Tegeta (Nyuki/Wazo)': {'lat': -6.6749, 'lng': 39.2150},
    'Bunju A / B': {'lat': -6.6197, 'lng': 39.1417},
    'Boko / Ununio Junction': {'lat': -6.6472, 'lng': 39.1844},
    'Kunduchi / Mtongani': {'lat': -6.6781, 'lng': 39.2241},
    'Kawe / Mbezi Garden': {'lat': -6.7381, 'lng': 39.2391},
    'Mikocheni (A/B)': {'lat': -6.7611, 'lng': 39.2522},
    'Kinondoni (Manyanya)': {'lat': -6.7912, 'lng': 39.2655},
    'Magomeni (Mapipa/Kanisani)': {'lat': -6.8041, 'lng': 39.2591},
    'Manzese (Tip Top)': {'lat': -6.7936, 'lng': 39.2312},
    'Kimara (Mwisho/Stop Over)': {'lat': -6.7829, 'lng': 39.1764},
    'Kimara Korogwe': {'lat': -6.7850, 'lng': 39.1850},
    'Kimara Temboni': {'lat': -6.7880, 'lng': 39.1950},
    'Tabata (Bima/Mawenzi)': {'lat': -6.8322, 'lng': 39.2132},
    'Tabata Segerea': {'lat': -6.8451, 'lng': 39.1822},
    'Tabata Kimanga': {'lat': -6.8400, 'lng': 39.2000},
    'Tabata Dampo': {'lat': -6.8250, 'lng': 39.2200},
    'Kinyerezi': {'lat': -6.8581, 'lng': 39.1511},
    'Gongo la Mboto': {'lat': -6.8973, 'lng': 39.1554},
    'Ukonga Banana': {'lat': -6.8850, 'lng': 39.1750},
    'Ukonga Mombasa': {'lat': -6.8900, 'lng': 39.1650},
    'Jet Lumo': {'lat': -6.8750, 'lng': 39.1850},
    'Pugu / Chanika': {'lat': -7.0081, 'lng': 39.0511},
    'Mbagala (Zakhem/Rangi Tatu)': {'lat': -6.9031, 'lng': 39.2676},
    'Mbagala Kiburugwa': {'lat': -6.8950, 'lng': 39.2550},
    'Mbagala Charambe': {'lat': -6.9150, 'lng': 39.2450},
    'Temeke (Mwisho/Hospitali)': {'lat': -6.8521, 'lng': 39.2682},
    'Tandika Market': {'lat': -6.8611, 'lng': 39.2555},
    'Buza / Yombo': {'lat': -6.8821, 'lng': 39.2411},
    'Kigamboni (Ferry)': {'lat': -6.8276, 'lng': 39.3005},
    'Kigamboni Kibada': {'lat': -6.8600, 'lng': 39.3200},
    'Kigamboni Gezaulole': {'lat': -6.8800, 'lng': 39.3400},
    'Kurasini / Shimo la Udongo': {'lat': -6.8450, 'lng': 39.2850},
    'Dar es Salaam Port': {'lat': -6.8183, 'lng': 39.2961},
    'Tazara Station': {'lat': -6.8291, 'lng': 39.2435},
    'Upanga East / West': {'lat': -6.8050, 'lng': 39.2800},
    'Buguruni (Chama/Rozana)': {'lat': -6.8250, 'lng': 39.2500},
    'Vingunguti / Kombo': {'lat': -6.8400, 'lng': 39.2300},
    'Kivukoni Fish Market': {'lat': -6.8180, 'lng': 39.3010},
    'Kijitonyama (Sayansi)': {'lat': -6.7750, 'lng': 39.2450},
    'Mwananyamala Hospital': {'lat': -6.7900, 'lng': 39.2550},
    'Msasani Village': {'lat': -6.7550, 'lng': 39.2650},
    'Mbezi Beach Afrikana': {'lat': -6.7150, 'lng': 39.2250},
    'Mbezi Beach Tangi Bovu': {'lat': -6.7250, 'lng': 39.2350},
    'Salasala': {'lat': -6.6850, 'lng': 39.1850},
    'Goba Center': {'lat': -6.7350, 'lng': 39.1550},
    'Madale': {'lat': -6.6550, 'lng': 39.1250},
    'Mivumoni': {'lat': -6.6950, 'lng': 39.1650},
    'Kibamba / Kiluvya': {'lat': -6.7650, 'lng': 39.0550},
    'Ilala Boma': {'lat': -6.8200, 'lng': 39.2700},
    'Mnazi Mmoja': {'lat': -6.8190, 'lng': 39.2850},
    'Tandale kwa Mtogole': {'lat': -6.7950, 'lng': 39.2450},

    // --- UPCOUNTRY REGIONS ---
    'Arusha': {'lat': -3.3731, 'lng': 36.6830},
    'Dodoma': {'lat': -6.1722, 'lng': 35.7516},
    'Mwanza': {'lat': -2.5164, 'lng': 32.9175},
    'Mbeya': {'lat': -8.9094, 'lng': 33.4608},
    'Morogoro': {'lat': -6.8278, 'lng': 37.6591},
    'Tanga': {'lat': -5.0689, 'lng': 39.1023},
    'Kigoma': {'lat': -4.8769, 'lng': 29.6414},
    'Iringa': {'lat': -7.7731, 'lng': 35.6991},
    'Mtwara': {'lat': -10.2744, 'lng': 40.1833},
    'Lindi': {'lat': -9.9961, 'lng': 39.7144},
    'Shinyanga': {'lat': -3.6619, 'lng': 33.4230},
    'Tabora': {'lat': -5.0162, 'lng': 32.8132},
    'Singida': {'lat': -4.8153, 'lng': 34.7436},
    'Kilimanjaro': {'lat': -3.3144, 'lng': 37.3333},
    'Pwani': {'lat': -7.1517, 'lng': 38.9822},
    'Unguja (Zanzibar)': {'lat': -6.1659, 'lng': 39.2026},
    'Pemba': {'lat': -5.2091, 'lng': 39.7633},
    'Kagera': {'lat': -1.3323, 'lng': 31.8123},
    'Mara': {'lat': -1.6167, 'lng': 34.0000},
    'Geita': {'lat': -2.8711, 'lng': 32.2285},
    'Katavi': {'lat': -6.3575, 'lng': 31.2952},
    'Njombe': {'lat': -9.3370, 'lng': 34.7686},
    'Ruvuma': {'lat': -10.6811, 'lng': 35.6544},
    'Simiyu': {'lat': -2.8431, 'lng': 33.9189},
    'Songwe': {'lat': -8.8471, 'lng': 32.7483},
    'Rukwa': {'lat': -7.2185, 'lng': 31.4241},
    'Manyara': {'lat': -4.3151, 'lng': 36.3333},
  };

  final _distanceController = TextEditingController(text: '0'); 
  final NumberFormat _currencyFormat = NumberFormat.decimalPattern();
  final double _pricePerKm = 500.0;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  double _calculateDistanceFormula(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _updateCalculatedDistance() {
    if (_selectedPickUpStation == null) return;
    String? destKey = _isWithinDar ? _selectedDropOffStation : _selectedDropOffRegion;
    if (destKey == null) return;

    // Fixed: If locations are the same, distance is 0.0 KM
    if (_selectedPickUpStation == destKey) {
      setState(() => _distanceController.text = '0.0');
      return;
    }

    var start = _locationCoords[_selectedPickUpStation];
    var end = _locationCoords[destKey];
    if (start != null && end != null) {
      double rawKm = _calculateDistanceFormula(start['lat']!, start['lng']!, end['lat']!, end['lng']!);
      double factor = _isWithinDar ? 1.4 : 1.25; 
      double finalKm = rawKm * factor;
      if (finalKm < 5) finalKm = 5.0;
      setState(() => _distanceController.text = finalKm.toStringAsFixed(1));
    }
  }

  int get _rentalDays {
    if (_startDate == null || _endDate == null) return 0;
    final diff = _endDate!.difference(_startDate!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  double get _distance => double.tryParse(_distanceController.text) ?? 0.0;

  double get _totalPrice {
    double basePrice = _rentalDays * widget.car.pricePerDay;
    double distancePrice = _distance * _pricePerKm;
    if (!_isWithinDar) distancePrice += 50000; 
    return basePrice + distancePrice;
  }

  bool _isRegion(String name) {
    return ['Arusha', 'Dodoma', 'Mwanza', 'Mbeya', 'Morogoro', 'Tanga', 'Kigoma', 'Iringa', 'Mtwara', 'Lindi', 'Shinyanga', 'Tabora', 'Singida', 'Kilimanjaro', 'Pwani', 'Unguja (Zanzibar)', 'Pemba', 'Kagera', 'Mara', 'Geita', 'Katavi', 'Njombe', 'Ruvuma', 'Simiyu', 'Songwe', 'Rukwa', 'Manyara'].contains(name);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    final darLocations = _locationCoords.keys.where((k) => !_isRegion(k)).toList()..sort();
    final upcountryRegions = _locationCoords.keys.where((k) => _isRegion(k)).toList()..sort();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(lang.translate('Booking Details', 'Maelezo ya Uhifadhi'), 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
        backgroundColor: Colors.white, 
        elevation: 0, 
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: lang.translate('Personal Information', 'Taarifa Binafsi'),
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(lang.translate('Full Name', 'Jina Kamili'), Icons.person_outline),
                      validator: (v) => v!.isEmpty ? lang.translate('Please enter your name', 'Tafadhali jaza jina lako') : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration(lang.translate('Phone Number', 'Namba ya Simu'), Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? lang.translate('Please enter your phone number', 'Tafadhali jaza namba ya simu') : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildSectionCard(
                title: lang.translate('Trip Information', 'Taarifa za Safari'),
                icon: Icons.route_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedPickUpStation,
                      decoration: _inputDecoration(lang.translate('Pick Up Location', 'Eneo la Kuchukuliwa'), Icons.location_on_outlined, color: Colors.green),
                      items: darLocations.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) { setState(() => _selectedPickUpStation = val); _updateCalculatedDistance(); },
                      validator: (val) => val == null ? lang.translate('Select pick up location', 'Chagua eneo la kuchukuliwa') : null,
                      selectedItemBuilder: (context) {
                        return darLocations.map((s) => Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)).toList();
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceChip(
                            label: lang.translate('Within Dar', 'Ndani ya Dar'),
                            isSelected: _isWithinDar,
                            onTap: () { setState(() { _isWithinDar = true; _selectedDropOffRegion = null; }); _updateCalculatedDistance(); }
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildChoiceChip(
                            label: lang.translate('Upcountry', 'Mikoani'),
                            isSelected: !_isWithinDar,
                            onTap: () { setState(() { _isWithinDar = false; _selectedDropOffStation = null; }); _updateCalculatedDistance(); }
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (_isWithinDar)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedDropOffStation,
                        decoration: _inputDecoration(lang.translate('Drop Off (Dar)', 'Eneo la Kushukia (Dar)'), Icons.location_searching, color: Colors.redAccent),
                        items: darLocations.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) { setState(() => _selectedDropOffStation = val); _updateCalculatedDistance(); },
                        validator: (val) => _isWithinDar && val == null ? lang.translate('Select drop off location', 'Chagua eneo la kushukia') : null,
                        selectedItemBuilder: (context) {
                          return darLocations.map((s) => Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)).toList();
                        },
                      )
                    else
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedDropOffRegion,
                        decoration: _inputDecoration(lang.translate('Destination Region', 'Mkoa Unaoenda'), Icons.map_outlined, color: Colors.blue),
                        items: upcountryRegions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) { setState(() => _selectedDropOffRegion = val); _updateCalculatedDistance(); },
                        validator: (val) => !_isWithinDar && val == null ? lang.translate('Select destination region', 'Chagua mkoa unaoenda') : null,
                        selectedItemBuilder: (context) {
                          return upcountryRegions.map((s) => Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)).toList();
                        },
                      ),
                    
                    if (_distance >= 0 && _selectedPickUpStation != null && (_selectedDropOffStation != null || _selectedDropOffRegion != null)) ...[
                      const SizedBox(height: 25),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.navigation_outlined, color: Colors.blueAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    lang.translate('Total Distance', 'Umbali wa Safari'),
                                    style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_distance.toStringAsFixed(1)} KM',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => _selectDateRange(context),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(18), 
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor, 
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ), 
                        child: Row(children: [
                          const Icon(Icons.calendar_today_outlined, color: Colors.blueAccent, size: 20), 
                          const SizedBox(width: 12), 
                          Text(
                            _startDate == null 
                              ? lang.translate('Select Dates', 'Chagua Tarehe') 
                              : '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _startDate == null ? Colors.grey : null),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ])
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _buildSectionCard(
                title: lang.translate('Vehicle Driver', 'Dereva wa Gari'),
                icon: Icons.verified_user_outlined,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30, 
                        backgroundImage: widget.car.driverImage.startsWith('http') 
                            ? NetworkImage(widget.car.driverImage) as ImageProvider
                            : AssetImage(widget.car.driverImage),
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.car.driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(
                              '${lang.translate('Age', 'Umri')}: ${widget.car.driverAge} | ${lang.translate('Phone', 'Simu')}: ${widget.car.driverPhone}', 
                              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_rounded, color: Colors.blue, size: 24),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003399), Color(0xFF002266)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF003399).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(children: [
                  _buildPriceRow('${lang.translate('Car Rental', 'Kukodisha Gari')} (${_rentalDays} ${lang.translate('days', 'siku')})', '${_currencyFormat.format(_rentalDays * widget.car.pricePerDay)} Tsh'),
                  _buildPriceRow('${lang.translate('Distance Fee', 'Ada ya Umbali')} (${_distance.toStringAsFixed(1)} KM)', '${_currencyFormat.format(_distance * _pricePerKm)} Tsh'),
                  if (!_isWithinDar) _buildPriceRow(lang.translate('Upcountry Fee', 'Ada ya Mkoani'), '50,000 Tsh'),
                  const Divider(color: Colors.white24, height: 30),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(lang.translate('Total Amount', 'Jumla ya Malipo'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)), 
                    Text('${_currencyFormat.format(_totalPrice)} Tsh', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
                  ]),
                ]),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity, 
                height: 65, 
                child: ElevatedButton(
                  onPressed: _isLoadingAvailability ? null : _confirmBooking, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ), 
                  child: _isLoadingAvailability 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(lang.translate('Confirm & Proceed to Payment', 'Thibitisha na Lipia'), 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                )
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Color? color}) {
    return InputDecoration(
      labelText: label, 
      labelStyle: const TextStyle(fontSize: 14, color: Colors.blueGrey),
      filled: true, 
      fillColor: Theme.of(context).cardColor, 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), 
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
      prefixIcon: Icon(icon, color: color ?? Colors.blueAccent, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1D275F), size: 22),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.withOpacity(0.1)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueGrey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)), 
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
        ]
      )
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context, 
      firstDate: DateTime.now(), 
      lastDate: DateTime.now().add(const Duration(days: 365)), 
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() { _startDate = picked.start; _endDate = picked.end; });
  }

  Future<void> _confirmBooking() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.translate('Please select trip dates', 'Tafadhali chagua tarehe za safari')))
        );
      }
      return;
    }

    String dropoff = _isWithinDar ? (_selectedDropOffStation ?? '') : (_selectedDropOffRegion ?? '');
    if (_selectedPickUpStation == null || dropoff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.translate('Please select trip locations first', 'Tafadhali chagua maeneo ya safari kwanza')))
      );
      return;
    }

    setState(() => _isLoadingAvailability = true);

    try {
      final overlapBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('carId', isEqualTo: widget.car.id)
          .get(const GetOptions(source: Source.server));

      final existingBooking = overlapBookings.docs.where((doc) {
        final data = doc.data();
        if (data['status'] == 'cancelled') return false;
        final bStart = (data['startDate'] as Timestamp).toDate();
        final bEnd = (data['endDate'] as Timestamp).toDate();
        return _startDate!.isBefore(bEnd) && _endDate!.isAfter(bStart);
      }).toList();

      if (existingBooking.isNotEmpty) {
        setState(() => _isLoadingAvailability = false);
        final firstMatch = existingBooking.first.data();
        final returnDate = (firstMatch['endDate'] as Timestamp).toDate();
        _showAlternativeSuggestions(returnDate);
        return;
      }

      setState(() => _isLoadingAvailability = false);
      
      if (!mounted) return;
      
      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => PaymentScreen(
        car: widget.car, 
        amount: _totalPrice,
        startDate: _startDate!,
        endDate: _endDate!,
        pickupLocation: _selectedPickUpStation ?? '',
        dropoffLocation: dropoff,
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        distance: _distance,
      )));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAvailability = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu imetokea: $e'), backgroundColor: Colors.redAccent)
      );
    }
  }

  void _showAlternativeSuggestions(DateTime returnDate) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Icon(Icons.event_busy_rounded, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 15),
                  Text(
                    lang.translate('Vehicle Already Booked', 'Gari limeshakodishwa'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lang.translate(
                      'This car is booked for your selected dates. It will be returned on ${DateFormat('dd MMM yyyy').format(returnDate)}.',
                      'Gari hili limekodishwa kwa tarehe ulizochagua. Litarudi tarehe ${DateFormat('dd MMM yyyy').format(returnDate)}.'
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    lang.translate('Alternative Suggestions', 'Magari Mengine Unayoweza Kuchagua'),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.titleLarge?.color),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('cars')
                    .where('category', isEqualTo: widget.car.category.index)
                    .limit(10)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final alternatives = (snapshot.data?.docs ?? [])
                      .map((doc) => Car.fromFirestore(doc))
                      .where((c) => c.id != widget.car.id)
                      .toList();

                  if (alternatives.isEmpty) {
                    return Center(child: Text(lang.translate('No alternatives found', 'Hakuna magari mengine yanayofanana kwa sasa')));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: alternatives.length,
                    itemBuilder: (ctx, idx) {
                      final altCar = alternatives[idx];
                      return _buildAlternativeCard(altCar, lang);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(lang.translate('Change Dates', 'Badili Tarehe za Safari'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); 
                        Navigator.pop(context); 
                        Navigator.pop(context); 
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(lang.translate('Select Another Car', 'Chagua Gari Lingine'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeCard(Car altCar, LanguageProvider lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: altCar.imageUrl.startsWith('http') 
                ? Image.network(altCar.imageUrl, width: 100, height: 80, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.car_rental))
                : Image.asset(altCar.imageUrl, width: 100, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.car_rental)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${altCar.brand} ${altCar.model}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${_currencyFormat.format(altCar.pricePerDay)} Tsh / day', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${altCar.seats} Seats', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 12),
                    const Icon(Icons.settings_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(altCar.transmission.name, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (ctx) => BookingScreen(
                  car: altCar,
                  initialName: _nameController.text,
                  initialPhone: _phoneController.text,
                  initialStartDate: _startDate,
                  initialEndDate: _endDate,
                ),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            child: Text(lang.translate('Select', 'Chagua')),
          ),
        ],
      ),
    );
  }
}
