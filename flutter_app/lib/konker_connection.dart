import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'cutom_logging.dart';

class KonkerCommunication {
  Map<String, DateTime> _lastSent = Map();
  int minPause = 3;
  static KonkerCommunication _instance;
  String mqttPubLink = '';
  String mqttSubLink = '';
  String user = '';
  String pass = '';
  bool paused = true;
  String mqttHost = '';
  MqttClient mqttClient;

  Map<String, Function(String)> callbacks = Map();

  factory KonkerCommunication() {
    if (_instance == null) {
      _instance = new KonkerCommunication._internal();
    }
    return _instance;
  }

  KonkerCommunication._internal() {}

  //HTTP
  void sendToKonker(BuildContext context, String channel, Map body) async {
    if (!paused &&
        (!_lastSent.containsKey(channel) ||
            DateTime.now().difference(_lastSent[channel]).inSeconds >=
                minPause)) {
      _lastSent[channel] = DateTime.now();

      Log().print('Sending Data to $mqttPubLink/$channel');
      try {
        String basicAuth = 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
        var retval = await http.post('$mqttPubLink/$channel',
            body: new JsonEncoder().convert(body),
            headers: {
              'Content-Type': 'application/json',
              'authorization': basicAuth
            });
        if (retval.statusCode != 200)
          Log().outputError('Error: ${retval.reasonPhrase}');
      } catch (ex) {
        Log().outputError('Sending data to konker failed! $ex');
      }
    }
  }

  void publish(String channel, Map body) async {
    if (!paused &&
        (!_lastSent.containsKey(channel) ||
            DateTime.now().difference(_lastSent[channel]).inSeconds >=
                minPause)) {
      _lastSent[channel] = DateTime.now();

      Log().print('Sending Data to $mqttPubLink/$channel');
      try {
        await mqttConnect();
        final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
        builder.addString(new JsonEncoder().convert(body));
        mqttClient.publishMessage(
            '$mqttPubLink/$channel', MqttQos.exactlyOnce, builder.payload);
      } catch (ex) {
        Log().print(ex);
        Log().outputError('Sending data to konker failed! $ex');
      }
    }
  }

  //HTTP
  Future<http.Response> getFromKonker(
    BuildContext context,
    String channel,
  ) async {
    if (paused) return null;

    Log().print('Try sending Data to $mqttSubLink/$channel');
    try {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
      return http.get('$mqttSubLink/$channel', headers: {
        'Content-Type': 'application/json',
        'authorization': basicAuth
      });
    } catch (ex) {
      paused = true;
      Log().print(ex);
      Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Sending data failed."),
      ));
    }
    return null;
  }

  void subscribe(String topic, Function(String) callback) async {
    if (!topic.startsWith(mqttSubLink)) topic = "$mqttSubLink/$topic";
    callbacks[topic] = callback;

    if (!paused) {
      try {
        await mqttConnect();
        mqttClient.subscribe(topic, MqttQos.exactlyOnce);
        mqttClient.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
          Log().print('update');
          final MqttPublishMessage recMess = c[0].payload;
          final String pt =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          Log().print(pt);

          callbacks[c[0].topic](pt);
        });
        Log().print('subscribe to $topic');
      } catch (ex) {
        Log().print(ex);
        Log().outputError('Subscribing to $topic failed! $ex');
      }
    }
  }

  void unsubscribe(String topic) async {
    if (!topic.startsWith(mqttSubLink)) topic = "$mqttSubLink/$topic";
    callbacks.remove(topic);
    if (!paused) {
      try {
        await mqttConnect();
        mqttClient.unsubscribe(topic);
      } catch (ex) {
        Log().print(ex);
        Log().outputError('Sending data to konker failed! $ex');
      }
    }
  }

  void setConnectionParams(String username, String password, int port,
      String host, String mqttPub, String mqttSub) {
    user = username;
    pass = password;
    mqttPubLink = mqttPub;
    mqttSubLink = mqttSub;
    mqttHost = host;
    mqttClient = MqttClient(host, '');
    mqttClient.port = port;
    mqttClient.secure = true;
    var mqttMessage =
        MqttConnectMessage().withClientIdentifier('test'); // TODO: change
    mqttMessage.authenticateAs(user, pass);
    mqttMessage.withWillQos(MqttQos.exactlyOnce);
    mqttClient.connectionMessage = mqttMessage;
  }

  void mqttConnect() async {
    if (mqttClient == null) {
      throw Exception('No connection info defined.');
    }
    if (mqttClient.connectionStatus.state == MqttConnectionState.connected) {
      Log().print('Already connected');
      return;
    }
    try {
      await mqttClient.connect();
    } on Exception catch (e) {
      mqttClient.disconnect();
      throw Exception('Connecting failed $e');
    }
  }

  void togglePause() async {
    paused = !paused;
    if (paused == false) {
      try {
        await mqttConnect();
        for (var key in callbacks.keys) {
          subscribe(key, callbacks[key]);
        }
      } catch (e) {
        Log().outputError('Starting connection failed: $e');
      }
    } else {
      try {
        await mqttConnect();
        for (var key in callbacks.keys) {
          unsubscribe(key);
        }
        mqttClient.disconnect();
      } catch (e) {
        mqttClient.disconnect();
        Log().outputError('Stopping connection failed: $e');
      }
    }
  }
}
