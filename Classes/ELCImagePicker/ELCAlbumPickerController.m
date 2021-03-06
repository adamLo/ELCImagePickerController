//
//  AlbumPickerController.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"
#import "UINavigationController+LimnCustomization.h"
#import "SystemVersion.h"

//GA
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "PQGoogleAnalytics.h"

@interface ELCAlbumPickerController ()

@property (nonatomic, retain) ALAssetsLibrary *library;

@end

@implementation ELCAlbumPickerController

@synthesize parent = _parent;
@synthesize assetGroups = _assetGroups;
@synthesize library = _library;

@synthesize minimumSelection;
@synthesize maximumSelection;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    if (IOS7) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    [self.navigationController customizeNavigationbarForLimn];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    //Customize tableview
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background_pattern"]];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
	[self.navigationItem setTitle:NSLocalizedString(@"Loading...",@"Loading albums title on album picker screen")];

    //UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelImagePicker)];
    UIBarButtonItem *cancelButton = [[self.navigationController customButtonForTarget:self.parent touchSelector:@selector(cancelImagePicker) withStyle:BUTTONSTYLECANCEL] retain];
	[self.navigationItem setRightBarButtonItem:cancelButton];
	[cancelButton release];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	self.assetGroups = tempArray;
    [tempArray release];
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    self.library = assetLibrary;
    [assetLibrary release];

    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // Group enumerator Block
        void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) 
        {
            if (group == nil) {
                return;
            }
            
            // added fix for camera albums order
            NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
            NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
            
            if ([[sGroupPropertyName lowercaseString] isEqualToString:@"camera roll"] && nType == ALAssetsGroupSavedPhotos) {
                [self.assetGroups insertObject:group atIndex:0];
            }
            else {
                [self.assetGroups addObject:group];
            }

            // Reload albums
            [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:YES];
        };
        
        // Group Enumerator Failure Block
        void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
            
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error dialog title") message:NSLocalizedString(@"Please enable Limn to access photos in Settings!", @"Error message when user declined access to photos") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            [alert release];
            
            NSLog(@"A problem occured %@", [error description]);	                                 
        };	
                
        // Enumerate Albums
        [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                               usingBlock:assetGroupEnumerator 
                             failureBlock:assetGroupEnumberatorFailure];
        
        [pool release];
    });    
}


- (void)viewWillAppear:(BOOL)animated {
    [self.navigationItem setTitle:NSLocalizedString(@"Select an Album",@"Select album title on album picker screen")];
}

- (void)viewDidAppear:(BOOL)animated {
    //Manually track view
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:GA_SCREEN_SELECTALBUM];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.navigationItem.title = NSLocalizedString(@"Albums", @"Short back button title on photo selection screen");
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)reloadTableView
{
	[self.tableView reloadData];
	[self.navigationItem setTitle:NSLocalizedString(@"Select an Album",@"Select album title on album picker screen")];
}

- (void)selectedAssets:(NSArray*)assets
{
	[_parent selectedAssets:assets];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.assetGroups count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
    }
    
    // Get count
    ALAssetsGroup *g = (ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row];
    [g setAssetsFilter:[ALAssetsFilter allPhotos]];
    NSInteger gCount = [g numberOfAssets];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%ld)",[g valueForProperty:ALAssetsGroupPropertyName], (long)gCount];
    [cell.imageView setImage:[UIImage imageWithCGImage:[(ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row] posterImage]]];
	//[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    //Customize cell for Limn
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:15.f];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] initWithNibName: nil bundle: nil];
	picker.parent = self;
    picker.minimumSelection = minimumSelection;
    picker.maximumSelection = maximumSelection;

    picker.assetGroup = [self.assetGroups objectAtIndex:indexPath.row];
    [picker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    
	picker.assetPickerFilterDelegate = self.assetPickerFilterDelegate;
    
    //Send GA event
    NSString *gaLabel;
    ALAssetsGroup *g = (ALAssetsGroup*)[self.assetGroups objectAtIndex:indexPath.row];
    gaLabel = [g valueForProperty:ALAssetsGroupPropertyName];
    if (gaLabel.length == 0) {
        gaLabel = @"No name";
    }
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createEventWithCategory:GA_CATEGORY_ALBUM action:GA_ACTION_SELECTALBUM label:gaLabel value:nil] build]];

	
	[self.navigationController pushViewController:picker animated:YES];
	[picker release];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	return 57;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc 
{	
    [_assetGroups release];
    [_library release];
    [super dealloc];
}

@end

