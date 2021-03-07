import 'package:flutter_mqtt_app/mqtt/state/MQTTAppState.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:async';
import 'dart:io';

import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTManager {
  //Instancias do cliente
  MQTTAppState _currentState;
  MqttServerClient _client;
  String _id;
  String _host;
  String topic;

  //Constructor
  MQTTManager(this._host, this.topic, this._id, this._currentState);

  void initMQTTClient() {
    _client = MqttServerClient(_host, _id);
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.logging(on: true);
    //hadlers
    _client.onDisconnected = onDisconnected;
    _client.onConnected = onConnected;
    _client.onSubscribed = onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_id)
        .withWillTopic('willTopic')
        .withWillMessage('willMessage')
        .startClean();
    print("[MQTT] Mosquito client connecting ...");
  }

  void connect() async {
    assert(_client != null);
    try {
      print("[MQTT] Client connecting ...");
      _currentState.setAppConnectionState(MQTTAppConnectionState.connecting);
      await _client.connect();
    } on Exception catch (e) {
      print("[MQTT] Client error => $e");
      disconnect();
    }
  }

  void disconnect() {
    print("[MQTT] Disconnect ...");
    _client.disconnect();
  }

  void publish(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload);
  }

  //handlers

  void onSubscribed(String topic) {
    print("[MQTT] Client subcribed to $topic");
  }

  void onDisconnected() {
    print("[MQTT] Client disconnection ...");
    _currentState.setAppConnectionState(MQTTAppConnectionState.disconnected);
  }

  void onConnected() {
    _currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    print("[MQTT] Client connected ...");
    _client.subscribe(topic, MqttQos.atLeastOnce);
    _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      _currentState.setReceivedText(payload);
      print('Received message:$payload from topic: ${c[0].topic}>');
    });
  }
}
