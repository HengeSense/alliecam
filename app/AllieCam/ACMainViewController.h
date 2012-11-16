//
//  ACMainViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 14/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACFlipsideViewController.h"
#import "ACCameraViewController.h"

@interface ACMainViewController : UIViewController <ACFlipsideViewControllerDelegate, ACCameraViewControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    ACCameraViewController *_cameraController;
    UIImagePickerController *_albumController;
    
    NSMutableArray *_capturedImages; // the list of images captures from the camera (either 1 or multiple)
    
}

@property (nonatomic, retain) ACCameraViewController *cameraController;
@property (nonatomic, retain) UIImagePickerController *albumController;
@property (nonatomic, retain) NSMutableArray *capturedImages;

- (IBAction)showInfo:(id)sender;
- (void)showCamera;
- (void)showAlbum;

- (IBAction)launchImagePickerController;
    
@end
