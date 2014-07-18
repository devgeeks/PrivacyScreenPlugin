/**
 * AppDelegate+notification.m
 * Created by Tommy-Carlos Williams on 18/07/2014
 * Copyright (c) 2014 Tommy-Carlos Williams. All rights reserved.
 * MIT Licensed
 */
#import "AppDelegate+privacyscreen.h"
#import <objc/runtime.h>

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
  self.window.hidden = NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  self.window.hidden = YES;
}

@end
