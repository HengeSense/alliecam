/*
     File: MyViewController.m 
 Abstract: The main view controller of this app.
  
  Version: 1.1 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import "MainViewController.h"

@implementation MainViewController

@synthesize imageView, myToolbar, timedCamera, standardCamera, album, pickerAlbum, capturedImages;

- (id)init {
    if ((self = [super init])) {
        _isStartingUp = YES;
    }
    
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        _isStartingUp = YES;
    }
    return self;
}

- (void)awakeFromNib {
    _isStartingUp = YES;
    _shouldUseTimedCamera = NO;
    [super awakeFromNib];
}


#pragma mark -
#pragma mark View Controller

- (void)viewDidLoad
{
    self.timedCamera =
        [[[TimedCameraViewController alloc] initWithNibName:@"TimedCameraViewContoller" bundle:nil] autorelease];

    // as a delegate we will be notified when pictures are taken and when to dismiss the image picker
    self.timedCamera.delegate = self;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.standardCamera = [[[UIImagePickerController alloc] init] autorelease];
        self.standardCamera.delegate = self;
        self.standardCamera.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.standardCamera.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypeCamera];
    }
    
    self.album = [[[UIImagePickerController alloc] init] autorelease];
    self.album.delegate = self;
    self.album.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    self.album.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType: UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    

//    self.pickerAlbum = [[[ELCImagePickerDemoViewController alloc] init] autorelease];
    ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] initWithNibName:@"ELCAlbumPickerController" bundle:[NSBundle mainBundle]];
	self.pickerAlbum = [[[ELCImagePickerController alloc] initWithRootViewController:albumController] autorelease];
    [albumController setParent:self.pickerAlbum];
	[self.pickerAlbum setDelegate:self];
    [albumController release];
    
    self.capturedImages = [NSMutableArray array];
    _showing = @"home";

    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        // camera is not on this device, don't show the camera button
        NSMutableArray *toolbarItems = [NSMutableArray arrayWithCapacity:self.myToolbar.items.count];
        [toolbarItems addObjectsFromArray:self.myToolbar.items];
        [toolbarItems removeObjectAtIndex:2];
        [self.myToolbar setItems:toolbarItems animated:NO];
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_isStartingUp) {
        [self showCamera];
        _isStartingUp = NO;
    }
}

- (void)viewDidUnload
{
    self.imageView = nil;
    self.myToolbar = nil;
    
    self.timedCamera = nil;
    self.standardCamera = nil;
    
    self.capturedImages = nil;
}

- (void)dealloc
{	
	[imageView release];
	[myToolbar release];
    
    [timedCamera release];
    [standardCamera release];
	[capturedImages release];
    
    [super dealloc];
}

- (void)showCamera {
    if (self.capturedImages.count > 0)
        [self.capturedImages removeAllObjects];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        if (_shouldUseTimedCamera) {
            [self.timedCamera setupImagePicker:UIImagePickerControllerSourceTypeCamera];
            [self presentModalViewController:self.timedCamera.imagePickerController animated:YES];
        }
        else {
            [self presentModalViewController:self.standardCamera animated:YES];
        }
    }
    _showing = @"camera";
}
- (void)showAlbum {
    if (self.capturedImages.count > 0)
        [self.capturedImages removeAllObjects];
    
//    [self presentModalViewController:self.album animated:YES];
    
	[self presentModalViewController:self.pickerAlbum animated:YES];

    _showing = @"album";
    
}


#pragma mark -
#pragma mark Toolbar Actions

- (IBAction)albumAction:(id)sender
{
    [self showAlbum];
}

- (IBAction)cameraAction:(id)sender
{
    [self showCamera];
}

- (void)uploadCapturedImages {
    NSUInteger count = self.capturedImages.count;
    NSUInteger posn = 1;
    for(NSDictionary *picture in self.capturedImages) {
        NSLog(@"Sending to Amazon S3");
        AppDelegate *del = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [del sendToS3:picture
           startBlock:^(NSString *message) {
               NSString *final_message = [NSString stringWithFormat:@"%@ (%d of %d)", message, posn, count];
               NSLog(@"upload starting");
               [self performSelectorOnMainThread:@selector(startWaitAnimationWithMessage:)
                                      withObject:final_message
                                   waitUntilDone:NO];
            }
             endBlock:^ {
                 NSLog(@"upload finishing");
                 [self performSelectorOnMainThread:@selector(stopWaitAnimationWithMessage:)
                                      withObject:@"Done."
                                   waitUntilDone:NO];
             }];
        
    }

}

- (void)startWaitAnimationWithMessage:(NSString *)message {
    [self.uploadActivityIndicator startAnimating];
    self.uploadLabel.text = message;
}
- (void)stopWaitAnimationWithMessage:(NSString *)message {
    [self.uploadActivityIndicator stopAnimating];
    self.uploadLabel.text = message;
}

// probably better not to do this in the VC, because will stop processing on app close (?)
// looks like better approach here: http://stackoverflow.com/questions/3928861/best-practice-to-send-a-lot-of-data-in-background-on-ios4-device which uses beginBackgroundTaskWithExpirationHandler on the UIApplication
//- (void)processGrandCentralDispatchUpload:(NSData *)imageData
//{
//    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//    dispatch_async(queue, ^{
//
//        // Upload image data.  Remember to set the content type.
//        NSDateFormatter *formatter;
//        formatter = [[[NSDateFormatter alloc] init] autorelease];
//        [formatter setDateFormat:PICTURE_NAME];
//        NSString *filename = [formatter stringFromDate:[NSDate date]];
//        NSLog(@"Uploading to %@ with filename %@", PICTURE_BUCKET, filename);
//        S3PutObjectRequest *por = [[[S3PutObjectRequest alloc] initWithKey:filename
//                                                                  inBucket:PICTURE_BUCKET] autorelease];
//        por.contentType = @"image/jpeg";
//        por.data        = imageData;
//
//        // Put the image data into the specified s3 bucket and object.
//        S3PutObjectResponse *putObjectResponse = [self.s3 putObject:por];
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            
//            if(putObjectResponse.error != nil)
//            {
//                NSLog(@"Error: %@", putObjectResponse.error);
//            }
//            else {
//                NSLog(@"Done");
//            }
//
//            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//        });
//    });
//}


#pragma mark -
#pragma mark UIImagePickerControllerDelegate

// this get called when an image has been chosen from the library or taken from the camera
//
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
//    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [self.capturedImages addObject:info];
    
    [self dismissModalViewControllerAnimated:YES];
    if (_showing == @"camera") {
#ifdef DEBUG
        UIImageWriteToSavedPhotosAlbum(picture, nil, nil, nil);
#else
        NSLog(@"Not storing photo in debug mode");
#endif
        // putting this on a background thread doesn't seem to work
//        [self performSelectorInBackground:@selector(storeAndUpload) withObject:nil];
        [self uploadCapturedImages];
    }
    
    if ([self.capturedImages count] > 0) {
        [self.imageView setImage:[self.capturedImages objectAtIndex:0]];
    }

    _showing = @"home";
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
    if ([self.capturedImages count] > 0) {
        NSDictionary *info = [self.capturedImages objectAtIndex:0];
        [self.imageView setImage:[info valueForKey:UIImagePickerControllerOriginalImage]];
    }
    _showing = @"home";
}

#pragma mark -
#pragma mark OverlayViewControllerDelegate

// as a delegate we are being told a picture was taken
- (void)didTakePicture:(UIImage *)picture
{
    NSLog(@"not implemented");
//    [self.capturedImages addObject:picture];
}

// as a delegate we are told to finished with the camera
- (void)didFinishWithCamera
{
    NSLog(@"not implemented");
//    [self dismissModalViewControllerAnimated:YES];
//    [self uploadCapturedImages];
//    
//    if ([self.capturedImages count] > 0) {
//        [self.imageView setImage:[self.capturedImages objectAtIndex:0]];
//    }

}

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info {
	
	[self dismissModalViewControllerAnimated:YES];
	
    for (NSDictionary *dict in info) {
//        UIImage *picture = (UIImage *)[dict objectForKey:UIImagePickerControllerOriginalImage];
        [self.capturedImages addObject:dict];
    }
    [self uploadCapturedImages];
    _showing = @"home";
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker {
    
	[self dismissModalViewControllerAnimated:YES];
    _showing = @"home";
}


@end