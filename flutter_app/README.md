# Flutter implementation of the Konker Sensors and Actuators App.
Available in the [Google Play Store](https://play.google.com/store/apps/details?id=com.konker.konkersensors)

## Preparing the flutter application for release
### `key.properties`
Add the `key.properties` file inside the `\android\` files containing the following:
```properties
storePassword=****
keyPassword=****
keyAlias=konker sensor app
storeFile=[path_to_key.jks]
```

### Update the app versioncode and release number
The release number and version code has to be updated in `pubspec.yaml`:
```yaml
version: 3.1.2+13
```
The release number has to be in format X.X.X and higher than the last published. The Versioncode after the `+` has to be higher than the last and a full number.

### Generate the apk
To build the app bundle run the following command inside the project directory.
```
flutter build appbundle
```
Inside `\build\app\outputs\bundle\release` the app bundle get's created which can be uploaded to the [Google Play Console](https://play.google.com/apps/publish).
