package com.konkerlabs.obd2;

import android.view.LayoutInflater;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.recyclerview.widget.RecyclerView;

import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Set;

public class MyAdapter extends RecyclerView.Adapter<MyAdapter.MyViewHolder> {
    private LinkedHashMap<OBDDefinition, Double> dataMap;
    private Set<String> dtcSet;
    // Provide a reference to the views for each data item
    // Complex data items may need more than one view per item, and
    // you provide access to all the views for a data item in a view holder
    public static class MyViewHolder extends RecyclerView.ViewHolder {
        // each data item is just a string in this case
        public ConstraintLayout rootLayout;
        public TextView nameView;
        public TextView valueView;
        public MyViewHolder(ConstraintLayout v) {
            super(v);
            rootLayout = v;
            nameView = v.findViewById(R.id.item_name);
            valueView = v.findViewById(R.id.item_value);
        }
    }

    // Provide a suitable constructor (depends on the kind of dataset)
    public MyAdapter(LinkedHashMap<OBDDefinition, Double> dataMap, Set<String> dtcSet) {
        this.dataMap = dataMap;
        this.dtcSet = dtcSet;
    }

    // Create new views (invoked by the layout manager)
    @Override
    public MyAdapter.MyViewHolder onCreateViewHolder(ViewGroup parent,
                                                     int viewType) {
        // create a new view
        ConstraintLayout v = (ConstraintLayout) LayoutInflater.from(parent.getContext())
                .inflate(R.layout.layout_listitem, parent, false);
        MyViewHolder vh = new MyViewHolder(v);
        return vh;
    }

    // Replace the contents of a view (invoked by the layout manager)
    @Override
    public void onBindViewHolder(MyViewHolder holder, int position) {
        // - get element from your dataset at this position
        // - replace the contents of the view with that element
        if (position >=dataMap.size()){
            holder.nameView.setText("DTCs");
            holder.valueView.setText(Arrays.toString(dtcSet.toArray()));
        }
        else{
            OBDDefinition def =  (OBDDefinition)dataMap.keySet().toArray()[position];
            Double value = dataMap.get(def);
            holder.nameView.setText(def.getBeautifiedName());
            holder.valueView.setText(""+value);
        }

    }

    // Return the size of your dataset (invoked by the layout manager)
    @Override
    public int getItemCount() {
        return dataMap.size()+(dataMap.size()>0?1:0);
    }
}
