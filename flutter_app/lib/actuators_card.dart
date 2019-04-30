
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:vibrate/vibrate.dart';
import 'package:torch/torch.dart';
import 'package:audioplayers/audioplayers.dart';
import 'konker_connection.dart';
import 'cutom_logging.dart';

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
    Log().print("Vibration switched ${_vibrationEnabled?'on':'off'}");
  }

  void flash(String data) async {
    Map<String, dynamic> dataJson = jsonDecode(data);

    if (dataJson['flash']) {
      Torch.turnOn();
    } else {
      Torch.turnOff();
    }
  }

  void play(String data) async {
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
    Log().print("Sound switched ${_soundEnabled?'on':'off'}");

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
    Log().print("Flash switched ${_vibrationEnabled?'on':'off'}");

  }

  void vibrate(String data) async {
    bool canVibrate = await Vibrate.canVibrate;
    Map<String, dynamic> dataJson = jsonDecode(data);

    final List<Duration> pauses = [];
    for (int i = 0; i < dataJson['times'] - 1; i++) {
      pauses.add(Duration(milliseconds: 500));
    }
    Vibrate.vibrateWithPauses(pauses);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Here are some actuators to use:',
              style: Theme.of(context).textTheme.headline,
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
