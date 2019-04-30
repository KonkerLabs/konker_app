import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors/sensors.dart';
import 'konker_connection.dart';

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
        KonkerCommunication().publish('location', body);
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
          'val1': event.x,
          'val2': event.y,
          'val3': event.z
        };
        KonkerCommunication().publish('accelerometer', body);
      }
    });

    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (_gyroEnabled) {
        var body = {
          '_ts': DateTime.now().millisecondsSinceEpoch,
          'val1': event.x,
          'val2': event.y,
          'val3': event.z
        };
        KonkerCommunication().publish('gyroscope', body);
      }
    });

    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'What data do you want to send?',
              style: Theme.of(context).textTheme.headline,
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
