//
//  AssetCell.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCImageSelectionDelegate.h"

@interface ELCAssetCell : UITableViewCell

@property (assign) id<ELCImageSelectionDelegate> delegate; /** Parent view controller to notify about selection change */

- (id)initWithAssets:(NSArray *)assets reuseIdentifier:(NSString *)identifier;
- (void)setAssets:(NSArray *)assets;


@end
