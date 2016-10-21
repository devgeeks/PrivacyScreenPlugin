/**
 * PrivacyScreenPlugin.java Cordova Plugin Implementation
 * Created by Tommy-Carlos Williams on 18/07/14.
 * Copyright (c) 2014 Tommy-Carlos Williams. All rights reserved.
 * MIT Licensed
 */
package org.devgeeks.privacyscreen;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaWebView;

import android.app.Activity;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Window;
import android.view.WindowManager;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.os.Bundle;

/**
 * This class sets the FLAG_SECURE flag on the window to make the app
 * private when shown in the task switcher
 */
public class PrivacyScreenPlugin extends CordovaPlugin {
  public static final String KEY_PRIVACY_SCREEN_ENABLED = "org.devgeeks.privacyscreen/PrivacyScreenEnabled";
  private SharedPreferences preferences;

  @Override
  public void initialize(CordovaInterface cordova, CordovaWebView webView) {
    super.initialize(cordova, webView);
    Activity activity = this.cordova.getActivity();
    preferences = PreferenceManager.getDefaultSharedPreferences(activity);
    boolean privacyScreenEnabled = isPrivacyScreenEnabled(true);

    if (privacyScreenEnabled) {
      activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_SECURE);
    }
  }

  /**
   * Gets the value of the Privacy Screen Enabled entry stored in {@link SharedPreferences}.
   * Will not attempt to correct an erroneous entry.
   *
   * @param defValue The default value of the preference if not readable or non-existent.
   * @return Whether the privacy screen should be enabled during the next application launch.
   * @see #KEY_PRIVACY_SCREEN_ENABLED
   * @see #isPrivacyScreenEnabled(boolean, boolean)
   */
  private boolean isPrivacyScreenEnabled(boolean defValue) {
    return isPrivacyScreenEnabled(defValue, false);
  }

  /**
   * Gets the value of the Privacy Screen Enabled entry stored in {@link SharedPreferences}.
   *
   * @param defValue      The default value of the preference if not readable or non-existent.
   * @param shouldCorrect If true, will attempt to convert String value to Boolean or replace with the default value.
   * @return Whether the privacy screen should be enabled during the next application launch.
   * @see #KEY_PRIVACY_SCREEN_ENABLED
   */
  private boolean isPrivacyScreenEnabled(boolean defValue, boolean shouldCorrect) {
    try {
      return preferences.getBoolean(KEY_PRIVACY_SCREEN_ENABLED, defValue);
    } catch (ClassCastException e) {
      Log.w("PrivacyScreen", "SharedPreference '" + KEY_PRIVACY_SCREEN_ENABLED + "' was not a Boolean value.", e);

      if (shouldCorrect) {
        if (convertStringEntryToBoolean()) {
          return preferences.getBoolean(KEY_PRIVACY_SCREEN_ENABLED, defValue);
        }
        setPrivacyScreenEnabled(defValue);
      }
    }
    return defValue;
  }

  /**
   * Converts the entry from a {@link String} to {@link Boolean} if possible.
   *
   * @return true if the entry was a {@code String} value that could be resolved to a {@code Boolean} value, false otherwise.
   * @see #isPrivacyScreenEnabled(boolean, boolean)
   * @see #KEY_PRIVACY_SCREEN_ENABLED
   */
  private boolean convertStringEntryToBoolean() {
    try {
      String val = preferences.getString(KEY_PRIVACY_SCREEN_ENABLED, null);
      if (val == null) {
        return false;
      }
      if (val.equalsIgnoreCase("true")) {
        setPrivacyScreenEnabled(true);
        return true;
      } else if (val.equalsIgnoreCase("false")) {
        setPrivacyScreenEnabled(false);
        return true;
      }
    } catch (ClassCastException e) {
      Log.w("PrivacyScreen", "SharedPreference '" + KEY_PRIVACY_SCREEN_ENABLED + "' was not a String value.", e);
    }
    return false;
  }

  /**
   * Sets the value of the Privacy Screen Enabled entry in {@link SharedPreferences}.
   *
   * @param value the value to set.
   * @return true if successful, false otherwise.
   * @see #KEY_PRIVACY_SCREEN_ENABLED
   */
  private boolean setPrivacyScreenEnabled(boolean value) {
    preferences.edit().putBoolean(KEY_PRIVACY_SCREEN_ENABLED, value).apply();
    return true;
  }

  @Override
  public Object onMessage(String id, Object data) {
    if (id == "isPrivacyScreenEnabled") {
      boolean shouldCorrect = (data instanceof Boolean) && (data != null) && ((Boolean) data);
      return isPrivacyScreenEnabled(true, shouldCorrect);
    } else if (id == "setPrivacyScreenEnabled") {
      if (data instanceof Boolean && data != null) {
        return setPrivacyScreenEnabled((Boolean) data);
      }
      return false;
    }
    return null;
  }
}
