//
//  ACAppDelegate.h
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AWSiOSSDK/AmazonLogger.h>
#import <AWSiOSSDK/AmazonErrorHandler.h>
#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import "AFAmazonS3Client.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

#import "UIImage+fixOrientation.h"

// no idea why i need to import the .m file also, but seems to fix a bad selector problem
#import "UIImage+fixOrientation.m"

// Constants used to represent your AWS Credentials.
#define ACCESS_KEY_ID          @"AKIAI5J5NZBZUYENJXHA"
#define SECRET_KEY             @"8eqSgTOh5nWD7MEbw6jpbVwEQ3/Xn4iebkeOYSV1"


// Constants for the Bucket and Object name.
//#define UNIQUE_NAME            @"my-unique-name"
#define PICTURE_BUCKET         @"blackwellfamily"
//#define PICTURE_NAME           @"yyyyMMddHHmm"
#define UPLOAD_URL             @"http://www.alliecam.net/photos/add"
//#define UPLOAD_URL             @"http://localhost/~mblackwell8/alliecam/photos/add"

// upload task takes a LOT of memory (S3?), which crashes the app
#define kMaxConcurrentUploads   1
#define kPendingUploadsFile    @"pending_uploads.plist"
#define kPendingUploadMetadataKey   @"metadata"
#define kPendingUploadFilenameKey   @"filename"
#define kPendingUploadAlbumnameKey   @"albumname"
#define kPendingUploadUploadStatusKey   @"uploadStatus"


#define DO_AWS_UPLOAD
//#define USE_AWS_OFFICIAL_CLIENT

@class ACLocalPhoto;


@interface ACAppDelegate : UIResponder <UIApplicationDelegate> {
    dispatch_semaphore_t _uploadSemaphore;
}

@property (strong, nonatomic) UIWindow *window;

@property UIBackgroundTaskIdentifier uploadTaskID;

#ifdef USE_AWS_OFFICIAL_CLIENT
@property (nonatomic, retain) AmazonS3Client *s3;
#else
@property (nonatomic, retain) AFAmazonS3Client *s3;
#endif

- (void)upload:(ACLocalPhoto *)photo
     albumname:(NSString *)albumname
      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
       success:(void (^)(ACLocalPhoto *))success
       failure:(void (^)(NSError *error))failure;
//startBlock:(void (^)(ACPhoto *))start
//        endBlock:(void (^)(ACPhoto *))end;

//- (void)sendToS3:(UIImage *)image
//        metadata:(NSString *)metadata
//        filename:(NSString *)filename
//       albumname:(NSString *)albumname
//           photo:(ACPhoto *)photo
//      startBlock:(void (^)(ACPhoto *))start
//        endBlock:(void (^)(ACPhoto *))end;

//@property (nonatomic, assign) UploadStatus uploadStatus;

@property (nonatomic, retain) NSMutableDictionary *pendingUploads;

@end
