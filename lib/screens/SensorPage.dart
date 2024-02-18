import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class SensorPage extends StatefulWidget {
  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  late MqttServerClient client;
  String broker = 'broker.hivemq.com';
  int port = 1883;
  String topicLight = 'LIGHTPERCENTAGE';
  String topicPirSensor = 'PIRSENSOR';
  String topicLdrSensor = 'LDRSENSOR';
  String topicCurtainsStatus = 'STATCURTAINS';
  String lightValue = '';
  String pirSensorValue = '';
  String ldrSensorValue = '';
  String curtainsStatusValue = '';

  @override
  void initState() {
    super.initState();
    client = MqttServerClient.withPort(broker, 'flutter_client', port);
    _connect();
  }

  void _connect() async {
    try {
      await client.connect();
      // print('Connected');
      _subscribeToLightTopic();
      _subscribeToPirSensorTopic();
      _subscribeToLdrSensorTopic();
      _subscribeToCurtainsStatusTopic();
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    client.disconnect();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connect();
  }

  void _subscribeToLightTopic() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe(topicLight, MqttQos.atLeastOnce);
      client.updates
          ?.where((List<MqttReceivedMessage<MqttMessage>> c) =>
              c[0].topic == topicLight)
          .listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('Received Light Percentage message: $message');
        setState(() {
          lightValue = message;
        });
      });
    }
  }

  void _subscribeToPirSensorTopic() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe(topicPirSensor, MqttQos.atLeastOnce);
      client.updates
          ?.where((List<MqttReceivedMessage<MqttMessage>> c) =>
              c[0].topic == topicPirSensor)
          .listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('Received PIR Sensor message: $message');
        setState(() {
          pirSensorValue = message;
        });
      });
    }
  }

  void _subscribeToLdrSensorTopic() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe(topicLdrSensor, MqttQos.atLeastOnce);
      client.updates
          ?.where((List<MqttReceivedMessage<MqttMessage>> c) =>
              c[0].topic == topicLdrSensor)
          .listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('Received LDR Sensor message: $message');
        setState(() {
          ldrSensorValue = message;
        });
      });
    }
  }

  void _subscribeToCurtainsStatusTopic() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.subscribe(topicCurtainsStatus, MqttQos.atLeastOnce);
      client.updates
          ?.where((List<MqttReceivedMessage<MqttMessage>> c) =>
              c[0].topic == topicCurtainsStatus)
          .listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        print('Received Curtains Status message: $message');
        setState(() {
          curtainsStatusValue = message;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 8,
        title: Text(
          'Smart Curtains',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            client.disconnect();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SensorTile(
              icon: Icons.lightbulb, // Icône pour LIGHTPERCENTAGE
              sensorName: 'Light Percentage',
              sensorValue: lightValue,
            ),
            SensorTile(
              icon: Icons.sensor_door, // Icône pour PIRSENSOR
              sensorName: 'PIR Sensor',
              sensorValue: pirSensorValue,
            ),
            SensorTile(
              icon: Icons.thermostat, // Icône pour LDRSENSOR
              sensorName: 'LDR Sensor',
              sensorValue: ldrSensorValue,
            ),
            SensorTile(
              icon: Icons.curtains, // Icône pour STATCURTAINS
              sensorName: 'Curtains Status',
              sensorValue: curtainsStatusValue,
            ),
          ],
        ),
      ),
    );
  }
}

class SensorTile extends StatelessWidget {
  final IconData icon;
  final String sensorName;
  final String sensorValue;

  const SensorTile({
    Key? key,
    required this.icon,
    required this.sensorName,
    required this.sensorValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.95,
      margin: EdgeInsets.symmetric(vertical: 15),
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.8),
            spreadRadius: 5,
            blurRadius: 2,
            offset: Offset(1, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 35,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sensorName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                sensorValue,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
