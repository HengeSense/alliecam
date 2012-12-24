//
//  ACWaitViewController.m
//  AllieCam
//
//  Created by Mark Blackwell on 7/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACWaitViewController.h"

@interface ACWaitViewController ()

@end

@implementation ACWaitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_statusLabel release];
    [_activityView release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setStatusLabel:nil];
    [self setActivityView:nil];
    [super viewDidUnload];
}
@end
