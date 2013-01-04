//
//  ACAlliecamPhoto.h
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ACPhoto.h"


@interface ACAlliecamPhoto : NSObject <ACPhoto>

- (id)initWithURL:(NSURL *)url;

//@property (nonatomic, retain) ALAsset *asset;
@property (nonatomic,assign) id parent;
@property (nonatomic,copy) NSDate *dateTaken;
@property (nonatomic,copy) NSString *uniqid;
@property (nonatomic,retain) NSURL *fullsizeURL;
@property (nonatomic,retain) NSURL *thumbnailURL;

// automatic property synthesis does not work for properties declared in protocols

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

/*
 * Returns true if the image failed to load.
 */
@property(nonatomic,assign,getter=didFail) BOOL failed;

@end
