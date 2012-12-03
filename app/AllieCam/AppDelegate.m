/*
     File: AppDelegate.m 
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

#import "AppDelegate.h"

@implementation AppDelegate;

@synthesize window, navController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    // create window and set up table view controller
//	[window addSubview:navController.view];
    [self.window setRootViewController:navController];
	[self.window makeKeyAndVisible];
    
    // Initial the S3 Client.
    self.s3 = [[[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY] autorelease];
#ifdef DEBUG
    S3Bucket *bucket = [[self.s3 listBuckets] objectAtIndex:0];
    NSLog(@"%@",[bucket name]);
#endif

    // Create the picture bucket.
//    NSString *pictureBucket = [[NSString stringWithFormat:@"%@-%@%@", UNIQUE_NAME, ACCESS_KEY_ID, PICTURE_BUCKET] lowercaseString];
//    NSString *pictureBucket = @"blackwellfamily";
//    S3CreateBucketRequest *createBucketRequest = [[[S3CreateBucketRequest alloc] initWithName:pictureBucket] autorelease];
//    S3CreateBucketResponse *createBucketResponse = [self.s3 createBucket:createBucketRequest];
//    if(createBucketResponse.error != nil)
//    {
//        NSLog(@"Error: %@", createBucketResponse.error);
//    }
    
    // Logging Control - Do NOT use logging for non-development builds.
#ifdef DEBUG
    [AmazonLogger verboseLogging];
#else
    [AmazonLogger turnLoggingOff];
#endif
    
    [AmazonErrorHandler shouldNotThrowExceptions];
}

- (void)beginBackgroundUpdateTask {
    uploadTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
}
- (void)endBackgroundUpdateTask {
    [[UIApplication sharedApplication] endBackgroundTask:uploadTaskID];
    uploadTaskID = UIBackgroundTaskInvalid;
}

- (void)sendToS3:(NSDictionary *)info
      startBlock:(void (^)(NSString *filename))start
        endBlock:(void (^)(void))end {
    
    // apparently this gives me ten minutes after app has ended to upload?
    // probably need to handle better than this though
    // with some sort of disk storage of images that didn't upload
    // (or a reference to the image in the library)
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self beginBackgroundUpdateTask];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMddHHmm"];
        NSDate *now = [NSDate date];
        NSString *filename = [formatter stringFromDate:now];
        [formatter setDateFormat:@"MMM-yyyy"];
        NSString *albumname = [formatter stringFromDate:now];
        NSString *fullpath = [NSString stringWithFormat:@"%@/%@", albumname, filename];
        
        start([NSString stringWithFormat:@"Uploading to album '%@'", albumname]);
        
        UIImage *picture = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSLog(@"Fixing picture orientation");
        UIImage *corrected_pic = [picture fixOrientation];
        NSLog(@"Compressing to JPEG");
        NSData *imageData = UIImageJPEGRepresentation(corrected_pic, 1.0);
        
        // Upload image data.  Remember to set the content type.
        NSLog(@"Uploading to '%@' with filename '%@'", PICTURE_BUCKET, fullpath);
        S3PutObjectRequest *por = [[[S3PutObjectRequest alloc] initWithKey:filename
                                                                  inBucket:PICTURE_BUCKET] autorelease];
        
        por.contentType = @"image/jpeg";
        por.data = imageData;
        
        // doco seems to indicate that if i DON'T set a delegate, the request will be syncronous
    //    por.delegate = self;

        // Put the image data into the specified s3 bucket and object.
        S3PutObjectResponse *response = [self.s3 putObject:por];
        NSLog(@"Finished upload: %@", response);
        
        // now let alliecam.net know about the upload
       
        NSString *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
        if (!metadata)
            metadata = @"";
        NSString *post = [NSString stringWithFormat:@"filename=%@&album=%@&metadata=%@", fullpath, albumname, metadata];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        
        NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
        
        NSURL *url = [NSURL URLWithString:UPLOAD_URL];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
        
        NSURLResponse *ac_response = nil;
        NSError *ac_error = nil;
        NSData *ac_responseData = [NSURLConnection sendSynchronousRequest:request
                                                        returningResponse:&ac_response
                                                                    error:&ac_error];
        NSLog(@"Finished comms with alliecam.net");
        NSLog(@"Response: %@", ac_response);
        NSLog(@"Error: %@", ac_error);
        NSLog(@"Response data: %@", ac_responseData);
        
        end();
        
        [self endBackgroundUpdateTask];
        
    });

    
}


-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    NSLog(@"SUCCESS: Finished uploading file to S3");
    
    UIApplication *app = [UIApplication sharedApplication];
//    if (uploadTaskID != UIBackgroundTaskInvalid) {
//        [app endBackgroundTask:uploadTaskID];
//        uploadTaskID = UIBackgroundTaskInvalid;
//    }
    
    [app setNetworkActivityIndicatorVisible:NO];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);

    UIApplication *app = [UIApplication sharedApplication];
//    if (uploadTaskID != UIBackgroundTaskInvalid) {
//        [app endBackgroundTask:uploadTaskID];
//        uploadTaskID = UIBackgroundTaskInvalid;
//    }
    
    [app setNetworkActivityIndicatorVisible:NO];
}

- (void)dealloc
{
	[navController release];
    [window release];
    [self.s3 release];
	
    [super dealloc];
}

@end
