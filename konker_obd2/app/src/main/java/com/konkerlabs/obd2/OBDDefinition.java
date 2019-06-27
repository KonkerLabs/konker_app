package com.konkerlabs.obd2;

public class OBDDefinition {
    private String name = "";
    private String pid= "";
    private float divisor = 1.0f;
    private long requestInterval = 10;
    private long lastRun = 0;
    private int subtract = 0;
    private int mode = 0;
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
}
