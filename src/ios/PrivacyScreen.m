/*
 
 2 possibilities for the privacy screen. 
 
 1. do not define BLUR, or define it as BLUR=0 to have an opaque screen with the logo centered
    as privacy screen. You can hardcode a background color (code commented out), or by default 
    the top left pixel color of the logo will be used as opaque background color. The alpha
    value is not taken into account.
 2. define BLUR=1 to have a blurred view of the current application content as privacy screen.
 
 Define these in the iOS project Build settings > Preprocessor macros
 
 */



#import "PrivacyScreen.h"
#import "FXBlurView.h"

@interface PrivacyScreen ()

@property (nonatomic, strong) UIView *blurView;

@end

@implementation PrivacyScreen

- (void) activate:(CDVInvokedUrlCommand *) command
{
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void) pluginInitialize
{
    //[super pluginInitialize];
    [self removeObservers];
    [self addObservers];
    
    [self blurView]; // create the blurview in advance.
}

- (void) onReset
{
    //[super onReset];
    
    [self removeObservers];
    [self addObservers];
}

- (void) addObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(applicationWillResignActive:)
               name:UIApplicationWillResignActiveNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(applicationDidBecomeActive:)
               name:UIApplicationDidBecomeActiveNotification
             object:nil];
}

- (void) removeObservers
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc removeObserver:self];
}

- (UIWindow *) window
{
    return [[UIApplication sharedApplication].delegate window];
}

- (UIColor*)pixelColorInImage:(UIImage*)image atX:(int)x atY:(int)y {
    
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const UInt8* data = CFDataGetBytePtr(pixelData);
    
    int pixelInfo = ((image.size.width  * y) + x ) * 4; // 4 bytes per pixel
    
    UInt8 red   = data[pixelInfo + 0];
    UInt8 green = data[pixelInfo + 1];
    UInt8 blue  = data[pixelInfo + 2];
    UInt8 alpha = data[pixelInfo + 3];
    CFRelease(pixelData);
    
    return [UIColor colorWithRed:red/255.0f
                           green:green/255.0f
                            blue:blue/255.0f
                           alpha:1];
}

- (UIView *)blurView
{
    if( nil == _blurView )
    {
#if BLUR
        FXBlurView *blurView = [[FXBlurView alloc]initWithFrame:self.window.frame];
        blurView.tintColor = [UIColor blackColor];
        blurView.blurRadius = 9;
        blurView.iterations = 3;
#else // OPAQUE
        UIView *blurView = [[UIView alloc]initWithFrame:self.window.frame];
        
        UIImage *logo = [UIImage imageNamed:@"icon"];
        UIImageView *iv = [[UIImageView alloc]initWithImage:logo];
        iv.tag = 4;
        
        // hard coded background color:
        //blurView.backgroundColor = [UIColor colorWithRed:133./255. green:255./255. blue:128./255. alpha:1];
        
        // sampled background color:
        blurView.backgroundColor = [self pixelColorInImage:logo atX:0 atY:0];
        
        [blurView addSubview:iv];
        iv.center = blurView.center;
#endif
        
        _blurView = blurView;
    }
    return _blurView;
}

- (void) showBlurView
{
    self.blurView.alpha = 1;
    UIView *coverView = self.blurView;
    coverView.frame = self.window.frame;
    coverView.transform = CGAffineTransformIdentity;
    coverView.layer.transform = CATransform3DIdentity;
    [coverView viewWithTag:4].center = coverView.center;
    
    [self.window addSubview:coverView];
}

- (void) applicationWillResignActive:(NSNotification *) notification
{
    [self showBlurView];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBlurView) object:nil];
    [self performSelector:@selector(hideBlurView) withObject:nil afterDelay:0.1];
}

- (void) hideBlurView
{
    UIView *blurView = self.blurView;
    
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         blurView.alpha = 0;
                         
                     } completion:^(BOOL finished) {
                         [blurView removeFromSuperview];
                     }];
}

@end
