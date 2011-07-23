//
//  OAuthWithCallbackAppDelegate.h
//  OAuthWithCallback
//
//  Created by Adriaan Tijsseling on 11/07/23.
//  Copyright 2011 Sanoma Digital. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAuthWithCallbackViewController;

@interface OAuthWithCallbackAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet OAuthWithCallbackViewController *viewController;

@end
