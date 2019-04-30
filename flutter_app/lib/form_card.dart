
import 'package:flutter/material.dart';
import 'custom_icons.dart';
import 'package:flutter/services.dart';
import 'konker_connection.dart';
import 'dart:convert';
import 'package:qrcode_reader/qrcode_reader.dart';
import 'cutom_logging.dart';




class FormCard extends StatefulWidget {
  @override
  _FormCardState createState() => _FormCardState();
}

class _FormCardState extends State<FormCard> {
  var userNameTEController = TextEditingController();
  var passwordTEController = TextEditingController();
  var mqttPubLinkTEController = TextEditingController();
  var mqttPortTEController = TextEditingController();
  var mqttSubLinkTEController = TextEditingController();
  var mqttHostTEController = TextEditingController();

  void scanQR() {
    Future<String> str = new QRCodeReader().scan();
    str.then(callbackQR);
  }

  void callbackQR(String ret) {
    try {
      var result = JsonDecoder().convert(ret);
      Log().print(result);
      userNameTEController.text = result["user"];
      passwordTEController.text = result["pass"];
      mqttHostTEController.text = result["host-mqtt"];
      mqttPortTEController.text = result['mqtt-tls'].toString();
      mqttPubLinkTEController.text = result['pub'];
      mqttSubLinkTEController.text = result['sub'];
      if (!mqttPubLinkTEController.text.startsWith('data/')) {
        mqttPubLinkTEController.text = 'data/${userNameTEController.text}/pub';
      }
      if (!mqttSubLinkTEController.text.startsWith('data/'))
        mqttSubLinkTEController.text = 'data/${userNameTEController.text}/sub';
      refreshConnectionParamters('');
      Log().print('QR Code successfully read.');
    } catch (e) {
      Log().outputError("QR Code invalid.");
    }
  }

  void refreshConnectionParamters(String _) {
    KonkerCommunication().setConnectionParams(
        userNameTEController.text,
        passwordTEController.text,
        int.parse(mqttPortTEController.text),
        mqttHostTEController.text,
        mqttPubLinkTEController.text,
        mqttSubLinkTEController.text);
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Enter your Konker device credential here:',
              style: Theme
                  .of(context)
                  .textTheme
                  .headline,
            ),
            ListTile(
              title: TextField(
                controller: userNameTEController,
                onChanged: refreshConnectionParamters,
                enabled: KonkerCommunication().paused,
                decoration: InputDecoration(hintText: 'username'),
              ),
              leading: Icon(
                IconFont.person,
                color: Theme
                    .of(context)
                    .accentColor,
              ),
            ),
            ListTile(
              title: TextField(
                controller: passwordTEController,
                enabled: KonkerCommunication().paused,
                onChanged: refreshConnectionParamters,
                decoration: InputDecoration(hintText: 'password'),
              ),
              leading: Icon(
                IconFont.vpn_key,
                color: Theme
                    .of(context)
                    .accentColor,
              ),
            ),
            ListTile(
              title: Row(
                children: <Widget>[
                  Flexible(
                      child: TextField(
                        controller: mqttHostTEController,
                        enabled: KonkerCommunication().paused,
                        onChanged: refreshConnectionParamters,
                        decoration: InputDecoration(hintText: 'host'),
                      ),
                      flex: 3),
                  Flexible(
                      child: TextField(
                        controller: mqttPortTEController,
                        enabled: KonkerCommunication().paused,
                        onChanged: refreshConnectionParamters,
                        decoration: InputDecoration(hintText: 'port'),
                        keyboardType: TextInputType.number,
                      ),
                      flex: 1)
                ],
              ),
              leading: Icon(
                IconFont.insert_link,
                color: Theme
                    .of(context)
                    .accentColor,
              ),
            ),
            ListTile(
              title: TextField(
                controller: mqttPubLinkTEController,
                enabled: KonkerCommunication().paused,
                onChanged: refreshConnectionParamters,
                decoration:
                InputDecoration(hintText: 'server pub url'),
              ),
              leading: Icon(
                IconFont.cloud_upload,
                color: Theme
                    .of(context)
                    .accentColor,
              ),
            ),
            ListTile(
              title: TextField(
                controller: mqttSubLinkTEController,
                enabled: KonkerCommunication().paused,
                onChanged: refreshConnectionParamters,
                decoration:
                InputDecoration(hintText: 'server sub url'),
              ),
              leading: Icon(
                IconFont.cloud_download,
                color: Theme
                    .of(context)
                    .accentColor,
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
    );
  }
}