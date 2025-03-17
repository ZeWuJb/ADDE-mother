import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthMetricsPage extends StatefulWidget {
  final String userId;
  const HealthMetricsPage({super.key, required this.userId});

  @override
  State<HealthMetricsPage> createState() => _HealthMetricsPageState();
}

class _HealthMetricsPageState extends State<HealthMetricsPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController bpSysController = TextEditingController();
  final TextEditingController bpDiaController = TextEditingController();
  final TextEditingController hrController = TextEditingController();
  final TextEditingController tempController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  List<Map<String, dynamic>> healthData = [];

  @override
  void initState() {
    super.initState();
    fetchHealthData();
  }

  Future<void> fetchHealthData() async {
    final response = await supabase
        .from('health_metrics')
        .select()
        .eq('user_id', widget.userId)
        .order('created_at', ascending: true);
    setState(() {
      healthData = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> saveHealthData() async {
    final bpSystolic = int.tryParse(bpSysController.text);
    final bpDiastolic = int.tryParse(bpDiaController.text);
    final heartRate = int.tryParse(hrController.text);
    final bodyTemp = double.tryParse(tempController.text);
    final weight = double.tryParse(weightController.text);

    if ([bpSystolic, bpDiastolic, heartRate, bodyTemp, weight].contains(null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter valid values for all fields.")),
      );
      return;
    }

    try {
      await supabase.from('health_metrics').insert({
        'user_id': widget.userId,
        'bp_systolic': bpSystolic,
        'bp_diastolic': bpDiastolic,
        'heart_rate': heartRate,
        'body_temp': bodyTemp,
        'weight': weight,
        'created_at': DateTime.now().toIso8601String(),
      });

      bpSysController.clear();
      bpDiaController.clear();
      hrController.clear();
      tempController.clear();
      weightController.clear();

      fetchHealthData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Data saved successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save data. Please try again.")),
      );
    }
  }

  Widget buildBarChart(String field, String title, Color color) {
    final spots =
        healthData.asMap().entries.map((e) {
          final index = e.key;
          final value = (e.value[field] as num).toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: color,
                width: 15,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: Colors.grey[300],
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 200, child: BarChart(BarChartData(barGroups: spots))),
      ],
    );
  }

  List<String> generateRecommendations() {
    if (healthData.isEmpty) return ["No data available."];
    final latest = healthData.last;

    final bpSys = latest['bp_systolic'];
    final bpDia = latest['bp_diastolic'];
    final hr = latest['heart_rate'];
    final temp = latest['body_temp'];
    final weight = latest['weight'];

    List<String> recommendations = [];

    if (bpSys < 90 || bpDia < 60) {
      recommendations.add(
        "Consider increasing salt intake and staying hydrated.",
      );
    } else if (bpSys > 140 || bpDia > 90) {
      recommendations.add(
        "Reduce salt intake, exercise regularly, and manage stress.",
      );
    }

    if (hr < 60) {
      recommendations.add(
        "Increase physical activity and monitor your heart health.",
      );
    } else if (hr > 100) {
      recommendations.add(
        "Try relaxation techniques like meditation or breathing exercises.",
      );
    }

    if (temp < 36.0) {
      recommendations.add("Keep warm and monitor for any signs of illness.");
    } else if (temp > 37.5) {
      recommendations.add(
        "Stay hydrated, rest, and monitor for fever symptoms.",
      );
    }

    if (weight < 50) {
      recommendations.add("Ensure a balanced diet with enough calories.");
    } else if (weight > 80) {
      recommendations.add("Consider regular exercise and a healthy diet.");
    }

    return recommendations.isEmpty
        ? ["All vitals are normal. Keep up the good work!"]
        : recommendations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Health Metrics", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter Health Data:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: bpSysController,
                decoration: InputDecoration(labelText: "BP Systolic (mmHg)"),
              ),
              TextField(
                controller: bpDiaController,
                decoration: InputDecoration(labelText: "BP Diastolic (mmHg)"),
              ),
              TextField(
                controller: hrController,
                decoration: InputDecoration(labelText: "Heart Rate (bpm)"),
              ),
              TextField(
                controller: tempController,
                decoration: InputDecoration(labelText: "Body Temperature (°C)"),
              ),
              TextField(
                controller: weightController,
                decoration: InputDecoration(labelText: "Weight (kg)"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: saveHealthData,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.pink,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: Text("Save Data", style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 20),
              Text(
                "Trend Charts:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (healthData.isEmpty)
                Text("No data available.")
              else ...[
                buildBarChart(
                  "bp_systolic",
                  "Blood Pressure Systolic",
                  Colors.blue,
                ),
                buildBarChart("heart_rate", "Heart Rate", Colors.red),
                buildBarChart("body_temp", "Body Temperature", Colors.green),
                buildBarChart("weight", "Weight", Colors.orange),
              ],
              SizedBox(height: 20),
              Text(
                "Recommendations:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...generateRecommendations().map((rec) => Text("• $rec")),
            ],
          ),
        ),
      ),
    );
  }
}
