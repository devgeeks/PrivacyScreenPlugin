/**
 * AppDelegate+notification.m
 * Created by Tommy-Carlos Williams on 18/07/2014
 * Copyright (c) 2014 Tommy-Carlos Williams. All rights reserved.
 * MIT Licensed
 */
#import "AppDelegate+privacyscreen.h"
#import <objc/runtime.h>

UIImageView *imageView;

@implementation AppDelegate (privacyscreen)


// Method only seems to be called on iPad Pro
- (void)applicationDidBecomeActive:(UIApplication *)application
{
  [self applicationWakes];
}

- (void)applicationWakes
{
  if (imageView == NULL) {
    self.window.hidden = NO;
  } else {
    [imageView removeFromSuperview];
  }

  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  NSString *imgName = [self getImageName:self.viewController.interfaceOrientation delegate:(id<CDVScreenOrientationDelegate>)self.viewController device:[self getCurrentDevice]];
  UIImage *splash = [UIImage imageNamed:imgName];
  if (splash == NULL) {
    self.window.hidden = YES;
  } else {
    imageView = [[UIImageView alloc]initWithFrame:[self.viewController.view bounds]];
    [imageView setImage:splash];
    [self.viewController.view addSubview:imageView];
  }

  // ApplicationDidBecomeActive needs to be observed, without the observer the method will not be called
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWakes) name:UIApplicationDidBecomeActiveNotification object:nil];
}

// Code below borrowed from the CDV splashscreen plugin @ https://github.com/apache/cordova-plugin-splashscreen
// Made some adjustments though, becuase landscape splashscreens are not available for iphone < 6 plus
- (CDV_iOSDevice) getCurrentDevice
{
  CDV_iOSDevice device;

  UIScreen* mainScreen = [UIScreen mainScreen];
  CGFloat mainScreenHeight = mainScreen.bounds.size.height;
  CGFloat mainScreenWidth = mainScreen.bounds.size.width;

  int limit = MAX(mainScreenHeight,mainScreenWidth);

  device.iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
  device.iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
  device.retina = ([mainScreen scale] == 2.0);
  device.iPhone5 = (device.iPhone && limit == 568.0);
  // note these below is not a true device detect, for example if you are on an
  // iPhone 6/6+ but the app is scaled it will prob set iPhone5 as true, but
  // this is appropriate for detecting the runtime screen environment
  device.iPhone6 = (device.iPhone && limit == 667.0);
  device.iPhone6Plus = (device.iPhone && limit == 736.0);

  return device;
}

- (NSString*)getImageName:(UIInterfaceOrientation)currentOrientation delegate:(id<CDVScreenOrientationDelegate>)orientationDelegate device:(CDV_iOSDevice)device
{
  // Use UILaunchImageFile if specified in plist.  Otherwise, use Default.
  NSString* imageName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UILaunchImageFile"];

  NSUInteger supportedOrientations = [orientationDelegate supportedInterfaceOrientations];

  // Checks to see if the developer has locked the orientation to use only one of Portrait or Landscape
  BOOL supportsLandscape = (supportedOrientations & UIInterfaceOrientationMaskLandscape);
  BOOL supportsPortrait = (supportedOrientations & UIInterfaceOrientationMaskPortrait || supportedOrientations & UIInterfaceOrientationMaskPortraitUpsideDown);
  // this means there are no mixed orientations in there
  BOOL isOrientationLocked = !(supportsPortrait && supportsLandscape);

  if (imageName) {
    imageName = [imageName stringByDeletingPathExtension];
  } else {
    imageName = @"Default";
  }

  BOOL isLandscape = supportsLandscape &&
  (currentOrientation == UIInterfaceOrientationLandscapeLeft || currentOrientation == UIInterfaceOrientationLandscapeRight);

  if (device.iPhone5) { // does not support landscape
    imageName = isLandscape ? nil : [imageName stringByAppendingString:@"-568h"];
  } else if (device.iPhone6) { // does not support landscape
    imageName = isLandscape ? nil : [imageName stringByAppendingString:@"-667h"];
  } else if (device.iPhone6Plus) { // supports landscape
    if (isOrientationLocked) {
      imageName = [imageName stringByAppendingString:(supportsLandscape ? @"-Landscape" : @"")];
    } else {
      switch (currentOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
          imageName = [imageName stringByAppendingString:@"-Landscape"];
          break;
        default:
          break;
      }
    }
    imageName = [imageName stringByAppendingString:@"-736h"];

  } else if (device.iPad) { // supports landscape
    if (isOrientationLocked) {
      imageName = [imageName stringByAppendingString:(supportsLandscape ? @"-Landscape" : @"-Portrait")];
    } else {
      switch (currentOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
          imageName = [imageName stringByAppendingString:@"-Landscape"];
          break;

        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        default:
          imageName = [imageName stringByAppendingString:@"-Portrait"];
          break;
      }
    }
  }

  return imageName;
}

@end
