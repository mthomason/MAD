//
//  MTCollectionViewCell.h
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADCellElement_h
#define Reports_MADCellElement_h

#import "MADManagedObjectCollectionViewCell.h"

@protocol MADCellElementDelegate;

@class MADCellElement, MADDesignerElementView;

@interface MADCellElement : MADManagedObjectCollectionViewCell  <UIContextMenuInteractionDelegate>
@property (nonatomic, weak) NSObject <MADCellElementDelegate> *delegate;
- (void)addElementView:(MADDesignerElementView *)elementView;
@end

#endif
