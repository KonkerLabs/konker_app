package com.konkerlabs.obd2;

import android.Manifest;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.location.Criteria;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.Spinner;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.harrysoft.androidbluetoothserial.*;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Set;

public class MainActivity extends AppCompatActivity{



    public static final int MY_PERMISSIONS_REQUEST_LOCATION = 99;


    Spinner deviceSelect;
    List<BluetoothDevice> pairedDevices;
    ArrayList<String> spinnerArray = new ArrayList<String>();
    OBDBluetoothManager bluetoothManager;
    Button connectButton;
    boolean connected = false;
    private RecyclerView dataView;
    private RecyclerView.LayoutManager layoutManager;
    private LinkedHashMap<OBDDefinition, Double> dataMap = new LinkedHashMap<>();
    private MyAdapter mAdapter;
    private TextView mqtt1;
    private TextView mqtt2;
    private TextView mqttState;
    private Switch sendingSwitch;
    KonkerConnection konkerConnection;
    SharedPreferences sharedPreferences;
    private String PASS_KEY = "konker.PASS";
    private String USER_KEY = "konker.USER";
    private String PUB_KEY = "konker.PUB";
    private String CONNSTR_KEY = "konker.CONNSTR";
    private Set<String> dtcSet = new HashSet();


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        checkLocationPermission();
        LocationService.setLocationUpdateListener(this::onLocationUpdate);
        LocationService.startLocationService(this);
        sharedPreferences = getSharedPreferences("Konker",MODE_PRIVATE);
        deviceSelect =findViewById(R.id.device_select);
        connectButton = findViewById(R.id.connectButton);
        mqtt1 = findViewById(R.id.mqtt1);
        mqtt2 = findViewById(R.id.mqtt2);
        mqttState = findViewById(R.id.mqtt_state);
        sendingSwitch = findViewById(R.id.sending_switch);
        dataView = findViewById(R.id.dataView);
        bluetoothManager  = OBDBluetoothManager.getInstance();
        bluetoothManager.setNewValueResultListener(this::onValueUpdate);
        bluetoothManager.setOnNewDTCResultListener(this::onDTCUpdate);
        if (bluetoothManager == null) {
            // Bluetooth unavailable on this device :( tell the user
            Toast.makeText(this, "Bluetooth not available.", Toast.LENGTH_LONG).show(); // Replace context with your context instance.
            finish();
        }
        pairedDevices  = bluetoothManager.getPairedDevices();

        for (BluetoothDevice device : pairedDevices) {
            spinnerArray.add(device.getName()+" ("+device.getAddress()+")");
        }
        ArrayAdapter<String> adapter;
        adapter = new ArrayAdapter<String>(
                this, android.R.layout.simple_spinner_item, spinnerArray);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        deviceSelect.setAdapter(adapter);

        //setup data view
        layoutManager = new LinearLayoutManager(this);
        dataView.setLayoutManager(layoutManager);

        mAdapter = new MyAdapter(dataMap, dtcSet);
        dataView.setAdapter(mAdapter);

        showKonkerData();

        sendingSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                // do something, the isChecked will be
                // true if the switch is in the On position
                if(konkerConnection != null){
                    konkerConnection.setSending(isChecked);
                }
            }
        });

    }


    public void onLocationUpdate(LocationResult result){
        JSONObject object = new JSONObject();
        try {
            object.put("_ts", System.currentTimeMillis());
            object.put("_lon", result.getLastLocation().getLongitude());
            object.put("_lat", result.getLastLocation().getLatitude());
            if(konkerConnection != null){
                konkerConnection.publish("location",object);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void getLogin(View view) {
        Intent intent = new Intent(this, QRCodeReader.class);
        startActivityForResult(intent, QRCodeReader.SCAN_QRCODE);
    }


    public void connect(View view){
        if(connected) {
            bluetoothManager.disconnect();
            connectButton.setText("Connect");
            connected = false;
        }else {
            BluetoothDevice device = pairedDevices.get((int)(deviceSelect.getSelectedItemId()));
            bluetoothManager.connectDevice(device.getAddress(),this::onConnected, this::onError);
            Log.e(device.getName(),device.getAddress());
            connectButton.setText("Connecting");
            connectButton.setEnabled(false);
        }

    }


    private void onConnected(SimpleBluetoothDeviceInterface deviceInterface) {
        connected = true;
        // Listen to bluetooth events
        deviceInterface.setMessageSentListener(this::onMessageSent);
        deviceInterface.setErrorListener(this::onError);
        bluetoothManager.startRegularIntervals();
        // Let's send a message:
        //deviceInterface.sendMessage("00\n");
        Log.e("CONNECT","CONNECTED");
        connectButton.setText("Disconnect");
        connectButton.setEnabled(true);
    }

    private void onMessageSent(String message) {
        // We sent a message! Handle it here.
        //Toast.makeText(this, "Sent a message! Message was: " + message, Toast.LENGTH_LONG).show(); // Replace context with your context instance.
        Log.d("MsgSent", message);
    }

    private void onValueUpdate(Double value, OBDDefinition definition){
        //Toast.makeText(this, "New value for "+definition.getName()+": " + value, Toast.LENGTH_LONG).show();
        dataMap.put(definition, value);
        mAdapter.notifyDataSetChanged();
        JSONObject object = new JSONObject();
        try {
            object.put("_ts", System.currentTimeMillis());
            object.put(definition.getName(),value);
            if(konkerConnection != null){
                konkerConnection.publish(definition.getName(),object);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
    private void onDTCUpdate(List<String> value, OBDDefinition definition){
        //Toast.makeText(this, "New value for "+definition.getName()+": " + value, Toast.LENGTH_LONG).show();
        dtcSet.addAll(value);
        mAdapter.notifyDataSetChanged();
        JSONObject object = new JSONObject();
        try {
            object.put("_ts", System.currentTimeMillis());
            object.put(definition.getName(), new JSONArray(value.toArray()));
            if(konkerConnection != null){
                konkerConnection.publish(definition.getName(),object);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
    private void onError(Throwable error) {
        onError("", error);
    }

    private void onError(String reason, Throwable error) {
        // Handle the error
        Toast.makeText(this, "ERROR: "+reason +"\n" + error.getMessage(), Toast.LENGTH_LONG).show();
        Log.e("onError","ERROR: "+reason +"\n" + error.getMessage());
        bluetoothManager.disconnect();
        connectButton.setText("Connect");
        connectButton.setEnabled(true);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        // Check which request we're responding to
        if (requestCode == QRCodeReader.SCAN_QRCODE) {
            // Make sure the request was successful
            if (resultCode == RESULT_OK) {
                // The user picked a contact.
                // The Intent's data Uri identifies which contact was selected.
                String result = data.getStringExtra("result");
                try {
                    JSONObject jsonObject =new JSONObject(result);
                    String host = jsonObject.getString("host-mqtt");
                    int port = jsonObject.getInt("mqtt");
                    String user = jsonObject.getString("user");
                    String pass = jsonObject.getString("pass");

                    String pub = "data/"+user+"/pub";
                    String connectionString = "tcp://"+host+":"+port+"";
                    SharedPreferences.Editor editor = sharedPreferences.edit();
                    editor.putString(CONNSTR_KEY, connectionString);
                    editor.putString(USER_KEY,user);
                    editor.putString(PASS_KEY,pass);
                    editor.putString(PUB_KEY,pub);
                    editor.apply();
                    showKonkerData();

                } catch (JSONException e) {
                    Toast.makeText(this, "Invalid QR Code", Toast.LENGTH_LONG).show();
                }
                // Do something with the contact here (bigger example below)
            }
        }
    }

    private void showKonkerData(){
        String pub = sharedPreferences.getString(PUB_KEY, null);
        String user = sharedPreferences.getString(USER_KEY, null);
        String pass = sharedPreferences.getString(PASS_KEY, null);
        String connStr = sharedPreferences.getString(CONNSTR_KEY, null);
        if(pub != null){
            mqtt1.setText(connStr+" - " + user);
            mqtt2.setText(pass.substring(0,3)+"**"+" - "+pub);
            konkerConnection = new KonkerConnection(this,connStr,user, pass, pub, this::setMQTTConnectionState, this::onError);
            konkerConnection.setSending(sendingSwitch.isChecked());
        }

    }

    private void setMQTTConnectionState(Boolean b){
        if(b){
            mqttState.setText("Connected");
        }else{
            mqttState.setText("Disconnected");
        }
    }




    //LOCATION


    public boolean checkLocationPermission() {
        if (ContextCompat.checkSelfPermission(this,
                Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {

            // Should we show an explanation?
            if (ActivityCompat.shouldShowRequestPermissionRationale(this,
                    Manifest.permission.ACCESS_FINE_LOCATION)) {

                // Show an explanation to the user *asynchronously* -- don't block
                // this thread waiting for the user's response! After the user
                // sees the explanation, try again to request the permission.
                new AlertDialog.Builder(this)
                        .setTitle("Location permission")
                        .setMessage("We need your location permission to be able to send the location to konker!")
                        .setPositiveButton("OK", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialogInterface, int i) {
                                //Prompt the user once explanation has been shown
                                ActivityCompat.requestPermissions(MainActivity.this,
                                        new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
                                        MY_PERMISSIONS_REQUEST_LOCATION);
                            }
                        })
                        .create()
                        .show();


            } else {
                // No explanation needed, we can request the permission.
                ActivityCompat.requestPermissions(this,
                        new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
                        MY_PERMISSIONS_REQUEST_LOCATION);
            }
            return false;
        } else {
            return true;
        }
    }


}
