import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportAnalysisPage extends StatelessWidget {
  final List<String> _graphNames = [
    'Age Trend',
    'Pickup Trend',
    'Breed Distribution',
    'Resource Allocation',
    'Hotspots and Safe Zones',
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
      appBar: AppBar(title: const Text('Report and Analysis')),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: _graphNames.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showGraphDialog(context, index),
            child: Container(
              decoration: BoxDecoration(
                color: _buttonColors[index],
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(
                _graphNames[index],
                style: const TextStyle(
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
            height: MediaQuery
                .of(context)
                .size
                .height,
            child: Column(
              children: [
                AppBar(
                  title: Text(_graphNames[index]),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
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
        return _buildAgeTrendChart();
      case 1:
        return _buildPickupTrendChart();
      case 2:
        return _buildBreedDistributionChart();
      case 3:
        return _buildResourceAllocationChart();
      case 4:
        return _buildHotspotsAndSafeZonesChart();
      default:
        return const Center(child: Text('Error loading graph.'));
    }
  }


  Widget _buildAgeTrendChart() {
    return StreamBuilder<List<BarChartGroupData>>(
      stream: getRealTimeAgeTrendData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available.'));
        }

        return Padding(
          padding: const EdgeInsets.all(14.0),
          child: BarChart(
            BarChartData(
              barGroups: snapshot.data ?? [],
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false), // Hide top titles
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Only display integer values on the Y-axis
                      if (value % 1 == 0) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 14),
                        );
                      }
                      return const SizedBox.shrink(); // Hide non-integer values
                    },
                    reservedSize: 40,
                    interval: 1, // Force a 1-unit interval for the Y-axis
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Only display integer values on the Y-axis
                      if (value % 1 == 0) {
                        return Text(
                          '  ${value.toInt()}',
                          style: const TextStyle(fontSize: 14),
                        );
                      }
                      return const SizedBox.shrink(); // Hide non-integer values
                    },
                    reservedSize: 40,
                    interval: 1, // Force a 1-unit interval for the Y-axis
                  ),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Show the age as a label on the X-axis
                      return Text(
                        '${value.toInt()} years',
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(enabled: true),
            ),
          ),
        );
      },
    );
  }

  Stream<List<BarChartGroupData>> getRealTimeAgeTrendData() {
    return FirebaseFirestore.instance.collection('dogs_records')
        .snapshots()
        .map((snapshot) {
      final ageGroups = <int, int>{}; // Map to store the count of each age

      for (var doc in snapshot.docs) {
        // Parse age from the document
        final age = int.tryParse(doc['Age'].toString()) ?? 0;

        // Increment the count for this age
        ageGroups[age] = (ageGroups[age] ?? 0) + 1;
      }

      // Sort the ages in ascending order
      final sortedAgeGroups = ageGroups.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // Debugging log for the aggregated age groups
      print("Aggregated Age Groups: $sortedAgeGroups");

      // Create BarChartGroupData for each age
      return sortedAgeGroups.map((entry) {
        return BarChartGroupData(
          x: entry.key, // Age as the X-axis value
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(), // Count of dogs for this age
              color: Colors.blueAccent,
              width: 20, // Width of the bar
            ),
          ],
        );
      }).toList();
    });
  }

  Widget _buildPickupTrendChart() {
    return FutureBuilder<List<BarChartGroupData>>(
      future: _getPickupTrendData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return Container(
          height: 300, // Adjust the height of the chart
          width: 600, // Adjust the width to match the parent container
          padding: const EdgeInsets.all(10), // Add padding if needed
          child: BarChart(
            BarChartData(
              barGroups: snapshot.data ?? [],
              gridData: FlGridData(show: true), // Gridlines enabled
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 15,
                    getTitlesWidget: (value, meta) {
                      // Only show integer values on the Y-axis
                      if (value % 1 == 0) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 16),
                        );
                      }
                      return const SizedBox.shrink(); // Hide non-integer values
                    },
                    interval: 1, // Force a 1-unit interval for the Y-axis
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 15,
                    getTitlesWidget: (value, meta) {
                      // Only show integer values on the Y-axis
                      if (value % 1 == 0) {
                        return Text(
                          ' ${value.toInt()}',
                          style: const TextStyle(fontSize: 16),
                        );
                      }
                      return const SizedBox.shrink(); // Hide non-integer values
                    },
                    interval: 1, // Force a 1-unit interval for the Y-axis
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      const months = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                      ];
                      return Text(months[value.toInt() - 1]);
                    },
                  ),
                ),
              ),
              minY: 0,
            ),
          ),
        );
      },
    );
  }

  Future<List<BarChartGroupData>> _getPickupTrendData() async {
    final querySnapshot = await FirebaseFirestore.instance.collection(
        'dogs_records').get();

    // Group pickups by month
    Map<int, int> monthCounts = {
      for (int i = 1; i <= 12; i++) i: 0,
    };

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['Pickup Date'] != null) {
        final pickupDate = (data['Pickup Date'] as Timestamp).toDate();
        monthCounts[pickupDate.month] =
            (monthCounts[pickupDate.month] ?? 0) + 1;
      }
    }

    // Convert data to BarChartGroupData
    return monthCounts.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.orange,
            width: 16,
          ),
        ],
      );
    }).toList();
  }

  Widget _buildBreedDistributionChart() {
    return StreamBuilder<Map<String, int>>(
      stream: getRealTimeBreedDistributionData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Extract breed data and prepare breed names
        final breedCounts = snapshot.data ?? {};
        final breedNames = breedCounts.keys.toList();

        // Assign unique colors for each breed
        final colors = [
          Colors.green,
          Colors.blue,
          Colors.red,
          Colors.orange,
          Colors.purple,
          Colors.yellow,
          Colors.pink,
        ]; // Add more colors if needed

        final breedColors = Map<String, Color>.fromIterables(
          breedNames,
          List.generate(
              breedNames.length, (index) => colors[index % colors.length]),
        );

        // Create BarChartGroupData
        final barGroups = breedCounts.entries.map((entry) {
          final index = breedNames.indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: breedColors[entry.key], // Assign color based on breed
                width: 20,
              ),
            ],
          );
        }).toList();

        return Container(
          height: 300,
          width: 600,
          padding: const EdgeInsets.all(10),
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      // Only show integer values on the Y-axis
                      if (value % 1 == 0) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 16),
                        );
                      }
                      return const SizedBox.shrink(); // Hide non-integer values
                    },
                    interval: 1, // Force a 1-unit interval for the Y-axis
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      // Only show integer values on the Y-axis
                      if (value % 1 == 0) {
                        return Text(
                          '  ${value.toInt()}',
                          style: const TextStyle(fontSize: 16),
                        );
                      }
                      return const SizedBox.shrink(); // Hide non-integer values
                    },
                    interval: 1, // Force a 1-unit interval for the Y-axis
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      final breed = index < breedNames.length
                          ? breedNames[index]
                          : '';
                      return Text(
                        breed,
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
            ),
          ),
        );
      },
    );
  }

  Stream<Map<String, int>> getRealTimeBreedDistributionData() async* {
    final querySnapshot = await FirebaseFirestore.instance.collection(
        'dogs_records').get();

    // Count occurrences of each breed
    Map<String, int> breedCounts = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final breed = data['Breed'] ?? '';
      breedCounts[breed] = (breedCounts[breed] ?? 0) + 1;
    }

    // Log breed counts and names
    print("Breed Counts from Firestore: $breedCounts");

    yield breedCounts;
  }


  Widget _buildResourceAllocationChart() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getRealTimeResourceAllocationData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        final data = snapshot.data!;
        final barChartGroups = data.map((
            e) => e['barGroup'] as BarChartGroupData).toList();
        final centreNames = data.map((e) => e['centreName'] as String).toList();

        return BarChart(
          BarChartData(
            barGroups: barChartGroups,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // Map index to centre names
                    if (value.toInt() >= 0 &&
                        value.toInt() < centreNames.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          centreNames[value.toInt()],
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 40,
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
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipMargin: 10, // Optional margin for tooltip
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final percentage = rod.toY;
                  return BarTooltipItem(
                    '${percentage.toStringAsFixed(1)}%',
                    // Show percentage with 1 decimal place
                    TextStyle(color: Colors.white),
                  );
                },
              ),
              touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                // Handle touch callback if necessary
                if (response != null && response.spot != null) {
                  print("Touched bar: ${response.spot!.touchedBarGroupIndex}");
                }
              },
              handleBuiltInTouches: true,
            ),
            borderData: FlBorderData(show: false),
            maxY: 100,
            backgroundColor: Colors.grey[200],
          ),
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getRealTimeResourceAllocationData() {
    return FirebaseFirestore.instance
        .collection(
        'abc_records') // Replace with your Firestore collection name
        .snapshots()
        .map((querySnapshot) {
      List<Map<String, dynamic>> chartData = [];
      int index = 0;

      for (var doc in querySnapshot.docs) {
        final capacity = doc['capacity'] as num? ?? 0;
        final currentLoad = doc['currentLoad'] as num? ?? 0;
        final centreName = doc['centreName'] as String? ??
            "Unknown"; // Default to "Unknown" if null

        final percentage = capacity > 0 ? (currentLoad / capacity * 100) : 0;

        chartData.add({
          'barGroup': BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: percentage.toDouble(),
                // Filled portion
                color: percentage > 80
                    ? Colors.red
                    : percentage > 50
                    ? Colors.orange
                    : Colors.green,
                // Bar color based on utilization
                width: 25,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100, // Maximum bar height for 100% capacity
                  color: Colors.grey.withOpacity(0.3), // Empty (background) part
                ),
              ),
            ],
          ),
          'centreName': centreName, // Store center name here
        });
        index++;
      }
      return chartData;
    });
  }
}

class CombinedBarData {
  final String locality;
  final String diseaseType;
  final int count;

  CombinedBarData({
    required this.locality,
    required this.diseaseType,
    required this.count,
  });
}

Stream<List<CombinedBarData>> getRealTimeHotSpotData() {
  return FirebaseFirestore.instance.collection('abc_records').snapshots().map((snapshot) {
    final data = <CombinedBarData>[];

    // Loop through all the ABC center records
    for (var doc in snapshot.docs) {
      // Ensure the 'diseasedDogs' field is a list and iterate over it
      List<dynamic> diseasedDogs = doc['diseasedDogs'] ?? [];

      for (var diseaseInfo in diseasedDogs) {
        // Ensure diseaseInfo is a map and safely access its fields
        if (diseaseInfo is Map<String, dynamic>) {
          String diseaseType = diseaseInfo['diseaseType'] ?? ''; // e.g., 'Rabies'
          int count = diseaseInfo['count'] ?? 0; // e.g., 10
          Map<String, int> localities = Map<String, int>.from(diseaseInfo['localities'] ?? {});

          // Process localities and add the data for each locality
          localities.forEach((localityName, localityCount) {
            data.add(CombinedBarData(
              locality: localityName,
              diseaseType: diseaseType,
              count: localityCount,
            ));
          });
        }
      }
    }

    return data;
  });
}

Widget _buildHotspotsAndSafeZonesChart() {
  return StreamBuilder<List<CombinedBarData>>(
    stream: getRealTimeHotSpotData(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      final data = snapshot.data ?? [];
      final colorMap = <String, Color>{};

      // Group data by locality and disease type
      Map<String, Map<String, int>> groupedData = {};
      for (var item in data) {
        if (!groupedData.containsKey(item.locality)) {
          groupedData[item.locality] = {};
        }
        groupedData[item.locality]?[item.diseaseType] = item.count;
      }

      // Prepare data for the bar chart
      List<BarChartGroupData> chartData = [];
      List<String> localityNames = []; // To store locality names

      groupedData.forEach((locality, diseases) {
        localityNames.add(locality); // Add locality to the list for x-axis labels

        List<BarChartRodData> rods = [];

        diseases.forEach((diseaseType, count) {
          rods.add(
            BarChartRodData(
              toY: count.toDouble(),
              color: getColorForDisease(diseaseType, colorMap),
              width: 20, // Use color based on disease type
            ),
          );
        });

        chartData.add(
          BarChartGroupData(
            x: localityNames.length - 1, // Set the x value based on the locality's index
            barRods: rods,
          ),
        );
      });

      return Column(
        children: [
          // Legend/Scale at the top-right corner
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 10,
                runSpacing: 5,
                children: groupedData.values
                    .expand((diseases) => diseases.keys)
                    .toSet()
                    .map((diseaseType) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      color: getColorForDisease(diseaseType, colorMap),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      diseaseType,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ))
                    .toList(),
              ),
            ),
          ),
          // Bar Chart
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(

                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return getTitlesWidgetTitles(value, meta, localityNames);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                barGroups: chartData,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget getTitlesWidgetTitles(double value, TitleMeta meta, List<String> localityNames) {
  // Ensure that the value corresponds to a valid index
  int index = value.toInt();
  if (index < localityNames.length) {
    return Text(
      localityNames[index], // Show the correct locality name
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  } else {
    return Container(); // Return an empty container if out of range
  }
}

Color getColorForDisease(String diseaseType, Map<String, Color> colorMap) {
  // Predefined colors for the first two disease types
  final predefinedColors = [
    Colors.blue, // First predefined color
    Colors.orange, // Second predefined color
  ];

  if (!colorMap.containsKey(diseaseType)) {
    // Assign predefined colors first
    if (colorMap.length < predefinedColors.length) {
      colorMap[diseaseType] = predefinedColors[colorMap.length];
    } else {
      // Generate a new random color for additional disease types
      colorMap[diseaseType] = Color((diseaseType.hashCode & 0xFFFFFF) | 0xFF000000);
    }
  }

  return colorMap[diseaseType]!;
}

