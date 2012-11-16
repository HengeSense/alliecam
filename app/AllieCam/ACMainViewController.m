//
//  ACMainViewController.m
//  AllieCam
//
//  Created by Mark Blackwell on 14/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACMainViewController.h"

@implementation ACMainViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.cameraController =
        [[[ACCameraViewController alloc] initWithNibName:@"ACCameraViewController" bundle:nil] autorelease];

    // as a delegate we will be notified when pictures are taken and when to dismiss the image picker
    self.cameraController.delegate = self;
    
    self.albumController = [[[UIImagePickerController alloc] init] autorelease];
    self.albumController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    self.albumController.delegate = self;
    
    self.capturedImages = [NSMutableArray array];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showAlbum];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)showCamera {
    [self.cameraController showCamera];
    [self presentModalViewController:self.cameraController.imagePickerController animated:YES];
    
}
- (void)showAlbum {
    [self presentModalViewController:self.albumController animated:YES];
    
}


#pragma mark -
#pragma mark ACCameraViewControllerDelegate

// as a delegate we are being told a picture was taken
- (void)didTakePicture:(UIImage *)picture
{
    [self.capturedImages addObject:picture];
}

// as a delegate we are told to finished with the camera
- (void)didFinishWithCamera
{
    [self dismissModalViewControllerAnimated:YES];
    
    [self showAlbum];
    
}

#pragma mark UIImagePickerControllerDelegate

// this get called when an image has been chosen from the library or taken from the camera
//
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
    [self showCamera];
}


#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(ACFlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{    
    ACFlipsideViewController *controller = [[[ACFlipsideViewController alloc] initWithNibName:@"ACFlipsideViewController" bundle:nil] autorelease];
    controller.delegate = self;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
}
//
//- (BOOL)startCameraControllerFrom: (UIViewController*) controller
//                    usingDelegate: (id <UIImagePickerControllerDelegate,
//                                                   UINavigationControllerDelegate>) delegate {
//    if (([UIImagePickerController isSourceTypeAvailable:
//          UIImagePickerControllerSourceTypeCamera] == NO)
//        || (delegate == nil)
//        || (controller == nil))
//        return NO;
//    
//    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
//    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
//    
//    // Displays a control that allows the user to choose picture or
//    // movie capture, if both are available:
//    
//    cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
//    
//    // Hides the controls for moving & scaling pictures, or for
//    // trimming movies. To instead show the controls, use YES.
//    cameraUI.allowsEditing = NO;
//    cameraUI.delegate = delegate;
//    
//    [controller presentModalViewController: cameraUI animated: YES];
//    
//    return YES;
//}

@end
