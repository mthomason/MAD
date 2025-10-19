//
//  MTCollectionViewCell.h
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
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
