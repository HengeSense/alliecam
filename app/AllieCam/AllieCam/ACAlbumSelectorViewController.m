//
//  ACAlbumSelectorViewController.m
//  AllieCam
//
//  Created by Mark Blackwell on 3/01/13.
//  Copyright (c) 2013 Mark Blackwell. All rights reserved.
//

#import "ACAlbumSelectorViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ACAlbumViewController.h"
#import "ACAlbum.h"
#import "ACLocalPhotoManager.h"
#import "AllieCam.h"

@interface ACAlbumSelectorViewController ()

@end

@implementation ACAlbumSelectorViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithAlbums:(NSArray *)albums {
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        self.albums = albums;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _albums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    //    DLog (@"returning cell %@ at %@", cell, indexPath);
    
    id<ACAlbum> album = [_albums objectAtIndex:indexPath.row];
    UIImage *posterImage = [album posterImage];
    if (!posterImage && [album numberOfPhotos] > 0) {
        posterImage = [[album photoAtIndex:0] thumbnail];
    }
    if (!posterImage && [album numberOfPhotos] > 0) {
        posterImage = [UIImage imageNamed:@"Placeholder.png"];
        [_manager loadThumbnail:[album photoAtIndex:0] success:^(UIImage *thumbnail) {
            cell.imageView.image = thumbnail;
        }];
    }
    cell.imageView.image = posterImage;
    cell.textLabel.text = album.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d photos", [album numberOfPhotos]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_albums.count > indexPath.row) {
        id<ACAlbum> album = [_albums objectAtIndex:indexPath.row];
        ACAlbumViewController *mvc = [[ACAlbumViewController alloc] initWithAlbum:album];
        [self.navigationController pushViewController:mvc animated:YES];
        [mvc release];
    }
}

@end
