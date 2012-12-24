//
//  ACMasterViewController.m
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACAlbumViewController.h"
#import "AlbumContentsTableViewCell.h"
#import "AllieCam.h"


@interface ACAlbumViewController () {
    NSMutableArray *_objects;
}
@end

@implementation ACAlbumViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Camera Roll";
    }
    return self;
}
							
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
    
    NSInteger startPageIx = 0; //[[ACPhotoSource sharedInstance] numberOfPhotos] - 1;
    EGOPhotoViewController *pvc = [[[EGOPhotoViewController alloc]
                                    initWithPhotoSource:[ACPhotoSource sharedInstance]
                                    atIndex:startPageIx] autorelease];
    self.photoController = pvc;
    
    UIBarButtonItem *cameraButton =
        [[UIBarButtonItem alloc] initWithTitle:@"Camera"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(cameraButtonTapped:)];
    
    [self setToolbarItems:[NSArray arrayWithObject:cameraButton]];
    
    [cameraButton release];
    
    // doesn't work with awakeFromNib...
    lastSelectedRow = NSNotFound;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // this may have been altered by photo viewer
    if ([[ACPhotoSource sharedInstance] isUploadFilesChanged])
        [[ACPhotoSource sharedInstance] writeUploadedImagesToFile];
    
    // may want to put this in viewDidLoad ???
    [[ACPhotoSource sharedInstance] initializePhotosForAlbum:_assetsGroup];
    
    self.title = [_assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    
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
    
    if ([[ACPhotoSource sharedInstance] isUploadFilesChanged])
        [[ACPhotoSource sharedInstance] writeUploadedImagesToFile];
}


//- (void) viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//    if (self.tableView.contentSize.height > self.tableView.frame.size.height)
//    {
//        CGPoint offset = CGPointMake(0, self.tableView.contentSize.height -
//                                     self.tableView.frame.size.height);
//        [self.tableView setContentOffset:offset animated:YES];
//    }
//}

- (void)cameraButtonTapped:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [self.navigationController pushViewController:_photoController animated:NO];
        [_photoController launchCamera];
    }
    else {
        DLog(@"camera not available on this device");
    }
    
}

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
    return ceil([[ACPhotoSource sharedInstance] numberOfPhotos] / 4.0);
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
    
    ACPhotoSource *photoSource = [ACPhotoSource sharedInstance];
    if (photoSource.photos.count <= firstPhotoInCell) {
        DLog(@"We are out of range, asking to start with photo %d but we only have %d", firstPhotoInCell, photoSource.photos.count);
        return nil;
    }
    
    NSUInteger currentPhotoIndex = 0;
    NSUInteger lastPhotoIndex = MIN(lastPhotoInCell, photoSource.photos.count);
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
        
        ACPhoto *photo = [photoSource photoAtIndex:firstPhotoInCell + currentPhotoIndex];
        if (photo.asset) {
            CGImageRef thumbnailImageRef = [photo.asset thumbnail];
            UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
            tiv.image = thumbnail;
        }
        
        if (photo.isUploaded)
            [tiv applyUploadedOverlay];
            
    }
    
    return cell;
}

#pragma mark -
#pragma mark AlbumContentsTableViewCellSelectionDelegate

- (void)albumContentsTableViewCell:(AlbumContentsTableViewCell *)cell selectedPhotoAtIndex:(NSUInteger)index {
    lastSelectedRow = cell.rowNumber;
    NSUInteger picIndex = (cell.rowNumber * 4) + index;
    DLog(@"navigating to image at index=%d", picIndex);
    
    [_photoController presetPhotoIndex:picIndex];
    [self.navigationController pushViewController:_photoController animated:YES];
        
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
