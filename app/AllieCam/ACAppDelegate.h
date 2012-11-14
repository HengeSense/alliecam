//
//  ACAppDelegate.h
//  AllieCam
//
//  Created by Mark Blackwell on 14/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACMainViewController;

@interface ACAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ACMainViewController *mainViewController;

@end
