import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportAnalysisPage extends StatelessWidget {
  final List<String> _graphNames = [
    'Age Trend',
    'Pickup Trend',
    'Breed Distribution',
    'Resource Allocation',
    'Hotspot and Safe Zone',
  ];

  final List<Color> _buttonColors = [
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.redAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report and Analysis'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: _graphNames.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _showGraphDialog(context, index);
            },
            child: Container(
              decoration: BoxDecoration(
                color: _buttonColors[index],
                borderRadius: BorderRadius.circular(15),
              ),
              margin: EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(
                _graphNames[index],
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showGraphDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                AppBar(
                  title: Text(_graphNames[index]),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: _buildGraph(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGraph(int index) {
    switch (index) {
      case 0:
        return AgeTrendChart(_createAgeTrendData());
      case 1:
        return PickupTrendChart(_createPickupData());
      case 2:
        return BreedDistributionChart(_createBreedData());
      case 3:
        return ResourceManagementChart(_createResourceData());
      case 4:
        return HotSpotsAndSafeZones(_createCombinedData());
      default:
        return Center(child: Text('Error loading graph.'));
    }
  }
}
//hotspots and safezones
class HotSpotsAndSafeZones extends StatelessWidget {
  final List<CombinedBarData> data;

  HotSpotsAndSafeZones(this.data);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: data.map((e) {
          final total = e.hotspotCount + e.safeZoneCount;
          final hotspotPercentage = (total > 0) ? (e.hotspotCount / total * 100) : 0.0;
          final safeZonePercentage = (total > 0) ? (e.safeZoneCount / total * 100) : 0.0;

          return BarChartGroupData(
            x: e.localityIndex,
            barRods: [
              BarChartRodData(
                toY: hotspotPercentage,
                color: Colors.red,
                width: 15,
              ),
              BarChartRodData(
                toY: safeZonePercentage,
                color: Colors.green,
                width: 15,
              ),
            ],
            showingTooltipIndicators: [0, 1],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return Text(data[value.toInt()].locality);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%');
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
      ),
    );
  }
}

class CombinedBarData {
  final String locality;
  final int localityIndex;
  final int hotspotCount;
  final int safeZoneCount;

  CombinedBarData(this.locality, this.localityIndex, this.hotspotCount, this.safeZoneCount);
}

class AgeTrendChart extends StatelessWidget {
  final List<BarChartGroupData> data;

  AgeTrendChart(this.data);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: data,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return Text(' ${value+1.toInt()} Years');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }
}


class PickupTrendChart extends StatelessWidget {
  final List<FlSpot> data;

  PickupTrendChart(this.data);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: Colors.green,
            belowBarData: BarAreaData(show: true),
            dotData: FlDotData(show: false),
            aboveBarData: BarAreaData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return Text(_getMonthLabel(value.toInt()));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthLabel(int value) {
    switch (value) {
      case 0:
        return 'Jan';
      case 1:
        return 'Feb';
      case 2:
        return 'Mar';
      case 3:
        return 'Apr';
      case 4:
        return 'May';
      case 5:
        return 'Jun';
      case 6:
        return 'Jul';
      case 7:
        return 'Aug';
      case 8:
        return 'Sep';
      case 9:
        return 'Oct';
      case 10:
        return 'Nov';
      case 11:
        return 'Dec';
      default:
        return '';
    }
  }
}

class BreedDistributionChart extends StatelessWidget {
  final List<BarChartGroupData> data;

  BreedDistributionChart(this.data);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: data,
        borderData: FlBorderData(show: false), // Optional: Hide borders
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                // Customize this to return breed names on the x-axis
                switch (value.toInt()) {
                  case 1:
                    return Text('Labrador');
                  case 2:
                    return Text('kanni');
                  case 3:
                    return Text('Kombai');
                  case 4:
                    return Text('Aspin');
                  default:
                    return Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
      ),
    );
  }
}

/*class ResourceManagementChart extends StatelessWidget {
  final List<BarChartGroupData> data;

  ResourceManagementChart(this.data);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: data,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('Centre ${value.toInt() + 1}'); // Label for ABC Centers
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%'); // Percentage labels
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        barTouchData: BarTouchData(enabled: false),
        borderData: FlBorderData(show: false),
        maxY: 100, // Maximum percentage value for Y-axis (100%)
      ),
    );
  }
}

List<BarChartGroupData> _createABCResourceData() {
  return [
    BarChartGroupData(
      x: 0,
      barRods: [
        BarChartRodData(
          toY: 60, // Current load as a percentage (filled)
          color: Colors.blue,
          width: 20,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100, // Capacity (100%)
            color: Colors.grey.shade300, // Empty portion with outline
          ),
        ),
      ],
    ),
    BarChartGroupData(
      x: 1,
      barRods: [
        BarChartRodData(
          toY: 80, // Current load as a percentage (filled)
          color: Colors.green,
          width: 20,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100, // Capacity (100%)
            color: Colors.grey.shade300, // Empty portion with outline
          ),
        ),
      ],
    ),
    BarChartGroupData(
      x: 2,
      barRods: [
        BarChartRodData(
          toY: 50, // Current load as a percentage (filled)
          color: Colors.orange,
          width: 20,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100, // Capacity (100%)
            color: Colors.grey.shade300, // Empty portion with outline
          ),
        ),
      ],
    ),
  ];
}
*/




List<BarChartGroupData> _createAgeTrendData() {
  return [
    BarChartGroupData(
      x: 0, // Age 0
      barRods: [
        BarChartRodData(
          toY: 15, // Count of dogs of age 0
          color: Colors.blue,
          width: 40, // Thickness of the bar
        ),
      ],
    ),
    BarChartGroupData(
      x: 1, // Age 1
      barRods: [
        BarChartRodData(
          toY: 25, // Count of dogs of age 1
          color: Colors.green,
          width: 40, // Thickness of the bar
        ),
      ],
    ),
    BarChartGroupData(
      x: 2, // Age 2
      barRods: [
        BarChartRodData(
          toY: 20, // Count of dogs of age 2
          color: Colors.orange,
          width: 40, // Thickness of the bar
        ),
      ],
    ),
    BarChartGroupData(
      x: 3, // Age 3
      barRods: [
        BarChartRodData(
          toY: 30, // Count of dogs of age 3
          color: Colors.red,
          width: 40, // Thickness of the bar
        ),
      ],
    ),
    BarChartGroupData(
      x: 4, // Age 4
      barRods: [
        BarChartRodData(
          toY: 10, // Count of dogs of age 4
          color: Colors.purple,
          width: 40, // Thickness of the bar
        ),
      ],
    ),
  ];
}

List<FlSpot> _createPickupData() {
  return [
    FlSpot(0, 10),
    FlSpot(1, 15),
    FlSpot(2, 13),
    FlSpot(3, 18),
    FlSpot(4, 20),
    FlSpot(5, 23),
    FlSpot(6, 25),
    FlSpot(7, 19),
    FlSpot(9, 30),
  ];
}

List<BarChartGroupData> _createBreedData() {
  return [
    BarChartGroupData(
      x: 1,
      barRods: [
        BarChartRodData(
          toY: 80, // Number of dogs for Breed A
          color: Colors.orange,
        ),
      ],
    ),
    BarChartGroupData(
      x: 2,
      barRods: [
        BarChartRodData(
          toY: 50, // Number of dogs for Breed B
          color: Colors.blue,
        ),
      ],
    ),
    BarChartGroupData(
      x: 3,
      barRods: [
        BarChartRodData(
          toY: 20, // Number of dogs for Breed C
          color: Colors.green,
        ),
      ],
    ),
    BarChartGroupData(
      x: 4,
      barRods: [
        BarChartRodData(
          toY: 67, // Number of dogs for Breed C
          color: Colors.red,
        ),
      ],
    ),
  ];
}



List<double> healthyDogPercentages = [70, 65, 80, 75, 60, 85, 90, 80, 70, 75, 85, 88]; // Example data
List<double> diseasedDogPercentages = [30, 35, 20, 25, 40, 15, 10, 20, 30, 25, 15, 12]; // Example data

List<double> _createHealthData() {
  return healthyDogPercentages; // Change this as necessary
}

List<double> _createDiseasedHealthData() {
  // Return the percentages for diseased dogs
  return diseasedDogPercentages; // Change this as necessary
}


List<CombinedBarData> _createCombinedData() {
  return [
    CombinedBarData('kalyan', 0, 70, 30),
    CombinedBarData('Thane', 1, 40, 60),
    CombinedBarData('Andheri', 2, 20, 80),
  ];
}

class ResourceManagementChart extends StatelessWidget {
  final List<ResourceData> data;

  ResourceManagementChart(this.data);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: data.map((e) {
          return BarChartGroupData(
            x: e.centerIndex,
            barRods: [
              BarChartRodData(
                toY: e.currentLoad.toDouble(),
                color: Colors.purpleAccent,
                width: 18,
                borderRadius: BorderRadius.circular(12), // Rounded for "tube" effect
              ),
              BarChartRodData(
                toY: (e.capacity - e.currentLoad).toDouble(),
                color: Colors.grey.withOpacity(0.3),
                width: 18,
                borderRadius: BorderRadius.circular(12),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('Center ${value.toInt() + 1}');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}');
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        barTouchData: BarTouchData(enabled: true),
      ),
    );
  }
}

class ResourceData {
  final int centerIndex;
  final int capacity;
  final int currentLoad;

  ResourceData(this.centerIndex, this.capacity, this.currentLoad);
}

List<ResourceData> _createResourceData() {
  return [
    ResourceData(0, 100, 70), // Center 1: Capacity 100, Current Load 70
    ResourceData(1, 120, 90), // Center 2: Capacity 120, Current Load 90
    ResourceData(2, 80, 40),  // Center 3: Capacity 80, Current Load 40
    ResourceData(3, 150, 110), // Center 4: Capacity 150, Current Load 110
  ];
}

