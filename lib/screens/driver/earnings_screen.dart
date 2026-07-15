import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currencyFormat = NumberFormat.decimalPattern();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF001F54), size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(lang.translate('Monthly Earnings', 'Mapato ya Mwezi'), 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF001F54))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF001F54),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: const Color(0xFF001F54).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Text(lang.translate('Total Monthly Balance', 'Jumla ya Mapato ya Mwezi'), 
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  Text('TZS ${currencyFormat.format(userProvider.monthlyEarnings)}', 
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(lang.translate('Earnings Summary', 'Muhtasari wa Mapato'), 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F54))),
            const SizedBox(height: 15),
            _buildStatCard(lang.translate('Today', 'Leo'), 'TZS ${currencyFormat.format(userProvider.todayEarnings)}', Icons.today, Colors.green),
            const SizedBox(height: 15),
            _buildStatCard(lang.translate('This Month', 'Mwezi Huu'), 'TZS ${currencyFormat.format(userProvider.monthlyEarnings)}', Icons.calendar_month, Colors.blue),
            const SizedBox(height: 15),
            _buildStatCard(lang.translate('Total Lifetime', 'Jumla Kuu'), 'TZS ${currencyFormat.format(userProvider.totalEarnings)}', Icons.account_balance_wallet, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F54))),
            ],
          ),
        ],
      ),
    );
  }
}
