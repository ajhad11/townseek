import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SecurityMonitorScreen extends StatefulWidget {
  const SecurityMonitorScreen({super.key});

  @override
  State<SecurityMonitorScreen> createState() => _SecurityMonitorScreenState();
}

class _SecurityMonitorScreenState extends State<SecurityMonitorScreen> {
  late Future<List<Map<String, dynamic>>> _adminLogsFuture;
  late Future<List<Map<String, dynamic>>> _loginLogsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    final service = Provider.of<SupabaseService>(context, listen: false);
    setState(() {
      _adminLogsFuture = service.getAdminSecurityLogs();
      _loginLogsFuture = service.getProfileLoginLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Monitor',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
              ),
              Text(
                'Monitor administrative actions and user login patterns',
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _refreshLogs,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2962FF)),
              tooltip: 'Refresh Logs',
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF2962FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2962FF),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Admin Access Logs'),
              Tab(text: 'User Login Logs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLogList(_adminLogsFuture, isMobile, 'admin'),
            _buildLogList(_loginLogsFuture, isMobile, 'user'),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList(Future<List<Map<String, dynamic>>> future, bool isMobile, String type) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: _refreshLogs,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security_rounded, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No security logs found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                const Text('New activities will appear here.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalyticsDashboard(logs, isMobile),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2962FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${logs.length} Recent entries',
                      style: const TextStyle(color: Color(0xFF2962FF), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey[100]),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogItem(log, type, isMobile);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsDashboard(List<Map<String, dynamic>> logs, bool isMobile) {
    // 1. Calculate Success vs Failure
    int successCount = 0;
    int failureCount = 0;
    for (var log in logs) {
      final status = (log['status'] ?? 'success').toString().toLowerCase();
      if (status == 'success' || status == 'verified') {
        successCount++;
      } else {
        failureCount++;
      }
    }

    // 2. Mock trend data based on logs (logs per grouping or just spread)
    final List<FlSpot> trendSpots = [];
    // We reverse logs to show trend leading to latest
    final sortedLogs = List.from(logs.reversed.toList());
    for (int i = 0; i < sortedLogs.length && i < 10; i++) {
        trendSpots.add(FlSpot(i.toDouble(), 1 + (i % 3).toDouble() + (successCount / 10)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isMobile) {
          return Column(
            children: [
              _buildChartCard('Success Ratio', _buildPieChart(successCount, failureCount), height: 250),
              const SizedBox(height: 16),
              _buildChartCard('Security Trends', _buildLineChart(trendSpots), height: 250),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildChartCard('Access Distribution', _buildPieChart(successCount, failureCount))),
            const SizedBox(width: 24),
            Expanded(child: _buildChartCard('Activity Frequency', _buildLineChart(trendSpots))),
          ],
        );
      }
    );
  }

  Widget _buildChartCard(String title, Widget chart, {double height = 300}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildPieChart(int success, int failure) {
    if (success == 0 && failure == 0) return const Center(child: Text('No Data'));
    
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: success.toDouble(),
            title: 'Success',
            color: const Color(0xFF22C55E),
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: failure.toDouble(),
            title: 'Failure',
            color: const Color(0xFFEF4444),
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots) {
    if (spots.isEmpty) return const Center(child: Text('Insufficient Data'));
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF2962FF),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2962FF).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLogItem(Map<String, dynamic> log, String type, bool isMobile) {
    final String user = log['email'] ?? log['profile_id'] ?? 'Unknown User';
    final DateTime? loginTime = log['login_time'] != null ? DateTime.tryParse(log['login_time']) : null;
    final String formattedDate = loginTime != null ? DateFormat('MMM dd, yyyy • HH:mm:ss').format(loginTime) : 'Unknown Time';
    final String status = log['status'] ?? 'Success';
    final bool isSuccess = status.toLowerCase() == 'success';
    final String ip = log['ip_address'] ?? 'N/A';
    final String userAgent = log['user_agent'] ?? 'Browser Unknown';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSuccess ? Icons.verified_user_rounded : Icons.gpp_bad_rounded,
          color: isSuccess ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: isSuccess ? Colors.green[700] : Colors.red[700],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (!isMobile)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('IP: $ip • $userAgent', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ),
          ],
        ),
      ),
      trailing: isMobile 
        ? null 
        : IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20, color: Colors.grey),
            onPressed: () => _showLogDetails(log),
          ),
    );
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Detail'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: log.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text('${e.value}')),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
