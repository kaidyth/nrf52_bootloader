--- nrf_dfu_ver_validation.c.orig	2019-05-30 10:24:37.000000000 -0500
+++ nrf_dfu_ver_validation.c	2019-05-30 10:32:22.000000000 -0500
@@ -254,6 +254,17 @@
 #endif // NRF_DFU_SUPPORTS_EXTERNAL_APP
     else
     {
+#if NRF_DFU_BL_ACCEPT_SAME_VERSION
+        if (p_init->fw_version == s_dfu_settings.bootloader_version) {
+            return true;
+        }
+#endif
+
+#if NRF_DFU_BL_ALLOW_DOWNGRADE
+        if (p_init->fw_version < s_dfu_settings.bootloader_version) {
+            return true;
+        }
+#endif
         return  (p_init->fw_version > s_dfu_settings.bootloader_version);
     }
 }
