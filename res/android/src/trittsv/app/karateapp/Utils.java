// Copyright (c) 2026 Sven Trittler and contributors
// SPDX-License-Identifier: MIT

package trittsv.app.karateapp;

import android.content.Context;
import android.os.Vibrator;
import android.os.Build;
import android.os.VibrationEffect;
import android.util.Log;
import android.content.ContentResolver;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import android.media.ExifInterface;
import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import java.io.IOException;
import java.io.InputStream;
import java.io.FileNotFoundException;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;


public class Utils {

    private static final String KEYSTORE_ALIAS = "trittsv.app.karateapp.qt";
    private static final String SHARED_PREFS_NAME = "trittsv.app.karateapp.qt";
    private static final String ANDROID_KEYSTORE = "AndroidKeyStore";

    /// @brief Vibrates the phone for 100ms.
    public static void vibrate(Context context) {
        Log.d("trittsv.app.karateapp.Utils.vibrate", "vibrate");
        Vibrator v = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
        int durationInMs = 100;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createOneShot(durationInMs, VibrationEffect.DEFAULT_AMPLITUDE));
        } else {
            //deprecated in API 26 
            v.vibrate(durationInMs);
        }
    }

    /// @brief Stores content:// uri to a given file path.
    public static void saveImageFromUri(Context context, String contentUri, String targetFilePath) {
        Log.d("trittsv.app.karateapp.Utils.saveImageFromUri", "saveImageFromUri " + contentUri + ", " + targetFilePath);
        Uri uri = Uri.parse(contentUri);
        ContentResolver resolver = context.getContentResolver();

        try (InputStream inputStream = resolver.openInputStream(uri);
             OutputStream outputStream = new FileOutputStream(targetFilePath)) {

            if (inputStream == null) {
                throw new IllegalArgumentException("InputStream for the given URI is null");
            }

            byte[] buffer = new byte[1024];
            int len;
            while ((len = inputStream.read(buffer)) > 0) {
                outputStream.write(buffer, 0, len);
            }

            outputStream.flush();
            Log.d("trittsv.app.karateapp", "Succesfully created file.");

        } catch (Exception e) {
            Log.e("trittsv.app.karateapp", "Failed to write to file");
            e.printStackTrace();
        }
    }

    /// @brief Get the birth date of a image with content uri.
    public static long getExifCreationDate(Context context, String contentUri) {

        Log.d("trittsv.app.karateapp", contentUri);

        long dateTimeOriginalUtc = -1;

        try {
            Uri theUri = Uri.parse(contentUri);
            InputStream inputStream = context.getContentResolver().openInputStream(theUri);
            ExifInterface exifInterface = new ExifInterface(inputStream);

            // Get Offset to UTC
            String orientation = exifInterface.getAttribute(ExifInterface.TAG_ORIENTATION);
            Log.d("trittsv.app.karateapp", "Orientation = " + orientation);

            String offsetTimeOriginal = exifInterface.getAttribute(ExifInterface.TAG_OFFSET_TIME_ORIGINAL);
            int sign = offsetTimeOriginal.startsWith("-") ? -1 : 1;
            char firstChar = offsetTimeOriginal.charAt(0);
            if (firstChar == '+' || firstChar == '-') {
                offsetTimeOriginal = offsetTimeOriginal.substring(1);
            }
            String[] parts = offsetTimeOriginal.split(":");
            int hours = Integer.parseInt(parts[0]);
            int minutes = Integer.parseInt(parts[1]);
            int offsetInMilli = sign * ((hours * 60 + minutes) * 60 * 1000);

            // Get DateTime +/- Offset
            dateTimeOriginalUtc = exifInterface.getDateTimeOriginal() + offsetInMilli;

            Log.d("trittsv.app.karateapp.Utils.getCreationDate", "dateTimeOriginalUtc " + dateTimeOriginalUtc);
            return dateTimeOriginalUtc;

        } catch (FileNotFoundException e) {
            Log.e("trittsv.app.karateapp.Utils.getCreationDate", "FileNotFoundException");
        } catch (IOException e){
            Log.e("trittsv.app.karateapp.Utils.getCreationDate", "IOException");
        } finally {
        }

        return dateTimeOriginalUtc;
    }

    /// @brief Securly store value like a password on the device.
    public static void storePassword(Context context, String password, String service) {
        try {
            Key key = getOrCreateSecretKey();

            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, key);
            byte[] iv = cipher.getIV();
            byte[] encryption = cipher.doFinal(password.getBytes(StandardCharsets.UTF_8));

            // Combine IV and encrypted password
            byte[] combined = new byte[iv.length + encryption.length];
            System.arraycopy(iv, 0, combined, 0, iv.length);
            System.arraycopy(encryption, 0, combined, iv.length, encryption.length);

            // Save encrypted password to SharedPreferences
            SharedPreferences sharedPreferences = context.getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE);
            sharedPreferences.edit().putString(service, Base64.encodeToString(combined, Base64.DEFAULT)).apply();
        } catch (Exception e) {
            Log.e("trittsv.app.karateapp.Utils.getCreationDate", "Exception");
        } finally {

        }
    }

    /// @brief Securly get value like a password from the device.
    public static String retrievePassword(Context context, String service) {
        try {
            Key key = getOrCreateSecretKey();

            // Get encrypted password from SharedPreferences
            SharedPreferences sharedPreferences = context.getSharedPreferences(SHARED_PREFS_NAME, Context.MODE_PRIVATE);
            String encryptedPasswordBase64 = sharedPreferences.getString(service, null);
            if (encryptedPasswordBase64 == null) {
                return new String("");
            }
            byte[] combined = Base64.decode(encryptedPasswordBase64, Base64.DEFAULT);

            // Extract IV and encrypted password
            byte[] iv = new byte[12];
            byte[] encryption = new byte[combined.length - iv.length];
            System.arraycopy(combined, 0, iv, 0, iv.length);
            System.arraycopy(combined, iv.length, encryption, 0, encryption.length);

            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            GCMParameterSpec spec = new GCMParameterSpec(128, iv);
            cipher.init(Cipher.DECRYPT_MODE, key, spec);
            byte[] decrypted = cipher.doFinal(encryption);
            return new String(decrypted, StandardCharsets.UTF_8);
        } catch (Exception e) {
            Log.e("trittsv.app.karateapp.Utils.getCreationDate", "Exception");
        } finally {}

        return new String("");
    }

    private static Key getOrCreateSecretKey() throws Exception {
        KeyStore keyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
        keyStore.load(null);

        // Check if key already exists
        if (keyStore.containsAlias(KEYSTORE_ALIAS)) {
            return keyStore.getKey(KEYSTORE_ALIAS, null);
        }

        // Generate new key
        KeyGenerator keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE);
        KeyGenParameterSpec keyGenParameterSpec = new KeyGenParameterSpec.Builder(KEYSTORE_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .build();
        keyGenerator.init(keyGenParameterSpec);
        return keyGenerator.generateKey();
    }
}
