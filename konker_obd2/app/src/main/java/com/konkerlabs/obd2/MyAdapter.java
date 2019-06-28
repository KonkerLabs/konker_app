package com.konkerlabs.obd2;

import android.content.Context;
import android.content.DialogInterface;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.appcompat.app.AlertDialog;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Set;

import io.reactivex.functions.Consumer;

public class MyAdapter extends RecyclerView.Adapter<MyAdapter.MyViewHolder> {
    private LinkedHashMap<OBDDefinition, Double> dataMap;
    private ArrayList<OBDDefinition> data;
    private Set<String> dtcSet;
    private Context context;
    // Provide a reference to the views for each data item
    // Complex data items may need more than one view per item, and
    // you provide access to all the views for a data item in a view holder
    public static class MyViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener {
        // each data item is just a string in this case
        public ConstraintLayout rootLayout;
        public TextView nameView;
        public TextView valueView;
        private Consumer<Integer> clickConsumer;
        public MyViewHolder(ConstraintLayout v, Consumer<Integer> clickConsumer) {
            super(v);
            rootLayout = v;
            nameView = v.findViewById(R.id.item_name);
            valueView = v.findViewById(R.id.item_value);
            rootLayout.setOnClickListener(this);
            this.clickConsumer = clickConsumer;
        }

        @Override
        public void onClick(View v) {
            int pos = this.getLayoutPosition();
            try {
                clickConsumer.accept(pos);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    // Provide a suitable constructor (depends on the kind of dataset)
    public MyAdapter(LinkedHashMap<OBDDefinition, Double> dataMap, Set<String> dtcSet) {
        this.dataMap = dataMap;
        this.dtcSet = dtcSet;
    }

    public MyAdapter(Context context, ArrayList<OBDDefinition> list){
        data = list;
        this.context = context;
    }

    // Create new views (invoked by the layout manager)
    @Override
    public MyAdapter.MyViewHolder onCreateViewHolder(ViewGroup parent,
                                                     int viewType) {
        // create a new view
        ConstraintLayout v = (ConstraintLayout) LayoutInflater.from(parent.getContext())
                .inflate(R.layout.layout_listitem, parent, false);
        MyViewHolder vh = new MyViewHolder(v,this::onClick);
        return vh;
    }

    private void onClick(Integer pos){
        if(data != null){

            new AlertDialog.Builder(context)
                    .setTitle("Delete entry")
                    .setMessage("Are you sure you want to delete this entry?")

                    // Specifying a listener allows you to take an action before dismissing the dialog.
                    // The dialog is automatically dismissed when a dialog button is clicked.
                    .setPositiveButton(android.R.string.yes, new DialogInterface.OnClickListener() {
                        public void onClick(DialogInterface dialog, int which) {
                            // Continue with delete operation
                            data.remove(pos.intValue());
                            Log.e("POS", ""+pos+" "+data.size());
                            notifyDataSetChanged();
                        }
                    })

                    // A null listener allows the button to dismiss the dialog and take no further action.
                    .setNegativeButton(android.R.string.no, null)
                    .setIcon(android.R.drawable.ic_dialog_alert)
                    .show();

        }
    }

    // Replace the contents of a view (invoked by the layout manager)
    @Override
    public void onBindViewHolder(MyViewHolder holder, int position) {
        // - get element from your dataset at this position
        // - replace the contents of the view with that element

        if (position >=(dataMap!=null?dataMap.size():(data != null?data.size():0))){
            holder.nameView.setText("DTCs");
            holder.valueView.setText(Arrays.toString(dtcSet.toArray()));
        }
        else{
            if(dataMap != null){
                OBDDefinition def =  (OBDDefinition)dataMap.keySet().toArray()[position];
                Double value = dataMap.get(def);
                holder.nameView.setText(def.getBeautifiedName());
                holder.valueView.setText(""+value);
            }
            if(data != null){
                holder.nameView.setText(data.get(position).getBeautifiedName());
                holder.valueView.setText(data.get(position).getPid());
            }

        }

    }

    // Return the size of your dataset (invoked by the layout manager)
    @Override
    public int getItemCount() {
        int size =(dataMap!=null?dataMap.size():(data != null?data.size():0));
        return size +(size>0&&dtcSet!=null?1:0);
    }
}
