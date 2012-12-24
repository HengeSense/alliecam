//
//  ACPhoto.m
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACPhoto.h"
#import "AllieCam.h"

@implementation ACPhoto

- (id)initWithURL:(NSURL *)url {
	
	if (self = [super init]) {
		_URL = [url retain];
        _dateTaken = [[NSDate date] retain];
        _uploaded = NO;
        _rawUploadStatus = UploadStatusNone;
    }
    
	return self;	
}

// do this lazily, memory problems otherwise
- (UIImage *)image {
    if (_image) {
        return _image;
    }
    
    // move to EGO image loader library...
    
//    ALAssetsLibrary* assetslibrary = [[[ALAssetsLibrary alloc] init] autorelease];
//    
//    [assetslibrary assetForURL:_URL resultBlock:^(ALAsset *asset) {
//        UIImageOrientation orientation = UIImageOrientationUp;
//        NSNumber* orientationValue = [_asset valueForProperty:@"ALAssetPropertyOrientation"];
//        if (orientationValue != nil) {
//            orientation = [orientationValue intValue];
//        }
//        _image = [[UIImage imageWithCGImage:[[_asset defaultRepresentation] fullResolutionImage]
//                                      scale:1.0
//                                orientation:orientation] retain];
//    } failureBlock:^(NSError *error) {
//        DLog(@"error couldn't get photo");
//        
//    }];
    
    return nil;
}

- (void)setImage:(UIImage *)anImage {
    if (_image != anImage)
    {
        [_image release];
        _image = [anImage retain];
    }
}

- (ALAsset *)asset {
    return _asset;
}
- (void)setAsset:(ALAsset *)anAsset {
    if (_asset != anAsset)
    {
        [_asset release];
        _asset = [anAsset retain];
        
        // collect the date taken immediately, because if the ALAssetLibrary
        // goes away, then can't get date and therefore not description
        if (_asset)
            self.dateTaken = [_asset valueForProperty:ALAssetPropertyDate];
    }
}

- (NSString *)defaultAlbumName {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"MMM-yyyy"];
    return [formatter stringFromDate:_dateTaken];
}

- (NSString *)description {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateTakenStr = [formatter stringFromDate:_dateTaken];
    return [NSString stringWithFormat:@"%@,%@,%d", _URL, dateTakenStr, _rawUploadStatus];
}

- (NSString *)uploadStatus {
    switch (_rawUploadStatus) {
        case UploadStatusNone:
            return @"";
        case UploadStatusPreDispatch:
        case UploadStatusWaitingForSemaphore:
        case UploadStatusStarting:
        case UploadStatusSendingToS3:
        case UploadStatusSendingToAlliecam:
        case UploadStatusEnding:
        return [NSString stringWithFormat:@"Uploading to '%@' (%d of %d)", [self defaultAlbumName], _rawUploadStatus, UploadStatusFinished];
        case UploadStatusFinished:
            return [NSString stringWithFormat:@"Uploaded to '%@'", [self defaultAlbumName]];
        default:
            DLog(@"unknown status: %d", _rawUploadStatus);
            break;
    }
    
    return @"Unknown";
 
}

@end
