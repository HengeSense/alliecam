//
//  ACWaitViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 7/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACWaitViewController : UIViewController
@property (retain, nonatomic) IBOutlet UILabel *statusLabel;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

@end
