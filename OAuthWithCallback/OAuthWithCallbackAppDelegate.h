#import <UIKit/UIKit.h>

@class OAuthWithCallbackViewController;

@interface OAuthWithCallbackAppDelegate : NSObject <UIApplicationDelegate> {}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet OAuthWithCallbackViewController *viewController;

@end
