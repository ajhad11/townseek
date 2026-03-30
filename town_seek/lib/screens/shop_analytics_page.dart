import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_header.dart';

class ShopAnalyticsPage extends StatefulWidget {
  final Map<String, dynamic> shop;
  const ShopAnalyticsPage({super.key, required this.shop});

  @override
  State<ShopAnalyticsPage> createState() => _ShopAnalyticsPageState();
}

class _ShopAnalyticsPageState extends State<ShopAnalyticsPage> {
  String _filter = 'Week'; // 'Day', 'Week', 'Month'
  bool _isLoading = true;
  List<FlSpot> _clickSpots = [];
  List<FlSpot> _orderSpots = [];
  double _maxY = 10;
  int _totalClicks = 0;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      DateTime startDate;
      int days;

      switch (_filter) {
        case 'Day':
          startDate = DateTime(now.year, now.month, now.day);
          days = 1;
          break;
        case 'Week':
          startDate = now.subtract(const Duration(days: 7));
          days = 7;
          break;
        case 'Month':
          startDate = now.subtract(const Duration(days: 30));
          days = 30;
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
          days = 7;
      }

      // 1. Fetch Orders from 'orders' table
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('created_at')
          .eq('shop_id', widget.shop['id'])
          .gte('created_at', startDate.toIso8601String());

      // 2. Fetch Clicks (Assuming a 'shop_clicks' table exists for time-series analytics)
      // If it doesn't exist, we fall back to 0 or mock data for demonstration
      List<dynamic> clicksResponse = [];
      try {
        clicksResponse = await Supabase.instance.client
            .from('shop_clicks')
            .select('created_at')
            .eq('shop_id', widget.shop['id'])
            .gte('created_at', startDate.toIso8601String());
      } catch (e) {
        debugPrint('Analytics: shop_clicks table might not exist. Falling back.');
      }

      _processData(ordersResponse, clicksResponse, startDate, days);
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processData(List<dynamic> orders, List<dynamic> clicks, DateTime startDate, int days) {
    Map<int, int> orderCounts = {};
    Map<int, int> clickCounts = {};

    for (int i = 0; i < days; i++) {
       orderCounts[i] = 0;
       clickCounts[i] = 0;
    }


    for (var o in orders) {
      final dt = DateTime.parse(o['created_at']);
      final diff = dt.difference(startDate).inDays;
      if (diff >= 0 && diff < days) {
        orderCounts[diff] = (orderCounts[diff] ?? 0) + 1;
      }
    }

    for (var c in clicks) {
      final dt = DateTime.parse(c['created_at']);
      final diff = dt.difference(startDate).inDays;
      if (diff >= 0 && diff < days) {
        clickCounts[diff] = (clickCounts[diff] ?? 0) + 1;
      }
    }

    _orderSpots = orderCounts.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
    _clickSpots = clickCounts.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    _totalOrders = orders.length;
    _totalClicks = clicks.length;

    double maxVal = 0;
    for (var s in _orderSpots) {
      if (s.y > maxVal) maxVal = s.y;
    }
    for (var s in _clickSpots) {
      if (s.y > maxVal) maxVal = s.y;
    }
    _maxY = (maxVal < 5) ? 10 : maxVal + 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          CustomHeader(
            title: 'Shop Analytics',
            showBackButton: true,
            onBack: () => Navigator.pop(context),
          ),
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        _buildChartCard("Engagement Overview", "Clicks vs Orders"),
                        const SizedBox(height: 24),
                        _buildInsightSection(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['Day', 'Week', 'Month'].map((f) {
          final isSelected = _filter == f;
          return ChoiceChip(
            label: Text(f),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                setState(() => _filter = f);
                _fetchData();
              }
            },
            selectedColor: const Color(0xFF2962FF),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildStatCard("Total Clicks", _totalClicks.toString(), Icons.touch_app, Colors.orange),
        const SizedBox(width: 16),
        _buildStatCard("Total Orders", _totalOrders.toString(), Icons.shopping_bag, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: _buildTitles(),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_filter == 'Day' ? 1 : (_filter == 'Week' ? 6 : 29)).toDouble(),
                minY: 0,
                maxY: _maxY,
                lineBarsData: [
                  _buildLineBar(_clickSpots, Colors.orange),
                  _buildLineBar(_orderSpots, Colors.blue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Clicks", Colors.orange),
              const SizedBox(width: 24),
              _buildLegendItem("Orders", Colors.blue),
            ],
          )
        ],
      ),
    );
  }

  FlTitlesData _buildTitles() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (val, meta) {
            if (_filter == 'Day') return const SizedBox.shrink();
            if (val % (_filter == 'Week' ? 1 : 5) != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _filter == 'Week' ? "Day ${val.toInt() + 1}" : "${val.toInt() + 1}",
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (val, meta) {
            return Text(val.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  LineChartBarData _buildLineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInsightSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text("Quick Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _totalClicks > 0 
              ? "Your shop has received $_totalClicks clicks and $_totalOrders orders in this period. Keep your profile updated to attract more customers!"
              : "No activity recorded yet for this period. Try sharing your shop profile to get started.",
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }
}
