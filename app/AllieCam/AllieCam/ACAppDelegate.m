//
//  ACAppDelegate.m
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACAppDelegate.h"
#import "ACRootViewController.h"
#import "AllieCam.h"
#import "ACLocalPhotoManager.h"


@implementation ACAppDelegate


- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    DLog(@"window frame is %@", NSStringFromCGRect(self.window.frame));
    // Override point for customization after application launch.

    ACRootViewController *rvc = [[[ACRootViewController alloc] init] autorelease];
    DLog(@"rvc frame 1 is %@", NSStringFromCGRect(rvc.view.frame));
    
    self.window.rootViewController = rvc;
    [self.window makeKeyAndVisible];
    
    
    // Initial the S3 Client.
#ifdef USE_AWS_OFFICIAL_CLIENT
    self.s3 = [[[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY] autorelease];
    // Logging Control - Do NOT use logging for non-development builds.
#ifdef DEBUG
    [AmazonLogger verboseLogging];
#else
    [AmazonLogger turnLoggingOff];
#endif
    
    [AmazonErrorHandler shouldNotThrowExceptions];
#else
    self.s3 = [[AFAmazonS3Client alloc] initWithAccessKeyID:ACCESS_KEY_ID secret:SECRET_KEY];
    
#endif
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    DLog(@"application entered background with %f seconds remaining", [[UIApplication sharedApplication] backgroundTimeRemaining]);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *fullpath = [NSString stringWithFormat:@"%@/%@", docsPath, kPendingUploadsFile];
    DLog(@"checking for pending uploads in %@", fullpath);
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullpath]) {
        _pendingUploads = [[NSMutableDictionary dictionaryWithContentsOfFile:fullpath] retain];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSTimeInterval timeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];

    if (!_pendingUploads)
        DLog(@"terminating, but pending uploads var has been deallocated");
    
    DLog(@"terminating with %d items and %f seconds remaining", _pendingUploads.count, timeRemaining);
    
}

- (void)beginBackgroundUpdateTask {
    DLog(@"beginning background task");
    [self setNetworkActivityIndicatorVisible:YES];
    self.uploadTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
}
- (void)endBackgroundUpdateTask {
    NSTimeInterval timeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
    if (!_pendingUploads)
        DLog(@"pending uploads var has been deallocated");
    
    DLog(@"ending background task with %d items and %f seconds remaining", _pendingUploads.count, timeRemaining);
    if (_pendingUploads.count > 0) {
        NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *fullpath = [NSString stringWithFormat:@"%@/%@", docsPath, kPendingUploadsFile];
        DLog(@"writing pending uploads to %@", fullpath);
        BOOL written = [_pendingUploads writeToFile:fullpath atomically:YES];
        if (!written)
            DLog(@"failed to write uploaded images file");
    }
    else {
        DLog(@"no pending uploads");
    }
    
    [[UIApplication sharedApplication] endBackgroundTask:self.uploadTaskID];
    self.uploadTaskID = UIBackgroundTaskInvalid;
    [self setNetworkActivityIndicatorVisible:NO];
}

- (void)upload:(ACLocalPhoto *)photo
     albumname:(NSString *)albumname
      progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
       success:(void (^)(ACLocalPhoto *))success
       failure:(void (^)(NSError *error))failure {
    
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSDate *now = [NSDate date];
    int r = rand() % 100;
    NSString *filename = [NSString stringWithFormat:@"%@-%d.jpg", [formatter stringFromDate:now], r];
    
    DLog(@"Getting image properties");
    CLLocation *locn = [photo.asset valueForProperty:ALAssetPropertyLocation];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateTakenStr = [formatter stringFromDate:photo.dateTaken];
    NSString *metadata = [NSString stringWithFormat:
                          @"{ \"dateCreated\": \"%@\", \"geolocation\": \"<%f,%f>\" }",
                          dateTakenStr, locn.coordinate.latitude, locn.coordinate.longitude];
    
    // apparently this gives me ten minutes after app has ended to upload
    // so store the reference for later if necessary...
    NSMutableDictionary *upload = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   metadata, kPendingUploadMetadataKey,
                                   filename, kPendingUploadFilenameKey,
                                   albumname, kPendingUploadAlbumnameKey,
                                   [NSNumber numberWithInt:UploadStatusNone], kPendingUploadUploadStatusKey,
                                   nil];
    if (!_pendingUploads)
        self.pendingUploads = [[[NSMutableDictionary alloc] init] autorelease];
    
    [_pendingUploads setObject:upload forKey:photo.URL.description];
    
    // TODO: may need to dispatch_release this semaphore
    if (!_uploadSemaphore)
        _uploadSemaphore = dispatch_semaphore_create(kMaxConcurrentUploads);
        
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self setStatus:UploadStatusWaitingForSemaphore forImage:photo];
        dispatch_semaphore_wait(_uploadSemaphore, DISPATCH_TIME_FOREVER);
        
        [self setStatus:UploadStatusStarting forImage:photo];
        [self beginBackgroundUpdateTask];
        
        
        DLog(@"Sending %@/%@ to Amazon S3", albumname, filename);
        [self setStatus:UploadStatusSendingToS3 forImage:photo];
        [self sendToS3:photo
             albumname:albumname
              filename:filename
              progress:progress
               success:^(id responseObject) {
                   [self setStatus:UploadStatusSendingToAlliecam forImage:photo];
                   // now let alliecam.net know about the upload
                   // HACK: assume this works
                   [self sendToAlliecam:photo albumname:albumname filename:filename metadata:metadata];
                   
                   [self setStatus:UploadStatusEnding forImage:photo];
                   DLog(@"removing object from pending uploads");
                   [_pendingUploads removeObjectForKey:photo];
                   
                   if (success)
                       success(photo);
                   [self setStatus:UploadStatusFinished forImage:photo];
                   
                   [self endBackgroundUpdateTask];
                   dispatch_semaphore_signal(_uploadSemaphore);
               }
               failure:^(NSError *error) {
                   if (failure)
                       failure(error);
                   [self endBackgroundUpdateTask];
                   dispatch_semaphore_signal(_uploadSemaphore);
               }];
    });
    
}

- (void)sendToS3:(ACLocalPhoto *)photo
       albumname:(NSString *)albumname
        filename:(NSString *)filename
        progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
         success:(void (^)(id responseObject))success
         failure:(void (^)(NSError *error))failure {
    // Upload image data.  Remember to set the content type.
    NSString *fullpath = [NSString stringWithFormat:@"%@/%@", albumname, filename];
    
#ifndef DO_AWS_UPLOAD
    DLog(@"DEBUG... NOT Uploading to '%@' with filename '%@'", PICTURE_BUCKET, fullpath);
    [NSThread sleepForTimeInterval:5.0];
    if (success)
        success(nil);
#else
    DLog(@"creating UIImage...");
    ALAssetRepresentation *rep = [photo.asset defaultRepresentation];
    UIImage *picture = [[UIImage alloc] initWithCGImage:[rep fullResolutionImage]
                                         scale:[rep scale]
                                   orientation:[rep orientation]];
    DLog(@"Fixing picture orientation");
    UIImage *corrected_pic = [picture fixOrientation];

    DLog(@"Compressing to JPEG");
    NSData *imageData = UIImageJPEGRepresentation(corrected_pic, 1.0);
    [picture release];
    
    DLog(@"Uploading to '%@' with filename '%@'", PICTURE_BUCKET, fullpath);
#ifdef USE_AWS_OFFICIAL_CLIENT
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:fullpath
                                                             inBucket:PICTURE_BUCKET];
    por.contentType = @"image/jpeg";
    por.data = imageData;
    
    // doco seems to indicate that if i DON'T set a delegate, the request will be syncronous
    //    por.delegate = self;
    
    // Put the image data into the specified s3 bucket and object.
    S3PutObjectResponse *response = [self.s3 putObject:por];
    [por release];
    DLog(@"Finished upload: %@", response);
#else
    _s3.bucket = PICTURE_BUCKET;
    
    [_s3 putObjectNamed:fullpath
                   data:imageData
             parameters:nil
               progress:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
                   DLog(@"%f%% Uploaded", (totalBytesWritten / (totalBytesExpectedToWrite * 1.0f) * 100));
                   progress(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
               } success:^(id responseObject) {
                   DLog(@"Upload Complete");
                   if (success)
                       success(responseObject);
               } failure:^(NSError *error) {
                   DLog(@"Error: %@", error);
                   if (failure)
                       failure(error);
               }];
    DLog(@"finished upload (via AFNetworking");
    
#endif
#endif
}

// don't really need the picture, but sig looks better that way
- (void)sendToAlliecam:(ACLocalPhoto *)photo
             albumname:(NSString *)albumname
              filename:(NSString *)filename
              metadata:(NSString *)metadata {
    
    NSString *post = [NSString stringWithFormat:@"filename=%@&albumname=%@&metadata=%@", filename, albumname, metadata];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSURL *url = [NSURL URLWithString:UPLOAD_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
#ifndef DO_ALLIECAM_UPLOAD
    DLog(@"DEBUG... NOT sending synchronous request: %@", request);
    [NSThread sleepForTimeInterval:2.0];
#else
    NSURLResponse *ac_response = nil;
    NSError *ac_error = nil;
    DLog(@"sending synchronous request: %@", request);
    NSData *ac_responseData = [NSURLConnection sendSynchronousRequest:request
                                                    returningResponse:&ac_response
                                                                error:&ac_error];
    DLog(@"Finished comms with alliecam.net");
    DLog(@"Response: %@", ac_response);
    DLog(@"Error: %@", ac_error);
    DLog(@"Response data: %@", ac_responseData);
#endif
}


- (void)setStatus:(UploadStatus)status forImage:(ACLocalPhoto *)photo {
    [[ACLocalPhotoManager sharedInstance] setUploadStatus:status forImage:photo];
    NSMutableDictionary *upload = [_pendingUploads objectForKey:photo.URL.description];
#ifdef DEBUG
    UploadStatus old_status = [[upload objectForKey:kPendingUploadUploadStatusKey] intValue];
    DLog(@"updating %@ status from %d to %d", photo.URL.description, old_status, status);
#endif
    [upload setObject:[NSNumber numberWithInt:status] forKey:@"uploadStatus"];
}

// from http://oleb.net/blog/2009/09/managing-the-network-activity-indicator/
- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible {
    static NSInteger NumberOfCallsToSetVisible = 0;
    if (setVisible) 
        NumberOfCallsToSetVisible++;
    else 
        NumberOfCallsToSetVisible--;

    // The assertion helps to find programmer errors in activity indicator management.
    // Since a negative NumberOfCallsToSetVisible is not a fatal error, 
    // it should probably be removed from production code.
    NSAssert(NumberOfCallsToSetVisible >= 0, @"Network Activity Indicator was asked to hide more often than shown");
    
    // Display the indicator as long as our static counter is > 0.
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(NumberOfCallsToSetVisible > 0)];
}

- (void)handlePendingUploads {
    DLog(@"handling pending uploads: there are %d to upload", _pendingUploads.count);
    
    ACLocalPhotoManager *photoManager = [ACLocalPhotoManager sharedInstance];
//    if ([photoSource numberOfPhotos] == 0) {
//        DLog(@"No photos in the source.  Ending.");
//        return;
//    }
    
    // using allKeys to enumerate allows me to modify the dictionary
    for (NSString *url in _pendingUploads.allKeys) {
        ACLocalPhoto *photo = [photoManager photoAtURL:url];
        if (!photo) {
            DLog(@"Could not find photo at %@", url);
            continue;
        }
        
        NSMutableDictionary *upload = [_pendingUploads objectForKey:url];
        UploadStatus status = [[upload objectForKey:@"uploadStatus"] intValue];
        DLog(@"found upload with status %d", status);
        switch (status) {
            case UploadStatusNone:
                //fall through
            case UploadStatusPreDispatch:
                //fall through
            case UploadStatusWaitingForSemaphore:
                //fall through
            case UploadStatusStarting:
                //fall through
            case UploadStatusSendingToS3:
                DLog(@"starting again with this upload");
                [photoManager setUploadStatus:status forImage:photo];
                [self upload:photo
                   albumname:[photo defaultAlbumName]
                    progress:nil
                     success:^(ACLocalPhoto *photo) {
                        [photoManager setUploadStatus:UploadStatusFinished forImage:photo];
                     }
                     failure:^(NSError *error) {
                         DLog(@"pending upload to S3 failed: %@", error);
                         // HACK: fail case will fall through to code below
                     }];
                break;
                
            case UploadStatusSendingToAlliecam:
                DLog(@"image appears to be on S3, so just send to alliecam");
                [photoManager setUploadStatus:status forImage:photo];
                // grab these before doing the upload async, because will remove object next
                NSString *albumname = [upload objectForKey:kPendingUploadAlbumnameKey];
                NSString *filename = [upload objectForKey:kPendingUploadFilenameKey];
                NSString *metadata = [upload objectForKey:kPendingUploadMetadataKey];
                [self sendToAlliecam:photo albumname:albumname filename:filename metadata:metadata];
                //fall through
            case UploadStatusEnding:
                DLog(@"image is on servers, just tell the image");
                [photoManager setUploadStatus:UploadStatusFinished forImage:photo];
                [photoManager writeUploadedImagesToFile];
                //fall through
            case UploadStatusFinished:
                DLog(@"image was uploaded!!");
                //fall through
            default:
                DLog(@"unknown status: %d", status);
                break;
        }
        [_pendingUploads removeObjectForKey:url];
    }

}


@end
