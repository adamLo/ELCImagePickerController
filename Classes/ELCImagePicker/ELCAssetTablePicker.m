//
//  AssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import "UINavigationController+LimnCustomization.h"
#import "SystemVersion.h"

@interface ELCAssetTablePicker () {
    UILabel *selectedLabel; /** Label to indicate how many images have been selected */
    UILabel *instructionLabel; /** Label to indicate whether to change selection or press done */
    UIImageView *bubbleImageView; /** ImageView holding bubble behind text labels */
    NSInteger selectedCount; /** Count of selected images */
}

@property (nonatomic, assign) int columns;

@end

@implementation ELCAssetTablePicker

#define BLUEBUBBLE [UIImage imageNamed:@"album_bubble_bg_blue"]
#define PINKBUBBLE [UIImage imageNamed:@"album_bubble_bg_pink"]
#define GREENBUBBLE [UIImage imageNamed:@"album_bubble_bg_green"]

@synthesize parent = _parent;;
@synthesize selectedAssetsLabel = _selectedAssetsLabel;
@synthesize assetGroup = _assetGroup;
@synthesize elcAssets = _elcAssets;
@synthesize singleSelection = _singleSelection;
@synthesize columns = _columns;

@synthesize minimumSelection;
@synthesize maximumSelection;

- (void)viewDidLoad
{
    
    //Customize navigation controller
    [self.navigationController customizeNavigationbarForLimn];
    
    if (IOS7) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    //Customize tableview    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[self.tableView setAllowsSelection:NO];
    self.tableView.backgroundColor = [UIColor clearColor];
    //headerView = [self createHeaderView];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
    
    //Reset selection
    selectedCount = 0;
    
    if (self.immediateReturn) {
        
    } else {
        //UIBarButtonItem *doneButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
        UIBarButtonItem *doneButtonItem;
//        if (IOS7) {
            doneButtonItem = [[self.navigationController customButtonForTarget:self touchSelector:@selector(doneAction:) withStyle:BUTTONSTYLEDONE] retain];
/*        }
        else {
            doneButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done button title") style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)] autorelease];
        }*/
        [self.navigationItem setRightBarButtonItem:doneButtonItem];
        [self.navigationItem setTitle:NSLocalizedString(@"Loading...",@"Loading title on image picker screen")];
        
        self.navigationItem.leftBarButtonItem = [[self.navigationController customButtonForTarget:self touchSelector:@selector(popBack) withStyle:BUTTONSTYLEBACK] retain];
    }

	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

- (void)popBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (UITableView*)tableView
{
    return tableView;
}

- (void)setTableView:(UITableView *)newTableView
{
    if ( newTableView != tableView )
    {
        [tableView release];
        tableView = [newTableView retain];
    }
}

- (void)loadView {
    [super loadView];
    //save current tableview, then replace view with a regular uiview
    self.tableView = (UITableView*)self.view;
    UIView *replacementView = [[UIView alloc] initWithFrame:self.tableView.frame];
    self.view = replacementView;
    [replacementView release];
    [self.view addSubview:self.tableView];
    
    //code below adds some custom stuff above the table
    UIView *customHeader = [self createHeaderView];
    [self.view addSubview:customHeader];
    [customHeader release];
    
    //Set background
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background_pattern"]];
    
    self.tableView.frame = CGRectMake(0, customHeader.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - customHeader.frame.size.height);
}
     
- (UIView*)createHeaderView {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70)];
    header.backgroundColor = [UIColor clearColor];
    
    //Bubble image view
    bubbleImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(63, 9, 193, 52)] autorelease];
    bubbleImageView.image = BLUEBUBBLE;
    [header addSubview:bubbleImageView];
    
    //Selection label
    selectedLabel = [[[UILabel alloc] initWithFrame:CGRectMake(63, 15, 193, 21)] autorelease];
    selectedLabel.backgroundColor = [UIColor clearColor];
    selectedLabel.textColor = [UIColor whiteColor];
    selectedLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:12.0];
    selectedLabel.textAlignment = NSTextAlignmentCenter;
    selectedLabel.text = @"";
    [header addSubview:selectedLabel];
    
    //Instruction label
    instructionLabel = [[[UILabel alloc] initWithFrame:CGRectMake(63, 32, 193, 21)] autorelease];
    instructionLabel.backgroundColor = [UIColor clearColor];
    instructionLabel.textColor = [UIColor whiteColor];
    instructionLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:12.0];
    instructionLabel.textAlignment = NSTextAlignmentCenter;
    instructionLabel.text = @"";
    [header addSubview:instructionLabel];
    
    //Update selection
    [self selectionChangedWithSelected:@0];
    
    return header;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.columns = self.view.bounds.size.width / 80;
    
    //Set done button status
    self.navigationItem.rightBarButtonItem.enabled = (minimumSelection == 0) || (selectedCount >= minimumSelection);
    
    //Scroll down to the bottom
    NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
    if (rowCount > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:rowCount inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.columns = self.view.bounds.size.width / 80;
    [self.tableView reloadData];
}

- (void)preparePhotos
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"enumerating photos");
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        
        if(result == nil) {
            return;
        }

        ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
        [elcAsset setParent:self];
        [self.elcAssets addObject:elcAsset];
        [elcAsset release];
     }];
    NSLog(@"done enumerating photos");
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        // scroll to bottom
        int section = [self numberOfSectionsInTableView:self.tableView] - 1;
        int row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
        if (section >= 0 && row >= 0) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:row
                                                 inSection:section];
            [self.tableView scrollToRowAtIndexPath:ip
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:NO];
        }
        
        [self.navigationItem setTitle:self.singleSelection ? NSLocalizedString(@"Pick Photo",@"Pick one photo title on photo picker screen") : NSLocalizedString(@"Pick Photos",@"Pick multiple photos title on photo picker screen")];
    });
    
    [pool release];

}

- (void)doneAction:(id)sender
{	
	NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
	    
	for(ELCAsset *elcAsset in self.elcAssets) {

		if([elcAsset selected]) {
			
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
        
    [self.parent selectedAssets:selectedAssetsImages];
}

- (void)assetSelected:(id)asset
{
    if (self.singleSelection) {

        for(ELCAsset *elcAsset in self.elcAssets) {
            if(asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }
    if (self.immediateReturn) {
        NSArray *singleAssetArray = [NSArray arrayWithObject:[asset asset]];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ceil([self.elcAssets count] / (float)self.columns);
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    int index = path.row * self.columns;
    int length = MIN(self.columns, [self.elcAssets count] - index);
    return [self.elcAssets subarrayWithRange:NSMakeRange(index, length)];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {		        
        cell = [[[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier] autorelease];
        cell.delegate = self;

    } else {		
		[cell setAssets:[self assetsForIndexPath:indexPath]];
	}    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	return 79;
}

- (int)totalSelectedAssets {
    
    int count = 0;
    
    for(ELCAsset *asset in self.elcAssets) {
		if([asset selected]) {   
            count++;	
		}
	}
    
    return count;
}

- (void)dealloc 
{
    [_assetGroup release];    
    [_elcAssets release];
    [_selectedAssetsLabel release];
    [super dealloc];
}

- (void)selectionChangedWithSelected:(NSNumber*)selected {
    
    @synchronized(self) {
        if (selected.boolValue) {
            selectedCount++;
        }
        else {
        
            selectedCount--;
            if (selectedCount < 0) {
                selectedCount = 0;
            }
        }
    }
    
    if (selectedCount == 0) {
        selectedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"No photos selected", @"No photos selected on image picker screen"),selectedCount];
    }
    else {
        selectedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"You have selected %d photos", @"Count of selected photos on image picker screen"),selectedCount];
    }
    
    if ((minimumSelection > 0) && (selectedCount < minimumSelection)) {
        instructionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Please select %d more photos", @"Select more photos label on image picker screen"),minimumSelection-selectedCount];
        self.navigationItem.rightBarButtonItem.enabled = NO;
        bubbleImageView.image = BLUEBUBBLE;
    }
    else if ((maximumSelection > 0) && (selectedCount > maximumSelection)) {
        instructionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Please deselect %d photos", @"Deselect photos label on image picker screen"),selectedCount-maximumSelection];
        self.navigationItem.rightBarButtonItem.enabled = NO;
        bubbleImageView.image = PINKBUBBLE;
    }
    else {
        instructionLabel.text = NSLocalizedString(@"You may press Done to complete", @"Reached desired amount of selected image on image picker screen");
        self.navigationItem.rightBarButtonItem.enabled = YES;
        bubbleImageView.image = GREENBUBBLE;
    }
    
}

// Image selection delegate

- (NSNumber*)canSelectMore {
    return [NSNumber numberWithBool:YES];
    //return [NSNumber numberWithBool:((maximumSelection == 0) || (selectedCount < maximumSelection))];
}


@end
