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

- (UIView *)blurView
{
    if( nil == _blurView )
    {
        FXBlurView *blurView = [[FXBlurView alloc]initWithFrame:self.window.frame];
        blurView.tintColor = [UIColor blackColor];
        blurView.blurRadius = 9;
        blurView.iterations = 3;
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
