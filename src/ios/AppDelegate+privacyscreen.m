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

// Taken from https://github.com/phonegap-build/PushPlugin/blob/master/src/ios/AppDelegate%2Bnotification.m
// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load
{
    Method original, swizzled;

    original = class_getInstanceMethod(self, @selector(init));
    swizzled = class_getInstanceMethod(self, @selector(swizzled_init));
    method_exchangeImplementations(original, swizzled);
}

- (AppDelegate *)swizzled_init
{
    if ([UIApplication respondsToSelector:@selector(ignoreSnapshotOnNextApplicationLaunch:)]) {
        [[UIApplication sharedApplication] ignoreSnapshotOnNextApplicationLaunch];
        // Add any notification observers here...
    }
    // This actually calls the original init method over in AppDelegate. Equivilent to calling super
    // on an overrided method, this is not recursive, although it appears that way. neat huh?
    return [self swizzled_init];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (imageView == NULL && [[UIApplication sharedApplication] respondsToSelector:@selector(ignoreSnapshotOnNextApplicationLaunch:)]) {
        [[UIApplication sharedApplication] ignoreSnapshotOnNextApplicationLaunch];
        self.window.hidden = NO;
    } else {
        [imageView removeFromSuperview];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    UIImage *splash = [UIImage imageNamed:[self getImageName:self.viewController.interfaceOrientation delegate:(id<CDVScreenOrientationDelegate>)self.viewController device:[self getCurrentDevice]]];
    if (splash == NULL && [[UIApplication sharedApplication] respondsToSelector:@selector(ignoreSnapshotOnNextApplicationLaunch:)]) {
        [[UIApplication sharedApplication] ignoreSnapshotOnNextApplicationLaunch];
        self.window.hidden = YES;
    } else {
        imageView = [[UIImageView alloc]initWithFrame:[self.window frame]];
        [imageView setImage:splash];
        [UIApplication.sharedApplication.keyWindow.subviews.lastObject addSubview:imageView];
    }
}

- (UIImage*)imageNamedForDevice:(NSString*)name
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (([UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale) >= 1136.0f) {
            name = [name stringByAppendingString:@"-568h@2x"];
        }
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        name = [name stringByAppendingString:@"-Portrait"];
    }
    return [UIImage imageNamed: name];
}


// Code below borrowed from the CDV splashscreen plugin (https://github.com/apache/cordova-plugin-splashscreen)
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
  
  if (device.iPhone5) { // does not support landscape
    imageName = [imageName stringByAppendingString:@"-568h"];
  } else if (device.iPhone6) { // does not support landscape
    imageName = [imageName stringByAppendingString:@"-667h"];
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