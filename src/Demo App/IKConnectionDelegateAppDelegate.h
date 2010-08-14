#import <UIKit/UIKit.h>

@class IKConnectionDelegateViewController;

@interface IKConnectionDelegateAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    IKConnectionDelegateViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet IKConnectionDelegateViewController *viewController;

@end

