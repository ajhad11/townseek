import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import 'users_list_screen.dart';
import 'shops_list_screen.dart';
import 'products_list_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'security_monitor_screen.dart';
import 'dart:async';
import 'dart:math' as math;
import 'pending_verification_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardHome(onNavigate: (index) => setState(() => _selectedIndex = index)),
      const UsersListScreen(),
      const ShopsListScreen(),
      const ProductsListScreen(),
      const SecurityMonitorScreen(),
      const PendingVerificationScreen(),
    ];
  }



  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("TownSeek Admin", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.security_rounded, color: Color(0xFF2962FF)),
              onPressed: () => setState(() => _selectedIndex = 4),
              tooltip: 'Security Monitor',
            ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2962FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF2962FF)),
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              tooltip: 'Logout',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isMobile
          ? Drawer(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2962FF), Color(0xFF536DFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: ClipOval(child: Image.asset('assets/Logo.png', width: 45, height: 45, fit: BoxFit.cover)),
                            ),
                            const SizedBox(height: 12),
                            const Text('Super Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    _buildDrawerTile(0, Icons.grid_view_rounded, 'Overview'),
                    _buildDrawerTile(1, Icons.group_rounded, 'User Management'),
                    _buildDrawerTile(2, Icons.storefront_rounded, 'Establishment'),
                    _buildDrawerTile(5, Icons.verified_user_rounded, 'Pending Verification'),
                    _buildDrawerTile(3, Icons.inventory_2_rounded, 'Products'),

                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedIndex = 4);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedIndex == 4 ? const Color(0xFF2962FF).withValues(alpha: 0.1) : const Color(0xFF2962FF).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: _selectedIndex == 4 ? Border.all(color: const Color(0xFF2962FF), width: 1.5) : null,
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(backgroundColor: Color(0xFF2962FF), radius: 16, child: Icon(Icons.security_rounded, color: Colors.white, size: 16)),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text('Security Monitor', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildSidebarItem(0, Icons.grid_view_rounded, 'Dashboard'),
                  _buildSidebarItem(1, Icons.group_rounded, 'User Management'),
                  _buildSidebarItem(2, Icons.storefront_rounded, 'Establishment'),
                  _buildSidebarItem(5, Icons.verified_user_rounded, 'Pending Verification'),
                  _buildSidebarItem(3, Icons.inventory_2_rounded, 'Products'),

                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = 4),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedIndex == 4 ? const Color(0xFF2962FF).withValues(alpha: 0.1) : const Color(0xFF2962FF).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: _selectedIndex == 4 ? Border.all(color: const Color(0xFF2962FF), width: 1.5) : null,
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(backgroundColor: Color(0xFF2962FF), radius: 16, child: Icon(Icons.security_rounded, color: Colors.white, size: 16)),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Security Monitor', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData? icon, String label, {Widget? customLeading}) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2962FF).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              customLeading ?? Icon(icon, color: isSelected ? const Color(0xFF2962FF) : Colors.grey[600], size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF2962FF) : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerTile(int index, IconData? icon, String title, {Widget? customLeading}) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: customLeading ?? Icon(icon, color: isSelected ? const Color(0xFF2962FF) : null),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null)),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}

class DashboardHome extends StatefulWidget {
  final Function(int)? onNavigate;
  const DashboardHome({super.key, this.onNavigate});


  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    final service = Provider.of<SupabaseService>(context, listen: false);
    _statsFuture = service.getDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Systems Synchronization Failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _statsFuture = Provider.of<SupabaseService>(context, listen: false).getDashboardStats();
                  }),
                  child: const Text('Re-sync Now'),
                ),
              ],
            ),
          );
        }
        
        final stats = snapshot.data ?? {'users': 0, 'shops': 0, 'pending': 0};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Systems Overview',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const Text('Real-time synchronization with TownSeek global database.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _FancyStatCard(
                        title: 'Total Users',
                        value: stats['users'].toString(),
                        icon: Icons.group_add_rounded,
                        colors: const [Color(0xFF2962FF), Color(0xFF00B0FF)],
                        width: isMobile ? double.infinity : 300,
                        onTap: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(1);
                          }
                        },
                      ),
                      _FancyStatCard(
                        title: 'Active Establishments',
                        value: stats['shops'].toString(),
                        icon: Icons.store_mall_directory_rounded,
                        colors: const [Color(0xFF00C853), Color(0xFF64DD17)],
                        width: isMobile ? double.infinity : 300,
                        onTap: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(2);
                          }
                        },
                      ),
                      _FancyStatCard(
                        title: 'Verification Requests',
                        value: (stats['pending'] ?? 0).toString(),
                        icon: Icons.verified_user_rounded,
                        colors: const [Color(0xFFFF9100), Color(0xFFFFC400)],
                        width: isMobile ? double.infinity : 300,
                        onTap: () {
                          if (widget.onNavigate != null) {
                            widget.onNavigate!(5);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
              const Text(
                'Platform Distribution',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Container(
                height: 350,
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 60,
                          sections: [
                            PieChartSectionData(
                              value: (stats['users'] ?? 0).toDouble(),
                              title: 'Users',
                              color: const Color(0xFF2962FF),
                              radius: 30,
                              titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            PieChartSectionData(
                              value: (stats['shops'] ?? 0).toDouble(),
                              title: 'Shops',
                              color: const Color(0xFF00C853),
                              radius: 30,
                              titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('Global Users', const Color(0xFF2962FF), stats['users'].toString()),
                          const SizedBox(height: 16),
                          _buildLegendItem('Active Shops', const Color(0xFF00C853), stats['shops'].toString()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const Row(
                children: [
                   Text(
                    'Live Ecosystem Flow',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 12),
                  _PulseDot(),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 380,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 40, 40, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 40, offset: const Offset(0, 10))],
                ),
                child: const _MovingGrowthChart(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }


  Widget _buildLegendItem(String label, Color color, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withValues(alpha: 1.0 - _controller.value),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF22C55E), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                blurRadius: 10 * _controller.value,
                spreadRadius: 5 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MovingGrowthChart extends StatefulWidget {
  const _MovingGrowthChart();

  @override
  State<_MovingGrowthChart> createState() => _MovingGrowthChartState();
}

class _MovingGrowthChartState extends State<_MovingGrowthChart> {
  final List<FlSpot> _userSpots = [];
  final List<FlSpot> _shopSpots = [];
  Timer? _timer;
  double _xValue = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 15; i++) {
      _userSpots.add(FlSpot(_xValue, 10 + math.Random().nextDouble() * 10));
      _shopSpots.add(FlSpot(_xValue, 5 + math.Random().nextDouble() * 5));
      _xValue += 1;
    }

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _userSpots.add(FlSpot(_xValue, 10 + math.Random().nextDouble() * 10));
          _shopSpots.add(FlSpot(_xValue, 5 + math.Random().nextDouble() * 5));
          _xValue += 1;
          
          if (_userSpots.length > 20) {
            _userSpots.removeAt(0);
            _shopSpots.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 30,
        lineBarsData: [
          _generateLineBarData(_userSpots, const Color(0xFF2962FF)),
          _generateLineBarData(_shopSpots, const Color(0xFF00C853)),
        ],
      ),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
    );
  }

  LineChartBarData _generateLineBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}


class _FancyStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Widget? customIcon;
  final List<Color> colors;
  final double width;
  final VoidCallback? onTap;

  const _FancyStatCard({
    required this.title,
    required this.value,
    this.icon,
    this.customIcon,
    required this.colors,
    required this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: customIcon ?? Icon(icon, color: Colors.white, size: 28),
              ),
              const Icon(Icons.trending_up, color: Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    ),
  );
}
}


