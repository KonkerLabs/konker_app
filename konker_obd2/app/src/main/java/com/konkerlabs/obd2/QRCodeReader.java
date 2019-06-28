package com.konkerlabs.obd2;

import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.SparseIntArray;
import android.view.Surface;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import com.google.android.gms.vision.barcode.BarcodeDetector;
import com.google.firebase.FirebaseApp;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcode;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcodeDetector;
import com.google.firebase.ml.vision.barcode.FirebaseVisionBarcodeDetectorOptions;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.common.FirebaseVisionImageMetadata;
import com.wonderkiln.camerakit.CameraKitError;
import com.wonderkiln.camerakit.CameraKitEvent;
import com.wonderkiln.camerakit.CameraKitEventListener;
import com.wonderkiln.camerakit.CameraKitImage;
import com.wonderkiln.camerakit.CameraKitVideo;
import com.wonderkiln.camerakit.CameraView;

import java.util.List;

public class QRCodeReader extends AppCompatActivity {
    private CameraView camera;
    public  static int SCAN_QRCODE = 0;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_qrcode_reader);
        camera = findViewById(R.id.camera);
        FirebaseApp.initializeApp(this);
        camera.addCameraKitListener(new CameraKitEventListener() {
            @Override
            public void onEvent(CameraKitEvent cameraKitEvent) {

            }

            @Override
            public void onError(CameraKitError cameraKitError) {

            }

            @Override
            public void onImage(CameraKitImage cameraKitImage) {
                Log.d("QR","onImage");

                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        Bitmap bitmap = cameraKitImage.getBitmap();
                        bitmap = Bitmap.createScaledBitmap(bitmap, camera.getWidth(), camera.getHeight(), false);
                        camera.stop();
                        getQRCodeDetails(bitmap);
                    }
                });
            }

            @Override
            public void onVideo(CameraKitVideo cameraKitVideo) {

            }

        });


    }


    public void onClick( View v) {
        if(camera.isStarted()) {
            camera.captureImage();
        }
    }

    private void getQRCodeDetails(Bitmap bitmap) {
        FirebaseApp.initializeApp(getApplicationContext());
        FirebaseVisionBarcodeDetectorOptions options =
                new FirebaseVisionBarcodeDetectorOptions.Builder()
                        .setBarcodeFormats(
                                FirebaseVisionBarcode.FORMAT_QR_CODE,
                                FirebaseVisionBarcode.FORMAT_AZTEC)
                        .build();


        FirebaseVisionImage image = FirebaseVisionImage.fromBitmap(bitmap);
        FirebaseVisionBarcodeDetector detector = FirebaseVision.getInstance().getVisionBarcodeDetector(options);
        detector.detectInImage(image).addOnSuccessListener((List<FirebaseVisionBarcode> it) ->{
            for (FirebaseVisionBarcode firebaseBarcode:it) {
                String txt = firebaseBarcode.getDisplayValue(); //Display contents inside the barcode
                Toast.makeText(this, txt, Toast.LENGTH_SHORT).show();
                Log.e("TEST", txt);
                if(firebaseBarcode.getValueType() == FirebaseVisionBarcode.TYPE_TEXT){
                    Intent returnIntent = new Intent();
                    returnIntent.putExtra("result",firebaseBarcode.getDisplayValue());
                    setResult(Activity.RESULT_OK,returnIntent);
                    finish();
                }
            }
            camera.start();
            Toast.makeText(this, "NO QR Code found", Toast.LENGTH_SHORT).show();
        });



    }

    @Override
    protected void onResume() {
        super.onResume();
        camera.start();
    }

    @Override
    protected void onPause() {
        camera.stop();
        super.onPause();
    }





}
