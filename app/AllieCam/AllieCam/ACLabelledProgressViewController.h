//
//  ACLabelledProgressViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 11/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACLabelledProgressViewController : UIViewController
@property (retain, nonatomic) IBOutlet UIProgressView *progressBar;
@property (retain, nonatomic) IBOutlet UILabel *progressLabel;

@end
