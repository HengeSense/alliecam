//
//  ACLocalPhotoManager.h
//  AllieCam
//
//  Created by Mark Blackwell on 2/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ACLocalPhoto.h"

@protocol ACPhotoManager;
@protocol ACAlbum;

@interface ACLocalPhotoManager : NSObject <ACPhotoManager> {
    BOOL _uploadFilesChanged;
    NSMutableDictionary *_uploadedImages;
    ALAssetsLibrary *_assetsLibrary;
}

+ (ACLocalPhotoManager *)sharedInstance;
- (void)initializeWithCallback:(void (^)(NSArray *albums))done;

- (ACLocalPhoto *)photoAtURL:(NSString *)url;

- (void)releaseImages;
- (void)setUploadStatus:(UploadStatus)status forImage:(ACLocalPhoto *)photo;
- (void)writeUploadedImagesToFile;

@end



