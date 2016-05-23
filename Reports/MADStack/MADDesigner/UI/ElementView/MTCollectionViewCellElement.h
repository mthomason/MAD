//
//  MTCollectionViewCell.h
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTCollectionViewCellElement_h
#define Reports_MTCollectionViewCellElement_h

#import <MAD/MADDocumentObjectType.h>
#import "MADManagedObjectCollectionViewCell.h"

@class MTCollectionViewCellElement, MADDesignerElementView;

@protocol MTCollectionViewCellElementDelegate

    - (void)deleteDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell;
    - (void)editDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell;
    - (void)formatDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell;
    - (MTDocumentObjectType)objectTypeRepresentedByCell:(MTCollectionViewCellElement *)cell;

@end

@interface MTCollectionViewCellElement : MADManagedObjectCollectionViewCell

    @property (nonatomic, weak) id <MTCollectionViewCellElementDelegate> delegate;
    - (void)addElementView:(MADDesignerElementView *)elementView;

@end

#endif
