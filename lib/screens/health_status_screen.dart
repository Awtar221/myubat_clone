import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';

class HealthStatusScreen extends StatelessWidget {
  const HealthStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Status'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDailyAssessment(context, healthProvider),
            const SizedBox(height: 16),
            _buildTemperatureList(healthProvider),
            const SizedBox(height: 16),
            _buildTestResults(healthProvider),
            const SizedBox(height: 16),
            _buildHealthTips(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHealthAssessmentDialog(context, healthProvider),
        icon: const Icon(Icons.add),
        label: const Text('Log Health'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _buildDailyAssessment(BuildContext context, HealthProvider healthProvider) {
    final latestRecord = healthProvider.healthRecords.isNotEmpty
        ? healthProvider.healthRecords.last
        : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Assessment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (latestRecord != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Temperature',
                    '${latestRecord.temperature}°C',
                    Icons.thermostat,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Symptoms',
                    latestRecord.symptoms.isEmpty ? 'None' : '${latestRecord.symptoms.length}',
                    Icons.medical_services,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Last updated: ${DateFormat('dd MMM yyyy, HH:mm').format(latestRecord.date)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ] else
            const Text('No health records yet. Log your first assessment!'),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureList(HealthProvider healthProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temperature Records (Last 7 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...healthProvider.healthRecords.reversed.take(7).map((record) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.thermostat,
                    color: _getTemperatureColor(record.temperature),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.temperature}°C',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getTemperatureColor(record.temperature),
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(record.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (record.symptoms.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 2.0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${record.symptoms.length} symptom${record.symptoms.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp >= 37.5) return Colors.red;
    if (temp >= 37.0) return Colors.orange;
    return Colors.green;
  }

  Widget _buildTestResults(HealthProvider healthProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (healthProvider.testResults.isEmpty)
            const Text('No test results available')
          else
            ...healthProvider.testResults.map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTestResultItem(test),
            )),
        ],
      ),
    );
  }

  Widget _buildTestResultItem(TestResult test) {
    final isNegative = test.result.toLowerCase().contains('negative');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNegative
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNegative ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNegative ? Icons.check_circle : Icons.warning,
            color: isNegative ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.testType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Result: ${test.result}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isNegative ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(test.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  test.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A),
            const Color(0xFF1E3A8A).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Health Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('Wash hands frequently with soap and water'),
          _buildTipItem('Wear mask in crowded places'),
          _buildTipItem('Maintain social distancing'),
          _buildTipItem('Get vaccinated and boosted'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthAssessmentDialog(BuildContext context, HealthProvider healthProvider) {
    double temperature = 36.5;
    List<String> selectedSymptoms = [];

    final symptoms = [
      'Fever',
      'Cough',
      'Sore Throat',
      'Headache',
      'Body Ache',
      'Loss of Taste/Smell',
      'Difficulty Breathing',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Daily Health Assessment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Temperature (°C)'),
                Slider(
                  value: temperature,
                  min: 35.0,
                  max: 42.0,
                  divisions: 70,
                  label: temperature.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      temperature = value;
                    });
                  },
                ),
                Text('${temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Symptoms'),
                ...symptoms.map((symptom) => CheckboxListTile(
                  title: Text(symptom),
                  value: selectedSymptoms.contains(symptom),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedSymptoms.add(symptom);
                      } else {
                        selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                healthProvider.addHealthRecord(
                  HealthRecord(
                    date: DateTime.now(),
                    temperature: temperature,
                    symptoms: selectedSymptoms,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Health record logged successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}