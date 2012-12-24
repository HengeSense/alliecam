//
//  RootViewController.m
//  AllieCam
//
//  Created by Mark Blackwell on 7/12/12.
//  Copyright (c) 2012 Mark Blackwell. All rights reserved.
//

#import "ACAlbumViewController.h"
#import "RootViewController.h"
#import "AllieCam.h"

@implementation RootViewController


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    DLog(@"RVC viewDidLoad called");
    
//    if (!_assetsLibrary) {
//        self.assetsLibrary = [[[ALAssetsLibrary alloc] init] autorelease];
//    }
//    if (!_groups) {
//        self.groups = [[[NSMutableArray alloc] init] autorelease];
//    } else {
//        [_groups removeAllObjects];
//    }
//    
//    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
//        
//        if (group) {
//            DLog(@"found album: %@", group);
//            [_groups addObject:group];
//        } else {
//            // this is the main thread...
//            [self.tableView reloadData];
////            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
//        }
//    };
//    
//    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
//        DLog(@"failed with error: %@", error);
//    };
//    
//    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:listGroupBlock failureBlock:failureBlock];
//    
//    _isFirstAppearance = YES;

    [[ACPhotoSource sharedInstance] initializeAlbumsWithCallback:^(NSArray *albums) {
        self.groups = albums;
        [self.tableView reloadData];
    }];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.title = @"Alliecam Albums";
    
    // find the saved photo album and navigate to that
    DLog(@"RVC viewWillAppear with %d groups", [_groups count]);
//    if (_isFirstAppearance) {
//        DLog(@"Navigating to the first SavedPhotos asset group");
//        for (ALAssetsGroup *group in _groups) {
//            DLog(@"found group with type: %@", [group valueForProperty:ALAssetsGroupPropertyType]);
//            if ([[group valueForProperty:ALAssetsGroupPropertyType]
//                 isEqualToNumber:[NSNumber numberWithInt:ALAssetsGroupSavedPhotos]]) {
//                DLog(@"Found saved photos group: %@", group);
//                // just take the first one
//                ACMasterViewController *mvc = [[ACMasterViewController alloc] initWithNibName:@"ACMasterViewController" bundle:nil];
//                mvc.assetsGroup = group;
//                [self.navigationController pushViewController:mvc animated:NO];
//                [mvc release];
//                break;
//            }
//        }
//        _isFirstAppearance = NO;
//    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    DLog(@"RVC viewDidAppear with %d groups", [_groups count]);
 
}


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _groups.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    //    DLog (@"returning cell %@ at %@", cell, indexPath);
    
    ALAssetsGroup *groupForCell = [_groups objectAtIndex:indexPath.row];
    CGImageRef posterImageRef = [groupForCell posterImage];
    UIImage *posterImage = [UIImage imageWithCGImage:posterImageRef];
    cell.imageView.image = posterImage;
    cell.textLabel.text = [groupForCell valueForProperty:ALAssetsGroupPropertyName];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_groups.count > indexPath.row) {
        ACAlbumViewController *mvc = [[ACAlbumViewController alloc] initWithNibName:@"ACAlbumViewController" bundle:nil];
        mvc.assetsGroup = [_groups objectAtIndex:indexPath.row];
        [self.navigationController pushViewController:mvc animated:YES];
        [mvc release];
    }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
    DLog(@"RootViewController received memory warning");
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
    DLog(@"RootViewController viewDidUnload called");
    
    [_groups release];
    _groups = nil;
    
    [super viewDidUnload];
}


- (void)dealloc {
    [_groups release];
    
    [super dealloc];
}

@end
