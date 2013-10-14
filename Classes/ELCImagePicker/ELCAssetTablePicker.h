//
//  AssetTablePicker.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ELCAsset.h"
#import "ELCAssetSelectionDelegate.h"
#import "ELCImageSelectionDelegate.h"
#import "ELCAssetPickerFilterDelegate.h"

@interface ELCAssetTablePicker : UITableViewController <ELCAssetDelegate, ELCImageSelectionDelegate> {
    UITableView *tableView;
}

@property (nonatomic, assign) id <ELCAssetSelectionDelegate> parent;
@property (nonatomic, retain) ALAssetsGroup *assetGroup;
@property (nonatomic, retain) NSMutableArray *elcAssets;
@property (nonatomic, retain) IBOutlet UILabel *selectedAssetsLabel;
@property (nonatomic, assign) BOOL singleSelection;
@property (nonatomic, assign) BOOL immediateReturn;

@property (assign) NSInteger minimumSelection; /** Minimum number of required selection */
@property (assign) NSInteger maximumSelection; /** Maximum number of required selection */

// optional, can be used to filter the assets displayed
@property(nonatomic, assign) id<ELCAssetPickerFilterDelegate> assetPickerFilterDelegate;

- (int)totalSelectedAssets;
- (void)preparePhotos;

- (void)doneAction:(id)sender;

- (void)assetSelected:(ELCAsset *)asset;

@end
