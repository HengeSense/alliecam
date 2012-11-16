//
//  OverlayViewController.m
//  AllieCam
//
//  Created by Mark Blackwell on 15/11/12.
//
//

#import "ACCameraViewController.h"

@implementation ACCameraViewController

@synthesize delegate, imagePickerController, albumButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initipalization
        self.imagePickerController = [[[UIImagePickerController alloc] init] autorelease];
        self.imagePickerController.delegate = self;
    }
    return self;
}

- (void)showCamera
{
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.showsCameraControls = YES;
    
    if ([[self.imagePickerController.cameraOverlayView subviews] count] == 0)
    {
        // setup our custom overlay view for the camera
        // ensure that our custom view's frame fits within the parent frame
        CGRect overlayViewFrame = self.imagePickerController.cameraOverlayView.frame;
        CGRect newFrame = CGRectMake(0.0,
                                     CGRectGetHeight(overlayViewFrame) -
                                     self.view.frame.size.height - 10.0,
                                     CGRectGetWidth(overlayViewFrame),
                                     self.view.frame.size.height + 10.0);
        self.view.frame = newFrame;
        [self.imagePickerController.cameraOverlayView addSubview:self.view];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self showCamera];
}

- (void)viewDidUnload
{
    self.albumButton = nil;
    
    [super viewDidUnload];
}

- (void)dealloc
{	
    [albumButton release];
    [imagePickerController release];

    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)albumButtonTouchUpInside:(id)sender {
}

#pragma mark UIImagePickerControllerDelegate

// this get called when an image has been chosen from the library or taken from the camera
//
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    // give the taken picture to our delegate
    if (self.delegate)
        [self.delegate didTakePicture:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.delegate didFinishWithCamera];    // tell our delegate we are finished with the picker
}
@end
