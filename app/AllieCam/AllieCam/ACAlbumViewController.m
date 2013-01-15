//
//  ACMasterViewController.m
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "ACAlbumViewController.h"
#import "ACAlbum.h"
#import "ACPhotoManager.h"
#import "ACPhoto.h"
#import "ACLocalPhoto.h"
#import "AlbumContentsTableViewCell.h"
#import "AllieCam.h"


@interface ACAlbumViewController () {
    NSMutableArray *_objects;
}
@end

@implementation ACAlbumViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.tableView.rowHeight = 78;
    }
    return self;
}

- (id)initWithAlbum:(id<ACAlbum>)album {
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        self.album = album;
    }
    
    return self;
}

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        self.title = @"Camera Roll";
//    }
//    return self;
//}

- (void)dealloc
{
    [_tmpCell release];
    [super dealloc];
}

- (void)awakeFromNib {
    lastSelectedRow = NSNotFound;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    DLog(@"ACMasterViewController viewDidLoad");
    
	[self.tableView setSeparatorColor:[UIColor clearColor]];
	[self.tableView setAllowsSelection:NO];
    
    self.navigationController.toolbarHidden = NO;
    self.navigationController.navigationBar.tintColor = nil;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;
    
    self.navigationController.toolbar.tintColor = nil;
    self.navigationController.toolbar.barStyle = UIBarStyleBlack;
    self.navigationController.toolbar.translucent = YES;
    
    
    // doesn't work with awakeFromNib...
    lastSelectedRow = NSNotFound;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = _album.name;
    
    [self.navigationController setToolbarHidden:YES];
    
    NSInteger startPageIx = 0; //[[ACPhotoSource sharedInstance] numberOfPhotos] - 1;
    EGOPhotoViewController *pvc = [[[EGOPhotoViewController alloc]
                                    initWithPhotoSource:_album
                                    atIndex:startPageIx] autorelease];
    self.photoController = pvc;
    
    
    // may need to reload overlay...
    [self.tableView reloadData];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (lastSelectedRow != NSNotFound) {
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:lastSelectedRow inSection:0];
        AlbumContentsTableViewCell *selectedCell = (AlbumContentsTableViewCell *)[(UITableView *)self.view cellForRowAtIndexPath:selectedIndexPath];
        [selectedCell clearSelection];
        
        lastSelectedRow = NSNotFound;
    }
    else if (self.tableView.contentSize.height > self.tableView.frame.size.height)
    {
        // scroll to end
        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height -
                                     self.tableView.frame.size.height);
        [self.tableView setContentOffset:offset animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setToolbarHidden:NO];
}


//- (void)cameraButtonTapped:(id)sender {
//    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//        [self.navigationController pushViewController:_photoController animated:NO];
//        [_photoController launchCamera];
//    }
//    else {
//        DLog(@"camera not available on this device");
//    }
//    
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    DLog(@"ACMasterViewController did receive memory warning");
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ceil([_album numberOfPhotos] / 4.0);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    AlbumContentsTableViewCell *cell = (AlbumContentsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"AlbumContentsTableViewCell" owner:self options:nil];
        cell = _tmpCell;
        _tmpCell = nil;
    }
    
    cell.rowNumber = indexPath.row;
    cell.selectionDelegate = self;
    
    // Configure the cell...
    NSUInteger firstPhotoInCell = indexPath.row * 4;
    NSUInteger lastPhotoInCell  = firstPhotoInCell + 4;
    
    if ([_album numberOfPhotos] <= firstPhotoInCell) {
        DLog(@"We are out of range, asking to start with photo %d but we only have %d", firstPhotoInCell, [_album numberOfPhotos]);
        return nil;
    }
    
    NSUInteger currentPhotoIndex = 0;
    NSUInteger lastPhotoIndex = MIN(lastPhotoInCell, [_album numberOfPhotos]);
    for ( ; firstPhotoInCell + currentPhotoIndex < lastPhotoIndex ; currentPhotoIndex++) {
        
        ThumbnailImageView *tiv = nil;
        switch (currentPhotoIndex) {
            case 0:
                tiv = cell.photo1;
                break;
            case 1:
                tiv = cell.photo2;
                break;
            case 2:
                tiv = cell.photo3;
                break;
            case 3:
                tiv = cell.photo4;
                break;
            default:
                break;
        }
        
        id<ACPhoto> photo = [_album photoAtIndex:firstPhotoInCell + currentPhotoIndex];
        if (photo.thumbnail) {
            tiv.image = photo.thumbnail;
        }
        else {
            DLog(@"using placeholder for image at %@", photo.URL.absoluteString);
            tiv.image = [UIImage imageNamed:@"Placeholder.png"];
            if (_album.manager) {
                [_album.manager loadThumbnail:photo success:^(UIImage *thumbnail) {
                    DLog(@"loaded image for photo at %@", photo.URL.absoluteString);
                    tiv.image = thumbnail;
                }];
            }
            else {
                DLog(@"cannot load thumbnail at %@ without manager set", photo.URL.relativeString);
            }
            
        }
        
        if ([photo isKindOfClass:[ACLocalPhoto class]]) {
            ACLocalPhoto *localPhoto = (ACLocalPhoto *)photo;
            if ([localPhoto isUploaded])
                [tiv applyUploadedOverlay];
//            if ([localPhoto.asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo)
//                [tiv applyMovieOverlay];
        }
        
    }
    
    return cell;
}

#pragma mark -
#pragma mark AlbumContentsTableViewCellSelectionDelegate

- (void)albumContentsTableViewCell:(AlbumContentsTableViewCell *)cell selectedPhotoAtIndex:(NSUInteger)index {
    lastSelectedRow = cell.rowNumber;
    NSUInteger picIndex = (cell.rowNumber * 4) + index;
    DLog(@"navigating to image at index=%d", picIndex);
    
//    id photo = [_album photoAtIndex:picIndex];
//    if ([photo isKindOfClass:[ACLocalPhoto class]] &&
//        [[photo asset] valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
//        MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:[photo URL]];
//        [self.navigationController pushViewController:player animated:YES];
//    }
//    else {
        [_photoController presetPhotoIndex:picIndex];
        [self.navigationController pushViewController:_photoController animated:YES];
//    }
    
    // this must be after the nav controller has been pushed, o/w EGOPhotoViewController
    // breaks (can probably fix if need to... problem is in the centerPhotoIndex method,
    // which needs the width of the scrolling frame to work)
//    [_photoController moveToPhotoAtIndex:picIndex animated:NO];
}


//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//	return 79;
//}


- (void)viewDidUnload {
    DLog(@"ACMasterViewController viewDidUnload");
    [self setTmpCell:nil];
    [super viewDidUnload];
}
@end
