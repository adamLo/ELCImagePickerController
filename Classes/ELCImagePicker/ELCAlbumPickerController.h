//
//  AlbumPickerController.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAssetSelectionDelegate.h"
#import "ELCAssetPickerFilterDelegate.h"

@interface ELCAlbumPickerController : UITableViewController <ELCAssetSelectionDelegate>

@property (nonatomic, assign) id<ELCAssetSelectionDelegate> parent;
@property (nonatomic, retain) NSMutableArray *assetGroups;

@property (assign) NSInteger minimumSelection; /** Minimum number of required selection */
@property (assign) NSInteger maximumSelection; /** Maximum number of required selection */

// optional, can be used to filter the assets displayed
@property (nonatomic, assign) id<ELCAssetPickerFilterDelegate> assetPickerFilterDelegate;

@end

