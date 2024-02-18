import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:sfm_app/screens/SensorPage.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isHome = true;
  bool isSetting = false;
  late MqttServerClient client;
  String broker = 'broker.hivemq.com';
  int port = 1883;
  String topicLight = 'LIGHTPERCENTAGE';
  String topicCommande = 'rideaux/commande';
  String topicMode = 'rideaux/mode';
  String receivedMessage = '';
  late Timer timer;
  bool isManualMode = false;
  DateTime selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    client = MqttServerClient.withPort(broker, 'flutter_client', port);

    _connect();
  }

  @override
  void dispose() {
    super.dispose();
    client.disconnect();
  }

  void _connect() async {
    try {
      await client.connect();
      print('Connected to MQTT server');
    } catch (e) {
      print('Failed to connect to MQTT server: $e');
    }
  }

  void _subscribeToTopic(String topic) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe(topic, MqttQos.atLeastOnce);
      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('Received message: $message');
        setState(() {
          if (topic == topicLight) {
            receivedMessage = message;
          }
        });
      });
    }
  }

  void _sendMessage(String message, String topic) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    } else {
      print("La connexion MQTT n'est pas établie.");
    }
  }

  void _refresh() {
    _subscribeToTopic(topicLight);
  }

  void _showDateTimePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Sélectionner l'heure"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text("Heure: "),
                      SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedDateTime.hour,
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                selectedDateTime.year,
                                selectedDateTime.month,
                                selectedDateTime.day,
                                newValue,
                                selectedDateTime.minute,
                              );
                              String formattedTime =
                                  "${selectedDateTime.hour}:${selectedDateTime.minute}";
                              _sendMessage(formattedTime, 'rideaux/rtc');
                            });
                          }
                        },
                        items: List.generate(24, (index) {
                          return DropdownMenuItem<int>(
                            value: index,
                            child: Text(index.toString().padLeft(2, '0')),
                          );
                        }),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text("Minutes: "),
                      SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedDateTime.minute,
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                selectedDateTime.year,
                                selectedDateTime.month,
                                selectedDateTime.day,
                                selectedDateTime.hour,
                                newValue,
                              );
                              String formattedTime =
                                  "${selectedDateTime.hour}:${selectedDateTime.minute}";
                              _sendMessage(formattedTime, 'rideaux/rtc');
                            });
                          }
                        },
                        items: List.generate(60, (index) {
                          return DropdownMenuItem<int>(
                            value: index,
                            child: Text(index.toString().padLeft(2, '0')),
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Envoyer la date sélectionnée à la broker
                    String formattedTime =
                        "${selectedDateTime.hour}:${selectedDateTime.minute}";
                    _sendMessage(formattedTime, 'rideaux/rtc');
                    Navigator.of(context).pop();
                  },
                  child: Text("Valider"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Annuler"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 8,
          title: Text(
            'Smart Curtains',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          actions: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isManualMode
                    ? Colors.greenAccent[700]
                    : Colors.redAccent[700],
                borderRadius: BorderRadius.circular(0.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isManualMode ? 'Manual' : 'Automatic',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Switch(
                    value: isManualMode,
                    onChanged: (value) {
                      setState(() {
                        isManualMode = value;
                        if (isManualMode) {
                          _sendMessage('manual', topicMode);
                        } else {
                          _sendMessage('auto', topicMode);
                        }
                      });
                    },
                    activeColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Column(
                children: [
                  Row(),
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 0.02,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.width * 0.05,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IgnorePointer(
                              ignoring: !isManualMode,
                              child: Opacity(
                                opacity: isManualMode ? 1.0 : 0.5,
                                child: CustomButton(
                                  color: Color.fromARGB(255, 235, 232, 232),
                                  icon: Icons.lock,
                                  label: 'close',
                                  iconColor: Colors.white,
                                  iconBackgroundColor: Colors.redAccent,
                                  labelColor: Colors.black,
                                  onPressed: () {
                                    _sendMessage('close', 'rideaux/commande');
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.2,
                            ),
                            IgnorePointer(
                              ignoring: !isManualMode,
                              child: Opacity(
                                opacity: isManualMode ? 1.0 : 0.5,
                                child: CustomButton(
                                  color: Color.fromARGB(255, 235, 232, 232),
                                  icon: Icons.lock_open,
                                  label: 'open',
                                  iconColor: Colors.white,
                                  iconBackgroundColor:
                                      Colors.lightGreenAccent.shade700,
                                  labelColor: Colors.black,
                                  onPressed: () {
                                    _sendMessage('open', 'rideaux/commande');
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.width * 0.05),
                        Row(
                          children: [
                            IgnorePointer(
                              ignoring: !isManualMode,
                              child: Opacity(
                                opacity: isManualMode ? 1.0 : 0.5,
                                child: Expanded(
                                  child: CustomButton(
                                    color: Color.fromARGB(255, 235, 232, 232),
                                    icon: Icons.schedule,
                                    label:
                                        'planning                                      ',
                                    iconColor: Colors.white,
                                    iconBackgroundColor: Colors.blue,
                                    labelColor: Colors.black,
                                    onPressed: () {
                                      _showDateTimePickerDialog(context);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(
                    color: Colors.black,
                    thickness: 3.0,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomButton(
                        color: Color.fromARGB(255, 235, 232, 232),
                        icon: Icons.sensor_window,
                        label: 'sensors',
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.redAccent,
                        labelColor: Colors.black,
                        onPressed: () {
                          client.disconnect();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SensorPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 10,
                          top: 10,
                        ),
                        child: Image.asset(
                          'images/smart.jpg',
                          width: 340,
                          height: 320,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(0, -5),
                          blurRadius: 2,
                        ),
                      ],
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.home,
                            color: isHome ? Colors.blueAccent : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              isHome = true;
                              isSetting = false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Appliance extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  Appliance({required this.color, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.all(5),
        width: MediaQuery.of(context).size.width * 0.43,
        height: MediaQuery.of(context).size.width * 0.15,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.1,
              height: MediaQuery.of(context).size.width * 0.1,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 25,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              width: 20,
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomSpecAppliance extends StatelessWidget {
  final String imagePath;
  final String label;
  final double imgHt;
  final double imgWidth;
  RoomSpecAppliance(
      {required this.label,
      required this.imgWidth,
      required this.imgHt,
      required this.imagePath});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.all(5),
        width: MediaQuery.of(context).size.width * 0.43,
        height: MediaQuery.of(context).size.width * 0.45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  height: MediaQuery.of(context).size.width * imgHt,
                  width: MediaQuery.of(context).size.width * imgWidth,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color labelColor;
  final VoidCallback onPressed;

  const CustomButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.labelColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55.0,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          primary: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40.0,
              width: 40.0,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.0),
                color: iconBackgroundColor,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
