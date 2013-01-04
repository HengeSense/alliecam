//
//  ACLocalPhotoSource.h
//  AllieCam2
//
//  Created by Mark Blackwell on 24/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Three20/Three20.h"
#import "ACPhotoSource.h"

@interface ACLocalPhotoSource : NSObject <ACPhotoSource>

@property (nonatomic, copy) NSString* title;
@property (nonatomic, readonly) NSInteger numberOfPhotos;
@property (nonatomic, readonly) NSInteger maxPhotoIndex;
- (id<TTPhoto>)photoAtIndex:(NSInteger)index;

- (NSMutableArray*)delegates;
- (BOOL)isLoaded;
- (BOOL)isLoading;
- (BOOL)isLoadingMore;
-(BOOL)isOutdated;
- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more;
- (void)cancel;
- (void)invalidate:(BOOL)erase;

@end
