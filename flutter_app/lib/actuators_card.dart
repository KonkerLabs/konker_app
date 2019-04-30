import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:vibrate/vibrate.dart';
import 'package:torch/torch.dart';
import 'package:audioplayers/audioplayers.dart';
import 'konker_connection.dart';
import 'cutom_logging.dart';
import 'custom_icons.dart';

class ActuatorsCard extends StatefulWidget {
  @override
  _ActuatorsCardState createState() => _ActuatorsCardState();
}

class _ActuatorsCardState extends State<ActuatorsCard> {
  bool _vibrationEnabled = false;
  bool _flashlightEnabled = false;
  bool _soundEnabled = false;
  AudioPlayer audioPlayer = new AudioPlayer();

  void toggleVibration() {
    setState(() {
      _vibrationEnabled = !_vibrationEnabled;
    });
    if (_vibrationEnabled) {
      KonkerCommunication().subscribe('vibra', vibrate);
    } else {
      KonkerCommunication().unsubscribe('vibra');
    }
    Log().print("Vibration switched ${_vibrationEnabled ? 'on' : 'off'}");
  }

  void flash(String data) async {
    try {
      Map<String, dynamic> dataJson = jsonDecode(data);

      if (dataJson['flash']) {
        Torch.turnOn();
      } else {
        Torch.turnOff();
      }
    } on FormatException catch (e) {
      Log().outputError("JSON parsing of $data failed. $e");
    } catch (e) {
      Log().outputError("Failed to handle $data. $e");
    }
  }

  void play(String data) async {
    try {
      Map<String, dynamic> dataJson = jsonDecode(data);
      switch (dataJson['command']) {
        case 'play':
          int result = await audioPlayer.play(
              "https://ia800200.us.archive.org/17/items/Dub_Triangle/Dub_Triangle_23_128_64kb.mp3");
          if (result == 1) {
            Log().print('Start playing!');
          } else {
            Log().print('Playing MP3 failed');
          }
          break;
        case 'pause':
          audioPlayer.pause();
          break;
        case 'stop':
          audioPlayer.stop();
          break;
        case 'resume':
          audioPlayer.resume();
          break;
      }
    } on FormatException catch (e) {
      Log().outputError("JSON parsing of $data failed. $e");
    } catch (e) {
      Log().outputError("Failed to handle $data. $e");
    }
  }

  void toggleSound() {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
    if (_soundEnabled) {
      KonkerCommunication().subscribe('music', play);
    } else {
      KonkerCommunication().unsubscribe('music');
      Torch.turnOff();
    }
    Log().print("Sound switched ${_soundEnabled ? 'on' : 'off'}");
  }

  void toggleFlash() {
    setState(() {
      _flashlightEnabled = !_flashlightEnabled;
    });
    if (_flashlightEnabled) {
      KonkerCommunication().subscribe('flash', flash);
    } else {
      KonkerCommunication().unsubscribe('flash');
      Torch.turnOff();
    }
    Log().print("Flash switched ${_vibrationEnabled ? 'on' : 'off'}");
  }

  void vibrate(String data) async {
    try {
      bool canVibrate = await Vibrate.canVibrate;
      if(!canVibrate){
        Log().outputError("Vibration not supported.");
      }
      Map<String, dynamic> dataJson = jsonDecode(data);

      final List<Duration> pauses = [];
      for (int i = 0; i < dataJson['vibrate'] - 1; i++) {
        pauses.add(Duration(milliseconds: 500));
      }
      Vibrate.vibrateWithPauses(pauses);
    } on FormatException catch (e) {
      Log().outputError("JSON parsing of $data failed. $e");
    } catch (e) {
      Log().outputError("Failed to handle $data. $e");
    }
  }

  void openInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Actuators"),
          content: new SingleChildScrollView(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                    "After enabling an actuator and pressing <Play> the device subscribes to the corresponding MQTT channel (vibra, music, flash)."),
                SizedBox(height: 10),
                Text(
                  "Vibration",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                    "To vibrate the phone for e.g. 3 times a JSON object like this is expected:"),
                Text(
                  "{\n '_ts': 1556636392685,\n 'vibrate': 3 \n}",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14.0),
                ),
                SizedBox(height: 10),
                Text(
                  "Sound",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                    "To controll the playback of the music a JSON object like this is expected:"),
                Text(
                  "{\n '_ts': 1556636392685,\n 'command': '<play/pause/stop/resume>' \n}",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14.0),
                ),
                SizedBox(height: 10),
                Text(
                  "Flash",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                    "To control the state of the flashlight a JSON object like this is expected:"),
                Text(
                  "{\n '_ts': 1556636392685,\n 'flash': <true/false> \n}",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14.0),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Here are some actuators to use:',
                  style: Theme.of(context).textTheme.headline,
                ),
                IconButton(
                  icon: Icon(IconFont.info_outline),
                  tooltip: 'Infos',
                  onPressed: openInfoDialog,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Switch(
                        value: _vibrationEnabled,
                        onChanged: (value) => {toggleVibration()},
                      ),
                      Text(
                        'Vibration',
                        style: Theme.of(context).textTheme.subhead,
                      ),
                      Text(
                        'vibra',
                        style: Theme.of(context).textTheme.caption,
                      )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Switch(
                        value: _soundEnabled,
                        onChanged: (value) => {toggleSound()},
                      ),
                      Text(
                        'Sound',
                        style: Theme.of(context).textTheme.subhead,
                      ),
                      Text(
                        'music',
                        style: Theme.of(context).textTheme.caption,
                      )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Switch(
                        value: _flashlightEnabled,
                        onChanged: (value) => {toggleFlash()},
                      ),
                      Text(
                        'Flashlight',
                        style: Theme.of(context).textTheme.subhead,
                      ),
                      Text(
                        'flash',
                        style: Theme.of(context).textTheme.caption,
                      )
                    ],
                  ),
                ]),
          ],
        ),
      ),
    );
  }
}
