package com.konkerlabs.obd2;

import android.content.Context;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class OBDDefinition {
    private String name = "";
    private String pid= "";
    private float divisor = 1.0f;
    private long requestInterval = 10;
    private long lastRun = 0;
    private int subtract = 0;
    private int mode = 0;
    private static String FILENAME = "obdDef.json";
    public static int NUMERIC_VALUE = 0;
    public static int DTC_REQUEST = 1;

    public String getPid() {
        return pid;
    }

    public float getDivisor() {
        return divisor;
    }

    public long getRequestInterval() {
        return requestInterval;
    }

    public OBDDefinition(String name, String pid, float divisor, long requestInterval) {
        this.name = name;
        this.pid = pid;
        this.divisor = divisor;
        this.requestInterval = requestInterval;
    }
    public OBDDefinition(JSONObject object) throws JSONException {
        this.name = object.getString("name");
        this.pid = object.getString("pid");
        this.divisor = (float)object.getDouble("divisor");
        this.requestInterval = object.getLong("requestInterval");
        this.subtract = object.getInt("subtract");
        this.mode = object.getInt("mode");
    }

    public OBDDefinition(String name, String pid, float divisor, long requestInterval, int subtract) {
        this.name = name;
        this.pid = pid;
        this.divisor = divisor;
        this.requestInterval = requestInterval;
        this.subtract = subtract;
    }

    public OBDDefinition(String name, String pid, long requestInterval) {
        this.name = name;
        this.pid = pid;
        this.requestInterval = requestInterval;
    }

    public OBDDefinition(String name, String pid, long requestInterval, int mode) {
        this.name = name;
        this.pid = pid;
        this.requestInterval = requestInterval;
        this.mode = mode;
    }

    public boolean shouldRun(){
        return System.currentTimeMillis()-lastRun > requestInterval*1000;
    }

    public void updateLastRun(){
        lastRun = System.currentTimeMillis();
    }

    public String getName() {
        return name;
    }

    public String getBeautifiedName(){
        String temp =name.replace("-", " ").trim();
        return  temp.substring(0,1).toUpperCase() + temp.substring(1);
    }

    public int getSubtract() {
        return subtract;
    }

    public int getMode() {
        return mode;
    }
    public JSONObject toJson() throws JSONException {
        JSONObject object = new JSONObject();
        object.put("name", name);
        object.put("pid", pid);
        object.put("divisor", divisor);
        object.put("requestInterval", requestInterval);
        object.put("subtract", subtract);
        object.put("mode", mode);
        return object;
    }

    public static void save(List<OBDDefinition> definitions, Context context) throws IOException, JSONException {
        File directory = context.getFilesDir();
        File out = new File(directory, FILENAME);
        FileWriter writer = new FileWriter(out,false);
        JSONArray jsonArray = new JSONArray();
        for(OBDDefinition definition:definitions){
            jsonArray.put(definition.toJson());
        }
        writer.write(jsonArray.toString());
        writer.close();
    }

    public static List<OBDDefinition> load(Context context) throws IOException, JSONException {
        File directory = context.getFilesDir();
        File in = new File(directory, FILENAME);
        if(!in.exists()){
            return getStandardDefinitions();
        }
        FileInputStream fis = new FileInputStream(in);
        byte[] data = new byte[(int) in.length()];
        fis.read(data);
        fis.close();
        String str = new String(data, "UTF-8");
        JSONArray array = new JSONArray(str);
        ArrayList<OBDDefinition> list = new ArrayList<>();
        for(int indx = 0; indx < array.length(); indx++){
            list.add(new OBDDefinition(array.getJSONObject(indx)));
        }
        return list;

    }
    public static List<OBDDefinition> getStandardDefinitions(){
        ArrayList<OBDDefinition> defs = new ArrayList<>();
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
        return defs;
    }
}
