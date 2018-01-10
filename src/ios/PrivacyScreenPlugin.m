/**
 * PrivacyScreenPlugin.m
 * Created by Tommy-Carlos Williams on 18/07/2014
 * Copyright (c) 2014 Tommy-Carlos Williams. All rights reserved.
 * MIT Licensed
 */
#import "PrivacyScreenPlugin.h"

#define PRIVACY_TIMER_DEFAULT   3.0f;

static UIImageView *imageView;

@interface PrivacyScreenPlugin ()

@property (strong, nonatomic) NSTimer* privacyTimer;
@property (nonatomic) float privacyTimerInterval;
@end


@implementation PrivacyScreenPlugin

#pragma mark - Initialize
- (void)pluginInitialize
{
    NSString* privacyTimerKey = @"privacytimer";
    NSString* prefTimer = [self.commandDelegate.settings objectForKey:[privacyTimerKey lowercaseString]];
    //Default value
    self.privacyTimerInterval = PRIVACY_TIMER_DEFAULT;
    if(prefTimer)
        self.privacyTimerInterval = [prefTimer floatValue] > 0.0f ? [prefTimer floatValue] : PRIVACY_TIMER_DEFAULT;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPageDidLoad)
                                                 name:CDVPageDidLoadNotification object:nil];
    
    NSString* onBackgroundKey = @"privacyonbackground";
    
    if([self.commandDelegate.settings objectForKey:[onBackgroundKey lowercaseString]] && [[self.commandDelegate.settings objectForKey:[onBackgroundKey lowercaseString]] isEqualToString:@"true"])
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];
    else
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - Explicit Commands
- (void) setTimer:(CDVInvokedUrlCommand*)command
{
    if(command.arguments.count > 0)
    {
        if(!command.arguments[0] || command.arguments[0] == [NSNull null])
        {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Timer argument is null"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        //timeInterval argument
        self.privacyTimerInterval = [command.arguments[0] floatValue];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    else
    {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"No arguments provided"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void) hidePrivacyScreen:(CDVInvokedUrlCommand*)command
{
     [self removePrivacyScreen];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) showPrivacyScreen:(CDVInvokedUrlCommand*)command
{
    [self applyPrivacyScreen];
    [self.privacyTimer invalidate];
    self.privacyTimer = [NSTimer scheduledTimerWithTimeInterval:self.privacyTimerInterval
                                                         target:self
                                                       selector:@selector(removePrivacyScreen)
                                                       userInfo:nil
                                                        repeats:NO];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - Triggered functions
- (void) onPageDidLoad
{
    [self removePrivacyScreen];
}

- (void)onAppDidBecomeActive:(UIApplication *)application
{
    [self.privacyTimer invalidate];
    //if(!self.privacyTimer || !self.privacyTimer.valid)
    self.privacyTimer = [NSTimer scheduledTimerWithTimeInterval:self.privacyTimerInterval
                                                         target:self
                                                       selector:@selector(removePrivacyScreen)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)onAppWillResignActive:(UIApplication *)application
{
    [self applyPrivacyScreen];
}

#pragma mark - Helper functions
-(void) removePrivacyScreen
{
    if(imageView)
    {
        self.viewController.view.window.hidden = NO;
        
        
        [UIView animateWithDuration:0.1f
                         animations:^{
                             imageView.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             [imageView removeFromSuperview];
                         }];
        
    }
    
//    if(self.privacyTimer || self.privacyTimer.valid)
//    {
    [self.privacyTimer invalidate];
    self.privacyTimer = nil;
//    }
}

-(void) applyPrivacyScreen
{
    CDVViewController *vc = (CDVViewController*)self.viewController;
    NSString *imgName = [self getImageName:(id<CDVScreenOrientationDelegate>)vc device:[self getCurrentDevice]];
    UIImage* splash;
    if([self isUsingCDVLaunchScreen])
    {
        splash = [self updatePrivacyImage];
    }
    else
    {
        splash = [self getImageFromName:imgName];
   
    }
    
    if (splash == NULL)
    {
        self.viewController.view.window.hidden = YES;
    }
    else
    {
        if(![self isUsingCDVLaunchScreen])
        {
            [imageView removeFromSuperview];
            imageView = nil;
            
            imageView = [[UIImageView alloc]initWithFrame:[self.viewController.view bounds]];
            [imageView setImage:splash];
        }
        
#ifdef __CORDOVA_4_0_0
        [[UIApplication sharedApplication].keyWindow addSubview:imageView];
#else
        [self.viewController.view addSubview:imageView];
#endif
        
    }

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
    device.iPhone4 = (device.iPhone && limit == 480.0);
    device.iPhone5 = (device.iPhone && limit == 568.0);
    // note these below is not a true device detect, for example if you are on an
    // iPhone 6/6+ but the app is scaled it will prob set iPhone5 as true, but
    // this is appropriate for detecting the runtime screen environment
    device.iPhone6 = (device.iPhone && limit == 667.0);
    device.iPhone6Plus = (device.iPhone && limit == 736.0);
    
    return device;
}

- (BOOL) isUsingCDVLaunchScreen {
    NSString* launchStoryboardName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UILaunchStoryboardName"];
    if (launchStoryboardName) {
        return ([launchStoryboardName isEqualToString:@"CDVLaunchScreen"]);
    } else {
        return NO;
    }
}

// Sets the view's frame and image.
- (UIImage*)updatePrivacyImage
{
    NSString* imageName = [self getImageName:(id<CDVScreenOrientationDelegate>)self.viewController device:[self getCurrentDevice]];
    
    UIImage* img = [UIImage imageNamed:imageName];
    [imageView removeFromSuperview];
    imageView = nil;
    
    imageView = [[UIImageView alloc]initWithFrame:[self.viewController.view bounds]];
    [imageView setImage: img];
    
    // Check that splash screen's image exists before updating bounds
    if (imageView.image)
    {
        [self updateBounds];
    }
    else
    {
        NSLog(@"WARNING: The splashscreen image named %@ was not found", imageName);
    }
    return img;
}

- (void)updateBounds
{
    if ([self isUsingCDVLaunchScreen]) {
        // CB-9762's launch screen expects the image to fill the screen and be scaled using AspectFill.
        CGSize viewportSize = [UIApplication sharedApplication].delegate.window.bounds.size;
        imageView.frame = CGRectMake(0, 0, viewportSize.width, viewportSize.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        return;
    }
    
    UIImage* img = imageView.image;
    CGRect imgBounds = (img) ? CGRectMake(0, 0, img.size.width, img.size.height) : CGRectZero;
    
    CGSize screenSize = [self.viewController.view convertRect:[UIScreen mainScreen].bounds fromView:nil].size;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGAffineTransform imgTransform = CGAffineTransformIdentity;
    
    /* If and only if an iPhone application is landscape-only as per
     * UISupportedInterfaceOrientations, the view controller's orientation is
     * landscape. In this case the image must be rotated in order to appear
     * correctly.
     */
    CDV_iOSDevice device = [self getCurrentDevice];
    if (UIInterfaceOrientationIsLandscape(orientation) && !device.iPhone6Plus && !device.iPad)
    {
        imgTransform = CGAffineTransformMakeRotation(M_PI / 2);
        imgBounds.size = CGSizeMake(imgBounds.size.height, imgBounds.size.width);
    }
    
    // There's a special case when the image is the size of the screen.
    if (CGSizeEqualToSize(screenSize, imgBounds.size))
    {
        CGRect statusFrame = [self.viewController.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView:nil];
        if (!(IsAtLeastiOSVersion(@"7.0")))
        {
            imgBounds.origin.y -= statusFrame.size.height;
        }
    }
    else if (imgBounds.size.width > 0)
    {
        CGRect viewBounds = self.viewController.view.bounds;
        CGFloat imgAspect = imgBounds.size.width / imgBounds.size.height;
        CGFloat viewAspect = viewBounds.size.width / viewBounds.size.height;
        // This matches the behaviour of the native splash screen.
        CGFloat ratio;
        if (viewAspect > imgAspect)
        {
            ratio = viewBounds.size.width / imgBounds.size.width;
        }
        else
        {
            ratio = viewBounds.size.height / imgBounds.size.height;
        }
        imgBounds.size.height *= ratio;
        imgBounds.size.width *= ratio;
    }
    
    imageView.transform = imgTransform;
    imageView.frame = imgBounds;
}




- (NSString*)getImageName:(id<CDVScreenOrientationDelegate>)orientationDelegate device:(CDV_iOSDevice)device
{
    
    NSString* imageName;
    // detect if we are using CB-9762 Launch Storyboard; if so, return the associated image instead
    if ([self isUsingCDVLaunchScreen]) {
        // Use UILaunchImageFile if specified in plist.  Otherwise, use Default.
        imageName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UILaunchImageFile"];
        imageName = [imageName stringByDeletingPathExtension];
        imageName = imageName ? imageName : @"LaunchImage";
        return imageName;
    }
    NSString* privacyImageNameKey = @"privacyimagename";
    NSString* prefImageName = [self.commandDelegate.settings objectForKey:[privacyImageNameKey lowercaseString]];
    imageName = prefImageName ? prefImageName : @"Default";
    //Override Launch images?
    NSString* privacyOverrideLaunchImage = @"privacyoverridelaunchimage";
    if([self.commandDelegate.settings objectForKey:[privacyOverrideLaunchImage lowercaseString]] && [[self.commandDelegate.settings objectForKey:[privacyOverrideLaunchImage lowercaseString]] isEqualToString:@"true"])
    {
        
    }
    else
    {
        // Use UILaunchImageFile if specified in plist.  Otherwise, use Default.
        imageName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UILaunchImageFile"];
        imageName = [imageName stringByDeletingPathExtension];
    }
    
    NSUInteger supportedOrientations = [orientationDelegate supportedInterfaceOrientations];
    
    // Checks to see if the developer has locked the orientation to use only one of Portrait or Landscape
    BOOL supportsLandscape = (supportedOrientations & UIInterfaceOrientationMaskLandscape);
    BOOL supportsPortrait = (supportedOrientations & UIInterfaceOrientationMaskPortrait || supportedOrientations & UIInterfaceOrientationMaskPortraitUpsideDown);
    // this means there are no mixed orientations in there
    BOOL isOrientationLocked = !(supportsPortrait && supportsLandscape);
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    // Add Asset Catalog specific prefixes
    if ([imageName isEqualToString:@"LaunchImage"])
    {
        if(device.iPhone4 || device.iPhone5 || device.iPad) {
            imageName = [imageName stringByAppendingString:@"-700"];
        } else if(device.iPhone6) {
            imageName = [imageName stringByAppendingString:@"-800"];
        } else if(device.iPhone6Plus) {
            imageName = [imageName stringByAppendingString:@"-800"];
            if (deviceOrientation == UIDeviceOrientationPortrait || deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
                imageName = [imageName stringByAppendingString:@"-Portrait"];
            }
        }
    }
    
    BOOL isLandscape = supportsLandscape &&
    (deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight);
    
    if (device.iPhone4) { // does not support landscape
        imageName = isLandscape ? nil : [imageName stringByAppendingString:@"-480h"];
    } else if (device.iPhone5) { // does not support landscape
        imageName = isLandscape ? nil : [imageName stringByAppendingString:@"-568h"];
    } else if (device.iPhone6) { // does not support landscape
        imageName = isLandscape ? nil : [imageName stringByAppendingString:@"-667h"];
    } else if (device.iPhone6Plus) { // supports landscape
        if (isOrientationLocked) {
            imageName = [imageName stringByAppendingString:(supportsLandscape ? @"-Landscape" : @"")];
        } else {
            switch (deviceOrientation) {
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
            switch (deviceOrientation) {
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
//    if(imageName)
//    {
//        imageName = [imageName stringByAppendingString:@".png"];
//    }
    return imageName;
}

- (UIImage*) getImageFromName:(NSString*) imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    if (image == NULL)
    {
        //If not in bundle try to go to resources path
        NSString* imagePath = [imageName stringByAppendingString:@".png"];
        image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:imagePath]];
        if(image)
            return image;
        
        //try to take out hyfens and see if that works (Compatbility with Outsystems mobile issue)
        imageName = [imageName stringByReplacingOccurrencesOfString:@"-" withString:@""];
        image = [UIImage imageNamed:imageName];
        if(image == NULL)
        {
            imagePath = [imageName stringByAppendingString:@".png"];
            image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:imagePath]];
            //If still null image doesn't really exist.
        }
    }
    
    
    return image;
}

@end
