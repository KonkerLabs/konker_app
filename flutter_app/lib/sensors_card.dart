import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors/sensors.dart';
import 'konker_connection.dart';
import 'custom_icons.dart';

class SensorsCard extends StatefulWidget {
  @override
  _SensorsCardState createState() => _SensorsCardState();
}

class _SensorsCardState extends State<SensorsCard> {
  var geolocator = Geolocator();
  var locationOptions =
      LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  bool _gyroEnabled = false;
  bool _gpsEnabled = false;
  bool _accEnabled = false;

  void openInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Sensors"),
          content: new SingleChildScrollView(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                    "Sensors send data when available and after <Play> was pressed, but waits between two events of the same sensor at least ${KonkerCommunication().minPause} seconds."),
                SizedBox(height: 10),
                Text(
                  "GPS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                    "Publishes location data to the location channel and altitude data to the altitude channel.:"),
                Text(
                  "{\n '_ts': 1556636392685,\n '_lat': -23.55,\n '_lon': -46.73 \n}",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14.0),
                ),
                SizedBox(height: 10),
                Text(
                  "Accelerometer/Gyroscope",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                    "Sends Gyroscope and accelerometer data to the corresponding channels:"),
                Text(
                  "{\n '_ts': 1556636392685,\n 'x': 0.23,\n 'y': 4.26,\n 'z': 8.98 \n}",
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
    StreamSubscription<Position> positionStream = geolocator
        .getPositionStream(locationOptions)
        .listen((Position position) {
      if (_gpsEnabled) {
        var body = {
          '_ts': DateTime.now().millisecondsSinceEpoch,
          '_lat': position.latitude,
          '_lon': position.longitude
        };
        setState(() {
          KonkerCommunication().publish('location', body);
        });
        body = {
          '_ts': DateTime.now().millisecondsSinceEpoch,
          'val1': position.altitude
        };
        KonkerCommunication().publish('location', body);
      }
    });
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (_accEnabled) {
        var body = {
          '_ts': DateTime.now().millisecondsSinceEpoch,
          'x': event.x,
          'y': event.y,
          'z': event.z
        };setState(() {
          setState(() {
            KonkerCommunication().publish('accelerometer', body);
          });
        });
      }
    });

    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (_gyroEnabled) {
        var body = {
          '_ts': DateTime.now().millisecondsSinceEpoch,
          'x': event.x,
          'y': event.y,
          'z': event.z
        };
        setState(() {
          KonkerCommunication().publish('gyroscope', body);
        });
      }
    });

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
                Row(
                  children: <Widget>[
                    Icon(
                      IconFont.cloud_upload,
                      color: KonkerCommunication().paused ||
                              !(_gpsEnabled || _gyroEnabled || _accEnabled)
                          ? Theme.of(context).hintColor
                          : KonkerCommunication().sending
                              ? Theme.of(context).accentColor
                              : Theme.of(context).primaryColor,
                    ),
                    Padding(
                      padding: EdgeInsets.all(5),
                    ),
                    Text(
                      'Sensors',
                      style: Theme.of(context).textTheme.headline,
                    ),
                  ],
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
                        value: _gpsEnabled,
                        onChanged: (value) =>
                            {setState(() => _gpsEnabled = value)},
                      ),
                      Text(
                        'GPS',
                        style: Theme.of(context).textTheme.subhead,
                      ),
                      Text(
                        'location/altitude',
                        style: Theme.of(context).textTheme.caption,
                      )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Switch(
                        value: _accEnabled,
                        onChanged: (value) =>
                            {setState(() => _accEnabled = value)},
                      ),
                      Text(
                        'Accelerometer',
                        style: Theme.of(context).textTheme.subhead,
                      ),
                      Text(
                        'accelerometer',
                        style: Theme.of(context).textTheme.caption,
                      )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Switch(
                        value: _gyroEnabled,
                        onChanged: (value) =>
                            {setState(() => _gyroEnabled = value)},
                      ),
                      Text(
                        'Gyroscope',
                        style: Theme.of(context).textTheme.subhead,
                      ),
                      Text(
                        'gyroscope',
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
