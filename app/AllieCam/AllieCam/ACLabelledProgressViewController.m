//
//  ACLabelledProgressViewController.m
//  AllieCam
//
//  Created by Mark Blackwell on 11/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACLabelledProgressViewController.h"

@interface ACLabelledProgressViewController ()

@end

@implementation ACLabelledProgressViewController

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
    [_progressLabel release];
    [_progressBar release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setProgressLabel:nil];
    [self setProgressBar:nil];
    [super viewDidUnload];
}
@end
