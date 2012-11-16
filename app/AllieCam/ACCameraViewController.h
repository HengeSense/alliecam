//
//  OverlayViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 15/11/12.
//
//

#import <UIKit/UIKit.h>

@protocol ACCameraViewControllerDelegate;

@interface ACCameraViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    
    id <ACCameraViewControllerDelegate> _delegate;
    
    UIImagePickerController *_imagePickerController;
    
@private
    UIButton *_albumButton;
}

@property (nonatomic, assign) id <ACCameraViewControllerDelegate> delegate;
@property (nonatomic, retain) UIImagePickerController *imagePickerController;

@property (nonatomic, retain) IBOutlet UIButton *albumButton;

- (void)showCamera;
- (IBAction)albumButtonTouchUpInside:(id)sender;

@end

@protocol ACCameraViewControllerDelegate
- (void)didTakePicture:(UIImage *)picture;
- (void)didFinishWithCamera;
@end
