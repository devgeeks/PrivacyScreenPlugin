/**
 * AppDelegate+notification.h
 * Created by Tommy-Carlos Williams on 18/07/2014
 * Copyright (c) 2014 Tommy-Carlos Williams. All rights reserved.
 * MIT Licensed
 */
#import "AppDelegate.h"

typedef struct {
  BOOL iPhone;
  BOOL iPad;
  BOOL iPhone5;
  BOOL iPhone6;
  BOOL iPhone6Plus;
  BOOL retina;
  
} CDV_iOSDevice;

@interface AppDelegate (privacyscreen)
- (void)applicationWillResignActive:(UIApplication *)application;
- (void)applicationDidBecomeActive:(UIApplication *)application;

@end