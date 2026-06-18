import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/log_provider.dart';

class InputFormScreen extends StatefulWidget {
  const InputFormScreen({super.key});

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen> {
  final _turbidityController = TextEditingController();
  String _selectedLight = 'Normal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulate Sensor Data')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _turbidityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Raw Turbidity (NTU)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedLight,
              isExpanded: true,
              underline: const SizedBox(),
              items: ['Low', 'Normal', 'High'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedLight = newValue!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                if (_turbidityController.text.isNotEmpty) {
                  final rawVal = double.parse(_turbidityController.text);
                  Provider.of<LogProvider>(context, listen: false)
                      .addManualReading(rawVal, _selectedLight);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data processed and sent to Dashboard!')),
                  );
                  _turbidityController.clear();
                }
              },
              child: const Text('Process Data', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}