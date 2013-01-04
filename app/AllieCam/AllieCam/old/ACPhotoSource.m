//
//  ACPhotoSource.m
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACPhotoSource.h"
#import "AllieCam.h"
//@interface ACPhotoSource ()
//
//@property(nonatomic, retain) NSMutableArray *photos;
//
//@end

@implementation ACPhotoSource

#if DEBUG
    #define kUploadFileName @"uploaded_urls_debug.strings"
#else
    #define kUploadFileName @"uploaded_urls.strings"
#endif

static ACPhotoSource *_sharedInstance;


//@synthesize photos = _photos, numberOfPhotos;

- (id)init {
    if (self = [super init]) {
//        [self preparePhotos];
//        self.assets = [NSMutableArray arrayWithCapacity:1024];
        
        
        NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *fullpath = [NSString stringWithFormat:@"%@/%@", docsPath, kUploadFileName];
        DLog(@"reading uploaded images from %@", fullpath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullpath])
            _uploadedImages = [[NSMutableDictionary dictionaryWithContentsOfFile:fullpath] retain];
        else
            _uploadedImages = [[NSMutableDictionary alloc] init];
        _uploadFilesChanged = NO;
    }
    
    return self;
}

// want every thread to be working with the same instance, because it is written to file
+ (ACPhotoSource *)sharedInstance {
    if (!_sharedInstance) {
        _sharedInstance = [[ACPhotoSource alloc] init];
    }
    
    return _sharedInstance;
}

- (void)initializeAlbumsWithCallback:(void (^)(NSArray *albums))done {
    DLog(@"initializing ACPhotoSource albums");
    if (_assetsLibrary) {
        DLog(@"releasing existing library");
        [_assetsLibrary release];
    }
    
    DLog(@"allocating ALAssetsLibrary");
    _assetsLibrary = [[ALAssetsLibrary alloc] init];
    if (!_albums)
        _albums = [[NSMutableArray alloc] init];
    
    DLog(@"Emptying existing albums object");
    [_albums removeAllObjects];
    // info in the photos will be invalidated anyway, so...
    DLog(@"Emptying existing photos object");
    [_photos removeAllObjects];
    
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            DLog(@"found album: %@", group);
            [_albums addObject:group];
        } else {
            done(_albums);
        }
    };
    
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        DLog(@"failed with error: %@", error);
    };
    
    DLog(@"enumerateGroupsWithTypes call");
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll
                                  usingBlock:listGroupBlock
                                failureBlock:failureBlock];
}

- (void)initializePhotosForAlbum:(ALAssetsGroup *)album {
    if (!_photos)
        _photos = [[NSMutableArray alloc] init];
    
    DLog(@"Emptying existing photos object");
    [_photos removeAllObjects];
    
    ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if (result) {
            DLog(@"found image");
            [self addImage:result atURL:[[result defaultRepresentation] url]];
        }
    };
    
    [album setAssetsFilter:[ALAssetsFilter allPhotos]];
    DLog(@"enumerateAssetsUsingBlock...");
    [album enumerateAssetsUsingBlock:assetsEnumerationBlock];


    //TODO: put in a call to the AppDelegate to handle any outstanding uploads...
    
}


- (id)photoAtIndex:(NSInteger)index {
    DLog(@"getting photo at index=%d", index);
    return [_photos objectAtIndex:index];
}

- (ACPhoto *)photoAtURL:(NSString *)url {
    if (!_photos)
        return nil;
    
    for (ACPhoto *photo in _photos) {
        if ([photo.URL.description isEqualToString:url])
            return photo;
    }
    
    return nil;
}

- (void)addImage:(ALAsset *)photo atURL:(NSURL *)url {
    ACPhoto *acp = [[ACPhoto alloc] initWithURL:url];
    [acp setAsset:photo];
    [acp setParent:self];
    
    NSString *uploadDetails = @"";
    if ((uploadDetails = (NSString *)[_uploadedImages objectForKey:url.description])) {
        acp.uploaded = YES;
        NSArray *parts = [uploadDetails componentsSeparatedByString:@","];
        if ([parts count] >= 3)
            acp.rawUploadStatus = [[parts objectAtIndex:2] intValue];
    }
    
    [_photos addObject:acp];
    [acp release];
}

- (NSInteger)numberOfPhotos {
    return _photos.count;
}

- (void)releaseImagesAroundIndex:(NSUInteger)index except:(NSUInteger)bounds {
    DLog(@"releaseImagesAroundIndex called with index=%d and bounds=%d", index, bounds);
    NSUInteger upperBound = MIN(index + ceil(bounds / 2), _photos.count);
    NSUInteger lowerBound = MAX(index - floor(bounds / 2), 0);
    
    DLog(@"there are currently %d images", _photos.count);
#ifdef DEBUG
    NSUInteger imageCount = 0, assetCount = 0;
    for (ACPhoto *photo in _photos) {
        imageCount += (photo.image != nil ? 1 : 0);
        assetCount += (photo.asset != nil ? 1 : 0);
    }
    DLog(@"there are currently %d underlying UIImages and %d underlying ALAssets", imageCount, assetCount);
#endif
    DLog(@"releasing images around %d to %d", lowerBound, upperBound);
    NSUInteger curr = 0;
    for (ACPhoto *photo in _photos) {
        if (curr < lowerBound || curr >= upperBound) {
            if (photo.image) {
                DLog(@"setting image %d to nil", curr);
                [photo setImage:nil];
            }
//            if (photo.asset) {
//                DLog(@"setting asset %d to nil", curr);
//                [photo setAsset:nil];
//            }
        }
        curr += 1;
    }
    
#ifdef DEBUG
    imageCount = 0;
    assetCount = 0;
    for (ACPhoto *photo in _photos) {
        imageCount += (photo.image != nil ? 1 : 0);
        assetCount += (photo.asset != nil ? 1 : 0);
    }
    DLog(@"there are currently %d underlying UIImages and %d underlying ALAssets", imageCount, assetCount);
#endif
    
        
}

- (void)setImageIsUploaded:(ACPhoto *)photo {
    [_uploadedImages setObject:photo.description forKey:photo.URL.description];
    _uploadFilesChanged = YES;

    // can't just adjust the photo object because the collection may have changed
    ACPhoto *samePhoto = [self photoAtURL:photo.URL.description];
    if (samePhoto)
        samePhoto.uploaded = YES;
}

- (void)setUploadStatus:(UploadStatus)status forImage:(ACPhoto *)photo {
    DLog(@"uploading image status for %@ to %d", photo.URL, status);
    photo.rawUploadStatus = status;
    // can't just adjust the photo object because the collection may have changed
    ACPhoto *samePhoto = [self photoAtURL:photo.URL.description];
    if (samePhoto) {
        DLog(@"found same photo in this collection");
        samePhoto.rawUploadStatus = status;
    }
    else {
        DLog(@"looking for photo in uploaded images");
        NSString *uploadDetails = nil, *newUploadDetails = nil;
        if ((uploadDetails = (NSString *)[_uploadedImages objectForKey:photo.URL.description])) {
            DLog(@"found it, changing status");
            NSArray *parts = [uploadDetails componentsSeparatedByString:@","];
            if ([parts count] >= 3) {
                newUploadDetails = [NSString stringWithFormat:@"%@,%@,%d", parts[0], parts[1], status];
            }
        }
        if (!newUploadDetails) {
            DLog(@"photo was not already in the uploaded images.  will add.");
            newUploadDetails = [photo description];
        }
        [_uploadedImages setObject:newUploadDetails forKey:photo.URL.description];
    }
    _uploadFilesChanged = YES;
}

- (void)writeUploadedImagesToFile {
    if (_uploadFilesChanged) {
        NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *fullpath = [NSString stringWithFormat:@"%@/%@", docsPath, kUploadFileName];
        DLog(@"writing uploaded images to %@", fullpath);
        BOOL written = [_uploadedImages writeToFile:fullpath atomically:YES];
        _uploadFilesChanged = !(written == YES);
        if (!written)
            DLog(@"failed to write uploaded images file");
    }
    else {
        DLog(@"no changes, not writing");
    }
}

- (void)dealloc {
    [_uploadedImages release];
    [_photos release];
    [_assetsLibrary release];
    [_albums release];
    
    [super dealloc];
}


@end
