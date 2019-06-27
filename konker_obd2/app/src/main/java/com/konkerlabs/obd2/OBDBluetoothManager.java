package com.konkerlabs.obd2;

import android.annotation.SuppressLint;
import android.bluetooth.BluetoothDevice;
import android.os.Handler;
import android.util.Log;

import com.harrysoft.androidbluetoothserial.BluetoothManager;
import com.harrysoft.androidbluetoothserial.BluetoothSerialDevice;
import com.harrysoft.androidbluetoothserial.SimpleBluetoothDeviceInterface;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.functions.BiConsumer;
import io.reactivex.functions.Consumer;
import io.reactivex.schedulers.Schedulers;

public class OBDBluetoothManager {
    private static OBDBluetoothManager instance;
    private ArrayList<OBDDefinition> defs = new ArrayList<>();
    private HashMap<String, OBDDefinition> definitionByPID = new HashMap<>();
    private BluetoothManager bluetoothManager;
    private SimpleBluetoothDeviceInterface deviceInterface;
    private Consumer<SimpleBluetoothDeviceInterface> onConnectedConsumer;
    private BiConsumer<String, Throwable> onErrorConsumer;
    private BiConsumer<Double, OBDDefinition> onNewValueResult;
    private BiConsumer<List<String>, OBDDefinition> onNewDTCResult;
    private Handler regularUpdateHandler = new Handler();
    private boolean connected = false;
    private OBDBluetoothManager(){
        defs.add(new OBDDefinition("speed","010D", 10));
        defs.add(new OBDDefinition("rpm","010C", 4.0f, 10));
        defs.add(new OBDDefinition("throttle-position","0111", 2.55f, 10));
        defs.add(new OBDDefinition("fuel-level","012F", 2.55f, 10));
        defs.add(new OBDDefinition("oil-temp","015C", 1f, 10, 40));
        defs.add(new OBDDefinition("coolant-temp","0167", 1f, 10, 40));
        defs.add(new OBDDefinition("ambient-temp","0146", 1f, 10, 40));
        defs.add(new OBDDefinition("intake-air-temp","0105", 1f, 10, 40));
        defs.add(new OBDDefinition("maf-airflow","0110", 100f, 10));
        defs.add(new OBDDefinition("dtc","03",10,OBDDefinition.DTC_REQUEST));

        for(OBDDefinition definition:defs){
            definitionByPID.put(definition.getPid(), definition);
        }

        bluetoothManager  = BluetoothManager.getInstance();
    }
    List<BluetoothDevice> getPairedDevices(){
        return bluetoothManager.getPairedDevicesList();
    }

    @SuppressLint("CheckResult")
    void connectDevice(String mac, Consumer<SimpleBluetoothDeviceInterface> onConnected, BiConsumer<String, Throwable> onError) {
        onErrorConsumer = onError;
        onConnectedConsumer = onConnected;
        bluetoothManager.openSerialDevice(mac)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(this::onConnected, this::onError);
    }

    private void onError(Throwable throwable){
        try {
            onErrorConsumer.accept("Bluetooth connection error.", throwable);
            disconnect();

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void onConnected(BluetoothSerialDevice connectedDevice) {
        deviceInterface = connectedDevice.toSimpleDeviceInterface();
        deviceInterface.setMessageReceivedListener(this::onMessageReceived);
        connected=true;
        try {
            onConnectedConsumer.accept(deviceInterface);
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    static OBDBluetoothManager getInstance(){
        if( instance == null ){
            instance = new OBDBluetoothManager();
        }
        return  instance;
    }

    public void send(String msg) {
        if(connected) {
            deviceInterface.sendMessage(msg + "\r\n");
        }
    }

    private void request(OBDDefinition definition){
        send(definition.getPid());
    }

    public void startRegularIntervals(){
        startHandler();
    }
    private void startHandler(){
        regularUpdateHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                startHandler();
                for(OBDDefinition def:defs){
                    if(def.shouldRun()){
                        request(def);
                        def.updateLastRun();
                        try {
                            Thread.sleep(200);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                }
            }
        },1000);
    }

    private void onMessageReceived(String message) {
        // We received a message! Handle it here.
        if(message.startsWith(">")|| !message.contains(" ")|| message.contains("N")){
            Log.d("MSG RCV","Ignored message: "+message);
            return;
        }
        if(message.startsWith("CONNECT")){
            Log.d("MSG RCV","Couldnt connect: "+message);
            return;
        }
        Log.d("MsgReceived", message);
        List<Integer> elementsInt = convertToIntList(message);
        elementsInt.set(0,elementsInt.get(0)-64);
        List<String> reconverted = convertToStringList(elementsInt);
        String pid = reconverted.get(0)+ (elementsInt.get(0) == 1 ? reconverted.get(1) : "");
        OBDDefinition obdDefinition = definitionByPID.get(pid);
        if(elementsInt.get(0)==1){
            elementsInt.remove(0);
        }
        elementsInt.remove(0);
        double result = 0;
        ArrayList<String> DTCs = new ArrayList<>();
        int i = 0;
        if(obdDefinition.getMode() == OBDDefinition.NUMERIC_VALUE) {

            for (int element : elementsInt) {
                result += element * (int) Math.pow(256, elementsInt.size() - 1 - i);
                i++;
            }
            result = Math.round(result / obdDefinition.getDivisor() - obdDefinition.getSubtract());
        }
        if(obdDefinition.getMode() == OBDDefinition.DTC_REQUEST){

            for(i =0; i<elementsInt.size(); i+=2){

                List<Integer> sub = elementsInt.subList(i,i+2);
                if(sub.get(0)+sub.get(1)!= 0){
                    DTCs.add(getDTC(sub));
                }
            }
            Log.e("DTCs", Arrays.toString(DTCs.toArray()));

        }
        try {
            if(obdDefinition.getMode() == OBDDefinition.NUMERIC_VALUE) {
                if (onNewValueResult != null) {
                    onNewValueResult.accept(result, obdDefinition);
                }
            }
            if(obdDefinition.getMode() == OBDDefinition.DTC_REQUEST) {
                if(!DTCs.isEmpty() && onNewDTCResult != null){
                    onNewDTCResult.accept(DTCs, obdDefinition);
                }
            }

        } catch (Exception e) {

            e.printStackTrace();
        }

    }

    int getBits(int n, int k, int mod) {
        return (n >> k) % mod;
    }
    String getDTC(List<Integer> elements){
        int firstByte = elements.get(0);
        int secondByte = elements.get(1);
        String[] firstChar = {"P", "C", "B", "U"};
        String result = "";
        result += firstChar[getBits(firstByte,6,4)];
        result += getBits(firstByte,4,4);
        result += String.format("%1X",firstByte%16);
        result += String.format("%1X",getBits(secondByte,4,16));
        result += String.format("%1X",secondByte % 16);

        return result;

    }
    List<Integer> convertToIntList(String s){
        String[] elements = s.split(" ");
        List<Integer> elementsInt = new ArrayList<>();
        for (String element : elements) {
            elementsInt.add(java.lang.Integer.decode("0x" + element));
        }
        return elementsInt;
    }

    List<String> convertToStringList( List<Integer> elements ){
        List<String> strings = new ArrayList<>();
        for(Integer element:elements) {
            strings.add(String.format("%02X", element));
        }
        return strings;
    }

    public void setNewValueResultListener(BiConsumer<Double, OBDDefinition> onNewResult) {
        this.onNewValueResult = onNewResult;
    }

    public void setOnNewDTCResultListener(BiConsumer<List<String>, OBDDefinition> onNewDTCResult) {
        this.onNewDTCResult = onNewDTCResult;
    }
    public void disconnect(){
        if(deviceInterface != null) {
            bluetoothManager.closeDevice(deviceInterface);
        }
        connected = false;
    }
}
