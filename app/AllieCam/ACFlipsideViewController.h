//
//  ACFlipsideViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 14/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACFlipsideViewController;

@protocol ACFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(ACFlipsideViewController *)controller;
@end

@interface ACFlipsideViewController : UIViewController

@property (assign, nonatomic) IBOutlet id <ACFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
