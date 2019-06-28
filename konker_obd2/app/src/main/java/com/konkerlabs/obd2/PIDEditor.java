package com.konkerlabs.obd2;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.app.Dialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONException;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class PIDEditor extends AppCompatActivity {
    RecyclerView pidView;
    ArrayList<OBDDefinition> obdDefinitionList;
    MyAdapter mAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_pideditor);
        pidView = findViewById(R.id.pidView);
        LinearLayoutManager layoutManager = new LinearLayoutManager(this);
        pidView.setLayoutManager(layoutManager);
        obdDefinitionList = OBDBluetoothManager.getInstance(this).getDefs();
        mAdapter = new MyAdapter(this, obdDefinitionList);
        pidView.setAdapter(mAdapter);
    }

    public void add(View v){
        View dView =getLayoutInflater().inflate(R.layout.create_dialog,null);
        new AlertDialog.Builder(this)
                .setTitle("Add new PID")
                .setView(dView)
                // Specifying a listener allows you to take an action before dismissing the dialog.
                // The dialog is automatically dismissed when a dialog button is clicked.
                .setPositiveButton(android.R.string.yes, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int which) {
                        TextView name = dView.findViewById(R.id.name);
                        TextView pid = dView.findViewById(R.id.pid);
                        TextView refreshInterval = dView.findViewById(R.id.refreshInterval);
                        TextView subtract = dView.findViewById(R.id.subtract);
                        TextView divisor = dView.findViewById(R.id.divisor);
                        try{
                        obdDefinitionList.add(new OBDDefinition(String.valueOf(name.getText()),String.valueOf(pid.getText()),Float.parseFloat(String.valueOf(divisor.getText())),Long.parseLong(String.valueOf(refreshInterval.getText())), Integer.parseInt( String.valueOf(subtract.getText()))));
                        mAdapter.notifyDataSetChanged();
                        }catch(Exception ex){
                            Toast.makeText(PIDEditor.this, "Creating new PID failed: "+ex.getMessage(), Toast.LENGTH_LONG).show();
                            ex.printStackTrace();
                        }
                    }
                })

                // A null listener allows the button to dismiss the dialog and take no further action.
                .setNegativeButton(android.R.string.no, null)
                .show();

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        try {
            OBDBluetoothManager.getInstance(this).updateDefs(this, obdDefinitionList);
        } catch (Exception e) {
            Toast.makeText(PIDEditor.this, "Saving PIDs failed: " + e.getMessage(), Toast.LENGTH_LONG).show();
            e.printStackTrace();
        }
    }

    // create an action bar button
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.pid_editor, menu);
        return super.onCreateOptionsMenu(menu);
    }

    // handle button activities
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();

        if (id == R.id.reset) {
            obdDefinitionList.clear();
            obdDefinitionList.addAll(OBDDefinition.getStandardDefinitions());
            mAdapter.notifyDataSetChanged();
        }
        return super.onOptionsItemSelected(item);
    }
}
