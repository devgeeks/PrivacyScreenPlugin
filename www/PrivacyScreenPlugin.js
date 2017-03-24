cordova.define("cordova-plugin-privacy-screen.PrivacyScreen", function(require, exports, module) {

function PrivacyScreen() {}
               
//Default time to remove privacy screen is 2 seconds (+0.1s for fade animation)
PrivacyScreen.prototype.setTimer = function(successCallback, errorCallback, timeInterval) {
    cordova.exec(successCallback, errorCallback, "PrivacyScreenPlugin", "setTimer", [timeInterval]);
};
               
PrivacyScreen.prototype.hidePrivacyScreen = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "PrivacyScreenPlugin", "hidePrivacyScreen", []);
};
               
PrivacyScreen.prototype.showPrivacyScreen = function(successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "PrivacyScreenPlugin", "showPrivacyScreen", []);
};
               
PrivacyScreen.install = function() {
    if (!window.plugins) {
        window.plugins = {};
    }
               
    window.plugins.privacyscreen = new PrivacyScreen();
    return window.plugins.privacyscreen;
};
               
cordova.addConstructor(PrivacyScreen.install);
});