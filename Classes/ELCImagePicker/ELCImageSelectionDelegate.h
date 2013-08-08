//
//  ELCImageSelectionDelegate.h
//  ProjectX
//
//  Created by Adam Lovastyik on 2013.08.08..
//  Copyright (c) 2013 PlusQuote. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ELCImageSelectionDelegate <NSObject>

@required

/** 
 User selected/deselected an image
 @param selected tapped image new state as boolean
 */
- (void)selectionChangedWithSelected:(NSNumber*)selected;

/**
 User can select more images if not reached maximum
 */
- (NSNumber*)canSelectMore;

@end
