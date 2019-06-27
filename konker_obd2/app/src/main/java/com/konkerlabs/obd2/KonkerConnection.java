package com.konkerlabs.obd2;

import android.content.Context;
import android.util.Log;

import org.eclipse.paho.android.service.MqttAndroidClient;
import org.eclipse.paho.client.mqttv3.DisconnectedBufferOptions;
import org.eclipse.paho.client.mqttv3.IMqttActionListener;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.IMqttToken;
import org.eclipse.paho.client.mqttv3.MqttCallbackExtended;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.json.JSONObject;

import io.reactivex.functions.BiConsumer;
import io.reactivex.functions.Consumer;

public class KonkerConnection {
    private String clientId;
    private String serverUri;
    private String password;
    private String username;
    private String pub;
    private MqttAndroidClient mqttAndroidClient;
    private Consumer<Boolean> connectionStateConsumer;
    private BiConsumer<String,Throwable> onErrorConsumer;
    private boolean sending = false;

    public KonkerConnection(Context context, String serverUri, String username, String password, String pub, Consumer<Boolean> connectionStateConsumer, BiConsumer<String, Throwable> onErrorConsumer){
        this.serverUri = serverUri;
        this.password = password;
        this.username = username;
        this.pub = pub;
        this.connectionStateConsumer = connectionStateConsumer;
        this.onErrorConsumer = onErrorConsumer;

        Log.e("MQTT", pub+' '+password+' '+username);
        clientId = MqttClient.generateClientId();
        Log.e("ClientId", clientId);
        mqttAndroidClient = new MqttAndroidClient(context, serverUri, clientId);
        mqttAndroidClient.setCallback(new MqttCallbackExtended() {
            @Override
            public void connectComplete(boolean b, String s) {
                Log.d("mqtt", "connected");
                try {
                    connectionStateConsumer.accept(true);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void connectionLost(Throwable throwable) {

                try {
                    onErrorConsumer.accept("Connection to konker lost",throwable);
                    connectionStateConsumer.accept(false);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void messageArrived(String topic, MqttMessage mqttMessage) throws Exception {

            }

            @Override
            public void deliveryComplete(IMqttDeliveryToken iMqttDeliveryToken) {

            }
        });
        connect(context);
    }

    public void setCallback(MqttCallbackExtended callback) {
        mqttAndroidClient.setCallback(callback);
    }

    private void connect(Context context){
        MqttConnectOptions mqttConnectOptions = new MqttConnectOptions();
        mqttConnectOptions.setAutomaticReconnect(true);
        mqttConnectOptions.setCleanSession(false);
        mqttConnectOptions.setUserName(username);
        mqttConnectOptions.setPassword(password.toCharArray());

        try {

            mqttAndroidClient.connect(mqttConnectOptions, context, new IMqttActionListener() {
                @Override
                public void onSuccess(IMqttToken asyncActionToken) {

                    DisconnectedBufferOptions disconnectedBufferOptions = new DisconnectedBufferOptions();
                    disconnectedBufferOptions.setBufferEnabled(true);
                    disconnectedBufferOptions.setBufferSize(100);
                    disconnectedBufferOptions.setPersistBuffer(false);
                    disconnectedBufferOptions.setDeleteOldestMessages(false);
                    mqttAndroidClient.setBufferOpts(disconnectedBufferOptions);
                    try {
                        connectionStateConsumer.accept(true);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    Log.d("mqtt", "Connection established");
                }

                @Override
                public void onFailure(IMqttToken asyncActionToken, Throwable exception) {
                    exception.printStackTrace();
                    try {
                        onErrorConsumer.accept("Failed to connect to: " + serverUri,exception);
                        connectionStateConsumer.accept(false);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            });


        } catch (MqttException ex){
            try {
                onErrorConsumer.accept("Connecting failed", ex);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public void publish(String channel, JSONObject object){
        if(sending) {
            MqttMessage message = new MqttMessage(object.toString().getBytes());
            try {
                Log.d("MQTT", "Sending to " + pub + "/" + channel);
                mqttAndroidClient.publish(pub + "/" + channel, message);
            } catch (MqttException e) {
                e.printStackTrace();
            }
        }
    }

    public void setSending(boolean sending) {
        this.sending = sending;
    }
}
