//
//  ACLocalPhotoManager.m
//  AllieCam
//
//  Created by Mark Blackwell on 2/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import "ACLocalPhotoManager.h"
#import "ACLocalAlbum.h"
#import "ACPhotoManager.h"

@interface ACLocalPhotoManager ()

@property(nonatomic,retain) NSMutableArray *albums;

@end

@implementation ACLocalPhotoManager

#if DEBUG
#define kUploadFileName @"uploaded_urls_debug.strings"
#else
#define kUploadFileName @"uploaded_urls.strings"
#endif

static ACLocalPhotoManager *_sharedInstance;

- (id)init {
    if (self = [super init]) {
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
+ (ACLocalPhotoManager *)sharedInstance {
    if (!_sharedInstance) {
        _sharedInstance = [[ACLocalPhotoManager alloc] init];
    }
    
    return _sharedInstance;
}

- (void)initializeWithCallback:(void (^)(NSArray *albums))done {
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
    
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            DLog(@"found album: %@", group);
            ACLocalAlbum *album = [[ACLocalAlbum alloc] init];
            album.assetGroup = group;
            album.manager = self;
            [_albums addObject:album];
            [self initializePhotosForAlbum:album];
            [album release];
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

- (void)initializePhotosForAlbum:(ACLocalAlbum *)album {
    DLog(@"Emptying existing photos object");
    
    ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if (result) {
            DLog(@"found image");
            [self addImage:result atURL:[[result defaultRepresentation] url] toAlbum:album];
        }
    };
    
    [album.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    DLog(@"enumerateAssetsUsingBlock...");
    [album.assetGroup enumerateAssetsUsingBlock:assetsEnumerationBlock];
    
    
    //TODO: put in a call to the AppDelegate to handle any outstanding uploads...
    
}

- (id<ACAlbum>)albumAtIndex:(NSInteger)index {
    return [_albums objectAtIndex:index];
}
- (NSInteger)numberOfAlbums {
    return _albums.count;
}
- (NSInteger)maxAlbumIndex {
    return _albums.count - 1;
}
- (NSArray *)albums {
    return _albums;
}
- (ACLocalPhoto *)photoAtURL:(NSString *)url {
    for (ACLocalAlbum *album in _albums) {
        ACLocalPhoto *photo = [album photoAtURL:url];
        if (photo)
            return photo;
    }
    
    return nil;
}

- (void)addImage:(ALAsset *)photo atURL:(NSURL *)url toAlbum:(ACLocalAlbum *)album {
    ACLocalPhoto *acp = [[ACLocalPhoto alloc] initWithURL:url];
    [acp setAsset:photo];
    [acp setParent:album];
    
    NSString *uploadDetails = @"";
    if ((uploadDetails = (NSString *)[_uploadedImages objectForKey:url.description])) {
        NSArray *parts = [uploadDetails componentsSeparatedByString:@","];
        if ([parts count] >= 3)
            acp.rawUploadStatus = [[parts objectAtIndex:2] intValue];
    }
    
    [album addPhoto:acp];
    [acp release];
}



- (void)releaseImages {
    DLog(@"releasing all images");
    for (ACLocalAlbum *album in _albums)
         [album releaseImages];
}

- (void)setUploadStatus:(UploadStatus)status forImage:(ACLocalPhoto *)photo {
    DLog(@"uploading image status for %@ to %d", photo.URL, status);
    photo.rawUploadStatus = status;
    // can't just adjust the photo object because the collection may have changed
    ACLocalPhoto *samePhoto = [self photoAtURL:photo.URL.description];
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
    [_assetsLibrary release];
    [_albums release];
    
    [super dealloc];
}


@end
