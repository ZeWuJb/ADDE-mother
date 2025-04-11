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

  Widget buildLineChart() {
    if (healthData.isEmpty) {
      return Text("No data available.");
    }

    final List<FlSpot> bpSysSpots =
        healthData.asMap().entries.map((e) {
          final value = (e.value['bp_systolic'] as num?)?.toDouble() ?? 0.0;
          return FlSpot(e.key.toDouble(), value);
        }).toList();

    final List<FlSpot> hrSpots =
        healthData.asMap().entries.map((e) {
          final value = (e.value['heart_rate'] as num?)?.toDouble() ?? 0.0;
          return FlSpot(e.key.toDouble(), value);
        }).toList();

    final List<FlSpot> tempSpots =
        healthData.asMap().entries.map((e) {
          final value = (e.value['body_temp'] as num?)?.toDouble() ?? 0.0;
          return FlSpot(e.key.toDouble(), value * 5); // Scale temperature
        }).toList();

    final List<FlSpot> weightSpots =
        healthData.asMap().entries.map((e) {
          final value = (e.value['weight'] as num?)?.toDouble() ?? 0.0;
          return FlSpot(e.key.toDouble(), value);
        }).toList();

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return Text("0");
                  if (value == 50) return Text("50");
                  if (value == 100) return Text("100");
                  if (value == 150) return Text("150");
                  if (value == 200) return Text("200");
                  return Text("");
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          minY: 0,
          maxY: 200,
          lineBarsData: [
            LineChartBarData(
              spots: bpSysSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: hrSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 2,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: tempSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: weightSpots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 2,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final data = healthData[index];
                  String label = '';
                  if (spot.barIndex == 0) {
                    label = 'BP Sys: ${data['bp_systolic']} mmHg';
                  } else if (spot.barIndex == 1) {
                    label = 'HR: ${data['heart_rate']} bpm';
                  } else if (spot.barIndex == 2) {
                    label =
                        'Temp: ${(data['body_temp'] as num).toStringAsFixed(1)}°C';
                  } else if (spot.barIndex == 3) {
                    label =
                        'Weight: ${(data['weight'] as num).toStringAsFixed(1)} kg';
                  }
                  return LineTooltipItem(label, TextStyle(color: Colors.white));
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<String> generateRecommendations() {
    if (healthData.isEmpty) {
      return [
        "No data available yet. Start by entering your health metrics to receive personalized recommendations.",
      ];
    }

    final latest = healthData.last;
    final bpSys = (latest['bp_systolic'] as num?)?.toInt() ?? 0;
    final bpDia = (latest['bp_diastolic'] as num?)?.toInt() ?? 0;
    final hr = (latest['heart_rate'] as num?)?.toInt() ?? 0;
    final temp = (latest['body_temp'] as num?)?.toDouble() ?? 0.0;
    final weight = (latest['weight'] as num?)?.toDouble() ?? 0.0;

    List<String> recommendations = [];

    if (bpSys < 90 || bpDia < 60) {
      recommendations.add(
        "Your blood pressure appears to be low (Systolic: $bpSys mmHg, Diastolic: $bpDia mmHg). This could be due to dehydration, fatigue, or other factors. To help stabilize it, consider increasing your salt intake slightly (e.g., adding a pinch to your meals), drinking more water throughout the day (aim for 8-10 glasses), and eating small, frequent meals to maintain energy levels. If you feel dizzy or faint often, consult a healthcare professional to rule out underlying issues.",
      );
    } else if (bpSys > 140 || bpDia > 90) {
      recommendations.add(
        "Your blood pressure is elevated (Systolic: $bpSys mmHg, Diastolic: $bpDia mmHg), which might indicate hypertension. To manage this, reduce your salt intake by avoiding processed foods and opting for fresh ingredients, engage in moderate exercise like brisk walking or cycling for 30 minutes most days of the week, and practice stress-reduction techniques such as yoga or deep breathing for 10-15 minutes daily. If this persists across multiple readings, consider seeing a doctor for a detailed evaluation.",
      );
    } else {
      recommendations.add(
        "Your blood pressure (Systolic: $bpSys mmHg, Diastolic: $bpDia mmHg) is within a normal range. To maintain this, continue a balanced diet rich in fruits, vegetables, and lean proteins, and keep up with regular physical activity (at least 150 minutes per week). Monitoring trends over time will help ensure it stays stable.",
      );
    }

    if (hr < 60) {
      recommendations.add(
        "Your heart rate ($hr bpm) is on the lower side. This can be normal for fit individuals, but if you’re not highly active or feel unusually tired, it’s worth monitoring. Increase your physical activity with exercises like jogging, swimming, or dancing for 20-30 minutes a few times a week to boost cardiovascular health. Track this over time and consult a doctor if it drops further or you experience symptoms like lightheadedness.",
      );
    } else if (hr > 100) {
      recommendations.add(
        "Your heart rate ($hr bpm) is elevated, which could be due to stress, caffeine, or exertion. To bring it down, try relaxation techniques like deep breathing exercises (inhale for 4 seconds, exhale for 6) or meditation for 10-15 minutes daily. Limit stimulants like coffee or energy drinks, and ensure you’re getting 7-9 hours of sleep. If it remains high consistently, a medical checkup might be warranted.",
      );
    } else {
      recommendations.add(
        "Your heart rate ($hr bpm) is in a healthy range. To keep it that way, maintain a routine of moderate exercise (e.g., walking or cycling) and ensure you’re managing stress effectively with hobbies or relaxation practices. Consistency is key—keep tracking it to spot any unusual changes.",
      );
    }

    if (temp < 36.0) {
      recommendations.add(
        "Your body temperature ($temp°C) is below average, which might suggest you’re cold or your metabolism is slow. Keep warm by layering clothing or using a blanket, and sip warm beverages like herbal tea throughout the day. Monitor for signs of illness like fatigue or chills, and if this persists, consider a thyroid check with your doctor since low temperature can sometimes indicate hormonal imbalances.",
      );
    } else if (temp > 37.5) {
      recommendations.add(
        "Your body temperature ($temp°C) is elevated, possibly indicating a fever or overheating. Stay hydrated by drinking 8-12 glasses of water daily, rest in a cool environment, and avoid heavy physical activity until it normalizes. If it exceeds 38°C or lasts more than a day, seek medical advice to rule out infections or other causes.",
      );
    } else {
      recommendations.add(
        "Your body temperature ($temp°C) is normal. To maintain this, dress appropriately for the weather, stay hydrated with 6-8 glasses of water daily, and avoid extreme temperature changes. Regular monitoring will help you catch any deviations early.",
      );
    }

    if (weight < 50) {
      recommendations.add(
        "Your weight ($weight kg) is on the lower side. To gain or maintain a healthy weight, focus on a nutrient-dense diet including proteins (e.g., eggs, chicken, beans), healthy fats (e.g., nuts, avocados), and complex carbs (e.g., whole grains). Aim for 3 balanced meals and 2 snacks daily, and consider light strength training exercises like lifting small weights to build muscle mass. Consult a nutritionist if you’re struggling to gain weight.",
      );
    } else if (weight > 80) {
      recommendations.add(
        "Your weight ($weight kg) is on the higher side. To manage it, incorporate regular exercise like walking, swimming, or yoga for 30-40 minutes most days, and focus on a diet rich in vegetables, lean proteins, and whole grains while cutting back on sugary drinks and processed snacks. Set small, achievable goals (e.g., losing 0.5 kg per month) and track progress. A healthcare provider can offer tailored advice if needed.",
      );
    } else {
      recommendations.add(
        "Your weight ($weight kg) is within a healthy range. To sustain this, continue eating a balanced diet with plenty of fruits, vegetables, and lean proteins, and stay active with at least 150 minutes of moderate exercise weekly. Regular weigh-ins will help you maintain consistency over time.",
      );
    }

    if (healthData.length > 1) {
      final previous = healthData[healthData.length - 2];
      final prevBpSys = (previous['bp_systolic'] as num?)?.toInt() ?? 0;
      final prevHr = (previous['heart_rate'] as num?)?.toInt() ?? 0;
      final prevWeight = (previous['weight'] as num?)?.toDouble() ?? 0.0;

      if (bpSys > prevBpSys + 10) {
        recommendations.add(
          "Your systolic blood pressure has increased by more than 10 mmHg since your last reading (from $prevBpSys to $bpSys). This could be situational (e.g., stress or diet), but monitor it closely over the next few days. Reduce sodium intake, avoid caffeine close to bedtime, and try a 10-minute relaxation exercise daily to see if it stabilizes.",
        );
      }
      if (hr > prevHr + 15) {
        recommendations.add(
          "Your heart rate has jumped by more than 15 bpm compared to your previous entry (from $prevHr to $hr). This might reflect temporary stress or activity, but if you haven’t been exercising, consider what’s changed—too much coffee, poor sleep, or anxiety? Take time to unwind with a calming activity like reading or a warm bath.",
        );
      }
      if (weight > prevWeight + 2) {
        recommendations.add(
          "Your weight has increased by more than 2 kg since your last record (from $prevWeight to $weight). This could be water retention or diet-related. Cut back on salty or carb-heavy meals for a few days and increase your water intake to flush out excess fluids. If it’s consistent, reassess your calorie intake and activity level.",
        );
      }
    }

    return recommendations.isEmpty
        ? [
          "All your latest vitals (BP: $bpSys/$bpDia mmHg, HR: $hr bpm, Temp: $temp°C, Weight: $weight kg) are within normal ranges. Great job! Keep up your healthy habits, including a balanced diet, regular exercise (150 minutes weekly), and consistent sleep (7-9 hours nightly) to stay on track.",
        ]
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
                "Recommendations:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...generateRecommendations().map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Text("• $rec", textAlign: TextAlign.justify),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Health Trends:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 5,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 20, height: 20, color: Colors.blue),
                      SizedBox(width: 5),
                      Text("BP Systolic"),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 20, height: 20, color: Colors.red),
                      SizedBox(width: 5),
                      Text("Heart Rate"),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 20, height: 20, color: Colors.green),
                      SizedBox(width: 5),
                      Text("Temp (°C x 5)"),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 20, height: 20, color: Colors.orange),
                      SizedBox(width: 5),
                      Text("Weight"),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              buildLineChart(),
            ],
          ),
        ),
      ),
    );
  }
}
