//
//  ACPhotoSource.h
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACPhoto.h"
#import "EGOPhotoSource.h"

@interface ACPhotoSource : NSObject <EGOPhotoSource> {
    NSMutableDictionary *_uploadedImages;
    ALAssetsLibrary *_assetsLibrary;
}

+ (ACPhotoSource *)sharedInstance;

/*
 * Array containing photo data objects.
 */
@property(nonatomic, retain) NSArray *albums;
@property(nonatomic,readonly,retain) NSArray *photos;

/*
 * Number of photos.
 */
@property(nonatomic,readonly) NSInteger numberOfPhotos;

/*
 * Should return a photo from the photos array, at the index passed.
 */
- (id)photoAtIndex:(NSInteger)index;
- (ACPhoto *)photoAtURL:(NSString *)url;

//@property(nonatomic, retain) NSMutableArray *assets;

- (void)addImage:(ALAsset *)photo atURL:(NSURL *)url;

- (void)releaseImagesAroundIndex:(NSUInteger)index except:(NSUInteger)bounds;

@property(assign, getter = isUploadFilesChanged) BOOL uploadFilesChanged;

- (void)setImageIsUploaded:(ACPhoto *)photo;
- (void)setUploadStatus:(UploadStatus)status forImage:(ACPhoto *)photo;
- (void)writeUploadedImagesToFile;

- (void)initializeAlbumsWithCallback:(void (^)(NSArray *albums))done;
- (void)initializePhotosForAlbum:(ALAssetsGroup *)album;

@end
