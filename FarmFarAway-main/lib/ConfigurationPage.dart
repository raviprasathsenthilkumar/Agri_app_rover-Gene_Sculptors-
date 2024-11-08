import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ConfigurationPage extends StatefulWidget {
  @override
  _ConfigurationPageState createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage>
    with SingleTickerProviderStateMixin {
  late DatabaseReference _databaseReference;
  bool _isMotorOn = false;
  double _selectedTimeInHours = 1.0;
  final TextEditingController _timeController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref();
    _loadInitialValues();

    // Animation controller for toggle switch
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _loadInitialValues() async {
    final snapshot = await _databaseReference.child('plant_health').get();
    final data = snapshot.value as Map?;
    if (data != null) {
      setState(() {
        _isMotorOn = data['motor'] ?? false;
        _selectedTimeInHours = (data['watering_time'] ?? 1).toDouble();
        _timeController.text = (_selectedTimeInHours * 60).toStringAsFixed(1);
      });
    }
  }

  void _toggleMotor(bool? value) {
    setState(() {
      _isMotorOn = value ?? false;
    });
    _databaseReference.child('plant_health').update({'motor': _isMotorOn});

    // Trigger animation
    _isMotorOn
        ? _animationController.forward()
        : _animationController.reverse();
  }

  void _updateWateringTime(double value) {
    setState(() {
      _selectedTimeInHours = value;
      _timeController.text =
          (value * 60).toStringAsFixed(1); // Update TextField with minutes
    });
    _databaseReference
        .child('plant_health')
        .update({'time': _selectedTimeInHours * 60}); // Store as minutes
  }

  void _updateWateringTimeFromText(String value) {
    final double? parsedValue = double.tryParse(value);
    if (parsedValue != null && parsedValue >= 0.1 && parsedValue <= 24 * 60) {
      setState(() {
        _selectedTimeInHours = parsedValue / 60;
        _timeController.text = parsedValue.toStringAsFixed(1);
      });
      _databaseReference.child('plant_health').update({'time': parsedValue});
    } else {
      // Handle invalid input
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Invalid time value. Must be between 0.1 and 1440 minutes.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend the body to include AppBar
      appBar: AppBar(
        title: Text('Configuration'),
        backgroundColor: Colors.transparent,
        elevation: 0, // Make AppBar transparent
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Motor Switch Card
              _buildCustomCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Motor',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: _isMotorOn,
                      onChanged: _toggleMotor,
                      activeColor: Colors.greenAccent,
                      inactiveThumbColor: Colors.redAccent,
                      activeTrackColor: Colors.green.withOpacity(0.5),
                      inactiveTrackColor: Colors.red.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Watering Time Slider Card
              _buildCustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watering Time: ${_selectedTimeInHours.toStringAsFixed(1)} hours',
                      style: TextStyle(fontSize: 18),
                    ),
                    Slider(
                      value: _selectedTimeInHours,
                      min: 0.5,
                      max: 24.0,
                      divisions: 47, // Adjust divisions to match slider range
                      label: _selectedTimeInHours.toStringAsFixed(1),
                      activeColor: Colors.tealAccent,
                      inactiveColor: Colors.grey,
                      onChanged: _updateWateringTime,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Watering Time Text Input
              _buildCustomCard(
                child: TextField(
                  controller: _timeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Enter Watering Time (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _updateWateringTimeFromText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
