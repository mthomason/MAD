//
//  MTCollectionViewCell.h
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADCellElement_h
#define Reports_MADCellElement_h

#import "MADManagedObjectCollectionViewCell.h"
#import <MAD/MADDocumentObjectType.h>

@class MADCellElement, MADDesignerElementView;

@protocol MADCellElementDelegate

    - (void)deleteDocumentObjectRepresentedByCell:(MADCellElement *)cell;
    - (void)editDocumentObjectRepresentedByCell:(MADCellElement *)cell;
    - (void)formatDocumentObjectRepresentedByCell:(MADCellElement *)cell;
    - (MTDocumentObjectType)objectTypeRepresentedByCell:(MADCellElement *)cell;

@end

@interface MADCellElement : MADManagedObjectCollectionViewCell

    @property (nonatomic, weak) id <MADCellElementDelegate> delegate;
    - (void)addElementView:(MADDesignerElementView *)elementView;

@end

#endif
