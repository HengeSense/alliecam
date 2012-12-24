//
//  ACMasterViewController.h
//  AllieCam
//
//  Created by Mark Blackwell on 5/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACPhotoSource.h"
#import "EGOPhotoViewController.h"
#import "AlbumContentsTableViewCell.h"

//@class ACDetailViewController;

@interface ACAlbumViewController : UITableViewController <AlbumContentsTableViewCellSelectionDelegate> {
    NSInteger lastSelectedRow;
}

@property (strong, nonatomic) EGOPhotoViewController *photoController;
//@property (nonatomic, retain) ACPhotoSource *photoSource;
@property (nonatomic, retain) ALAssetsGroup *assetsGroup;
@property (nonatomic, assign) IBOutlet AlbumContentsTableViewCell *tmpCell;



@end
