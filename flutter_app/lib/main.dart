import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:sensors/sensors.dart';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'custom_icons.dart';
import 'package:vibrate/vibrate.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primaryColor: Color.fromRGBO(0, 75, 155, 1),
          accentColor: Color.fromRGBO(180, 15, 15, 1),
          primaryColorDark: Color.fromRGBO(0, 60, 120, 1)),
      home: MyHomePage(title: 'Konker Sensors'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class KonkerCommunication {
  Map<String, DateTime> _lastSent = Map();
  int minPause = 3;
  static KonkerCommunication _instance = null;
  String httpPubLink = '';
  String httpSubLink = '';
  String user = '';
  String pass = '';
  bool paused = true;
  Function errorFunc = print;

  factory KonkerCommunication() {
    if (_instance == null) {
      _instance = new KonkerCommunication._internal();
    }
    return _instance;
  }

  KonkerCommunication._internal() {}

  void sendToKonker(BuildContext context, String channel, Map body) async {
    if (!paused &&
        (!_lastSent.containsKey(channel) ||
            DateTime.now().difference(_lastSent[channel]).inSeconds >=
                minPause)) {
      _lastSent[channel] = DateTime.now();

      print('Sending Data to $httpPubLink/$channel');
      try {
        String basicAuth = 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
        var retval = await http.post('$httpPubLink/$channel',
            body: new JsonEncoder().convert(body),
            headers: {
              'Content-Type': 'application/json',
              'authorization': basicAuth
            });
        if (retval.statusCode != 200)
          errorFunc('Error: ${retval.reasonPhrase}');
      } catch (ex) {
        errorFunc('Sending data to konker failed! $ex');
      }
    }
  }

  Future<http.Response> getFromKonker(
    BuildContext context,
    String channel,
  ) async {
    if (paused) return null;

    print('Sending Data to $httpSubLink/$channel');
    try {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
      return http.get('$httpSubLink/$channel', headers: {
        'Content-Type': 'application/json',
        'authorization': basicAuth
      });
    } catch (ex) {
      paused = true;
      print(ex);
      Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("Sending data failed."),
      ));
    }
    return null;
  }

  void setConnectionParams(
      String username, String password, String httpPub, String httpSub) {
    user = username;
    pass = password;
    httpPubLink = httpPub;
    httpSubLink = httpSub;
  }

  void togglePause() {
    paused = !paused;
  }

  void setErrorFunc(Function(String) function) {
    errorFunc = function;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var userNameTEController = TextEditingController();
  var passwordTEController = TextEditingController();
  var httpPubLinkTEController = TextEditingController();
  var httpSubLinkTEController = TextEditingController();
  BuildContext _scaffoldContext;
  bool _paused = true;

  KonkerCommunication sender;

  void scanQR() {
    Future<String> str = new QRCodeReader().scan();
    str.then(callbackQR);
  }

  void callbackQR(String ret) {
    try {
      var result = JsonDecoder().convert(ret);
      print(result);
      userNameTEController.text = result["user"];
      passwordTEController.text = result["pass"];
      var host = result["host"];
      var port = int.parse(result['http'].toString());
      var pub = result['pub'];
      var sub = result['sub'];
      httpPubLinkTEController.text = 'http://$host:$port/$pub';
      httpSubLinkTEController.text = 'http://$host:$port/$sub';
      refreshConnectionParamters('');
      sender
          .getFromKonker(_scaffoldContext, 'out')
          .then((http.Response resp) => {print(resp)});
    } catch (e) {
      Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(
        content: new Text("QR Code invalid."),
      ));
    }
  }

  void refreshConnectionParamters(String _) {
    KonkerCommunication().setConnectionParams(
        userNameTEController.text,
        passwordTEController.text,
        httpPubLinkTEController.text,
        httpSubLinkTEController.text);
  }

  void errorOut(String err) {
    if (!KonkerCommunication().paused) {
      setState(() {
        KonkerCommunication().paused = true;
        print('ERROR $err setState');
      });
    }
    Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(
      content: new Text(err),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    KonkerCommunication().setErrorFunc(errorOut);

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Icon(IconFont.konker_icon_white),
      ),
      body: new Builder(
        builder: (BuildContext context) {
          _scaffoldContext = context;
          return Column(children: <Widget>[
            Card(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Enter your Konker device credential here:',
                      style: Theme.of(context).textTheme.headline,
                    ),
                    ListTile(
                      title: TextField(
                        controller: userNameTEController,
                        onChanged: refreshConnectionParamters,
                        decoration: InputDecoration(hintText: 'username'),
                      ),
                      leading: Icon(
                        IconFont.person,
                        color: Theme.of(context).accentColor,
                      ),
                    ),
                    ListTile(
                      title: TextField(
                        controller: passwordTEController,
                        onChanged: refreshConnectionParamters,
                        decoration: InputDecoration(hintText: 'password'),
                      ),
                      leading: Icon(
                        IconFont.vpn_key,
                        color: Theme.of(context).accentColor,
                      ),
                    ),
                    ListTile(
                      title: TextField(
                        controller: httpPubLinkTEController,
                        onChanged: refreshConnectionParamters,
                        decoration: InputDecoration(hintText: 'server pub url'),
                      ),
                      leading: Icon(
                        IconFont.cloud_upload,
                        color: Theme.of(context).accentColor,
                      ),
                    ),
                    ListTile(
                      title: TextField(
                        controller: httpSubLinkTEController,
                        onChanged: refreshConnectionParamters,
                        decoration: InputDecoration(hintText: 'server sub url'),
                      ),
                      leading: Icon(
                        IconFont.cloud_download,
                        color: Theme.of(context).accentColor,
                      ),
                    ),
                    ButtonTheme.bar(
                      child: ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: <Widget>[
                          FlatButton(
                            onPressed: scanQR,
                            child: Icon(
                              IconFont.qrcode,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            SensorsCard(),
            ActuatorsCard()
          ]);
        },

        /*Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Your current location:',
            ),
            Text(
              '$_location',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      )*/
      ),
      floatingActionButton: FloatingActionButton(
        //onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: KonkerCommunication().paused
            ? Icon(IconFont.play_arrow)
            : Icon(IconFont.pause),
        onPressed: () {
          setState(() {
            KonkerCommunication().togglePause();
          });
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class ActuatorsCard extends StatefulWidget {
  @override
  _ActuatorsCardState createState() => _ActuatorsCardState();
}

class _ActuatorsCardState extends State<ActuatorsCard> {
  bool _vibrationEnabled = false;
  bool _flashlightEnabled = false;
  bool _soundEnabled = false;

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
                        onChanged: (value) =>
                            {setState(() => _vibrationEnabled = value)},
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
                        onChanged: (value) =>
                            {setState(() => _soundEnabled = value)},
                      ),
                      Text(
                        'Sound',
                        style: Theme.of(context).textTheme.subhead,
                      ),
                      Text(
                        'biep',
                        style: Theme.of(context).textTheme.caption,
                      )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Switch(
                        value: _flashlightEnabled,
                        onChanged: (value) =>
                            {setState(() => _flashlightEnabled = value)},
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
  bool _paused = true;

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
        KonkerCommunication().sendToKonker(context, 'location', body);
        body = {
          '_ts': DateTime.now().millisecondsSinceEpoch,
          'val1': position.altitude
        };
        KonkerCommunication().sendToKonker(context, 'location', body);
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
        KonkerCommunication().sendToKonker(context, 'accelerometer', body);
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
        KonkerCommunication().sendToKonker(context, 'gyroscope', body);
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
