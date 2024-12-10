package io.flutter.plugins.videoplayer;

import android.opengl.GLES20;

import java.io.IOException;
import java.io.RandomAccessFile;

public class DeviceUtils {

    // Determines if the device is low-end or high-end
    public static boolean isLowEndDevice() {
        int numberOfCores = Runtime.getRuntime().availableProcessors();
        long totalRAM = getTotalRAM();

        // Simple logic: If the device has fewer than 4 cores and less than 2GB RAM, classify it as low-end
        boolean isLowEndBasedOnHardware = numberOfCores < 4 || totalRAM < 2L * 1024 * 1024 * 1024;

        // Check GPU (OpenGL version and vendor)
        boolean isLowEndBasedOnGPU = isLowEndGPU();

        // Combine the checks: if any condition is true, it's a low-end device
        return isLowEndBasedOnHardware || isLowEndBasedOnGPU;
    }

    private static long getTotalRAM() {
        // Get the total RAM in the system from the device
        String memInfoFile = "/proc/meminfo";
        String[] memInfo = new String[2];
        try {
            RandomAccessFile reader = new java.io.RandomAccessFile(memInfoFile, "r");
            memInfo[0] = reader.readLine();
            reader.close();
        } catch (IOException ex) {
            ex.printStackTrace();
        }
        if (memInfo[0] != null) {
            String[] tokens = memInfo[0].split("\\s+");
            return Long.parseLong(tokens[1]) * 1024;  // Return RAM in bytes
        }
        return 0;
    }

    // Check if the GPU is low-end based on OpenGL version or vendor information
    private static boolean isLowEndGPU() {
        // Get the OpenGL renderer and vendor strings
        String glRenderer = GLES20.glGetString(GLES20.GL_RENDERER);  // OpenGL renderer
        String glVendor = GLES20.glGetString(GLES20.GL_VENDOR);      // OpenGL vendor

        // Check if the vendor is known for low-end GPUs
        if (glVendor != null) {
            // Example check: PowerVR and IMG are associated with lower-end GPUs
            if (glVendor.contains("IMG") || glVendor.contains("PowerVR")) {
                return true;  // Known low-end GPUs
            }
        }

        // You can also check the OpenGL version (if available) to determine if the GPU is older
        String glVersion = GLES20.glGetString(GLES20.GL_VERSION);
        return glVersion != null && glVersion.startsWith("1.");  // OpenGL ES 1.x typically indicates older GPUs
    }

}
