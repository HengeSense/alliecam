//
//  ACPhoto.m
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACLocalPhoto.h"
#import "AllieCam.h"
#import "ACPhoto.h"

@interface ACLocalPhoto ()

@property(nonatomic, retain) NSURL *URL;
@property(nonatomic, retain) NSString *caption;

@end

@implementation ACLocalPhoto

- (id)initWithURL:(NSURL *)url {
	
	if (self = [super init]) {
		_URL = [url retain];
        _dateTaken = [[NSDate date] retain];
        _rawUploadStatus = UploadStatusNone;
    }
    
	return self;	
}

// do this lazily, memory problems otherwise
- (UIImage *)image {
    if (_image) {
        return _image;
    }
    
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
- (NSString *)caption {
    return self.isUploaded ? [NSString stringWithFormat:@"Uploaded to %@", [self defaultAlbumName]] : @"";
}

- (UIImage *)thumbnail {
    CGImageRef thumbnailImageRef = [_asset thumbnail];
    return [UIImage imageWithCGImage:thumbnailImageRef];
}

- (NSString *)uploadStatus {
    switch (_rawUploadStatus) {
        case UploadStatusNone:
            return @"";
        case UploadStatusPreDispatch:
        case UploadStatusWaitingForSemaphore:
        case UploadStatusStarting:
        case UploadStatusSendingToAlliecam:
        case UploadStatusSendingToS3:
        case UploadStatusEnding:
#ifdef DEBUG
        return [NSString stringWithFormat:@"Uploading to '%@' (%d of %d)", [self defaultAlbumName], _rawUploadStatus, UploadStatusFinished];
#else
        return [NSString stringWithFormat:@"Uploading to '%@'", [self defaultAlbumName]];
#endif
        case UploadStatusFinished:
            return [NSString stringWithFormat:@"Uploaded to '%@'", [self defaultAlbumName]];
        default:
            DLog(@"unknown status: %d", _rawUploadStatus);
            break;
    }
    
    return @"Unknown";
 
}

- (BOOL)isUploaded {
    return _rawUploadStatus == UploadStatusFinished;
}



@end
