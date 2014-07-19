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
  [[UIApplication sharedApplication] ignoreSnapshotOnNextApplicationLaunch];
  // Add any notification observers here...

	// This actually calls the original init method over in AppDelegate. Equivilent to calling super
	// on an overrided method, this is not recursive, although it appears that way. neat huh?
	return [self swizzled_init];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  if (imageView == NULL) {
    [[UIApplication sharedApplication] ignoreSnapshotOnNextApplicationLaunch];
    self.window.hidden = NO;
  } else {
    [imageView removeFromSuperview];
  }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // for now, assuming 'Default' is the basename of the splashscreen, with a fallback to hiding the window
  UIImage *splash = [self imageNamedForDevice: @"Default"];
  if (splash == NULL) {
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

@end
