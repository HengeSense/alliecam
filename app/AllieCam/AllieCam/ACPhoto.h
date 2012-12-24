//
//  ACPhoto.h
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "EGOPhotoSource.h"

typedef NS_ENUM(NSInteger, UploadStatus) {
    UploadStatusNone,
    UploadStatusPreDispatch,
    UploadStatusWaitingForSemaphore,
    UploadStatusStarting,
    UploadStatusSendingToS3,
    UploadStatusSendingToAlliecam,
    UploadStatusEnding,
    UploadStatusFinished
};


@interface ACPhoto : NSObject <EGOPhoto> {
    UIImage *_image;
    ALAsset *_asset;
}

//@property (nonatomic, retain) ALAsset *asset;
@property (nonatomic, assign) id parent;
@property (getter=isUploaded) BOOL uploaded;
@property (nonatomic, assign) UploadStatus rawUploadStatus;
@property (nonatomic, retain, readonly) NSString *uploadStatus;
@property (nonatomic, retain) NSDate* dateTaken;

//- (id)initWithAsset:(ALAsset*)_anAsset;
- (id)initWithURL:(NSURL *)url;



/*
 * URL of the image, varied URL size should set according to display size.
 */
@property(nonatomic,readonly,retain) NSURL *URL;

/*
 * The caption of the image.
 */
@property(nonatomic,readonly,retain) NSString *caption;

/*
 * Size of the image, CGRectZero if image is nil.
 */
@property(nonatomic) CGSize size;

/*
 * The image after being loaded, or local.
 */
@property(nonatomic,retain) UIImage *image;
@property(nonatomic,retain) ALAsset *asset;

/*
 * Returns true if the image failed to load.
 */
@property(nonatomic,assign,getter=didFail) BOOL failed;


- (NSDate *)dateTaken;
- (NSString *)defaultAlbumName;


@end
