//
//  ACMainViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 14/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACFlipsideViewController.h"
#import "ACImagePickerDelegate.h"

@interface ACMainViewController : UIViewController <ACFlipsideViewControllerDelegate>

- (IBAction)showInfo:(id)sender;
- (BOOL)startCameraControllerFrom: (UIViewController*) controller 
                    usingDelegate: (id <UIImagePickerControllerDelegate,
                                                   UINavigationControllerDelegate>) delegate;
    
@end
