/*
     File: AppDelegate.h 
 Abstract: The application delegate class used for installing our main navigation controller.
  
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

#import <UIKit/UIKit.h>

#import <AWSiOSSDK/AmazonLogger.h>
#import <AWSiOSSDK/AmazonErrorHandler.h>
#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import "UIImage+fixOrientation.h"

// Constants used to represent your AWS Credentials.
#define ACCESS_KEY_ID          @"AKIAI5J5NZBZUYENJXHA"
#define SECRET_KEY             @"8eqSgTOh5nWD7MEbw6jpbVwEQ3/Xn4iebkeOYSV1"


// Constants for the Bucket and Object name.
//#define UNIQUE_NAME            @"my-unique-name"
#define PICTURE_BUCKET         @"blackwellfamily"
//#define PICTURE_NAME           @"yyyyMMddHHmm"
//#define UPLOAD_URL             @"http://www.alliecam.net/photos/add"
#define UPLOAD_URL             @"http://localhost/~mblackwell8/alliecam/photos/add"

@interface AppDelegate : NSObject <UIApplicationDelegate, AmazonServiceRequestDelegate>
{
	UIWindow *window;
	UINavigationController *navController;
    UIBackgroundTaskIdentifier uploadTaskID;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;
@property (nonatomic, retain) AmazonS3Client *s3;

- (void)sendToS3:(NSDictionary *)info
        filename:(NSString *)filename
       albumname:(NSString *)albumname
      startBlock:(void (^)(void))start
        endBlock:(void (^)(void))end;

@end
