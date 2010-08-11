//
//  IKConnectionDelegateAppDelegate.h
//  IKConnectionDelegate
//
//  Created by Илья Кулаков on 11.08.10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IKConnectionDelegateViewController;

@interface IKConnectionDelegateAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    IKConnectionDelegateViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet IKConnectionDelegateViewController *viewController;

@end

