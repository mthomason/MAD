//
//  MTCollectionViewCell.h
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTCollectionViewCellElement_h
#define Reports_MTCollectionViewCellElement_h

#import <UIKit/UIKit.h>
#import "RptqDocumentObject+Extras.h"

@class MTCollectionViewCellElement;

@protocol MTCollectionViewCellElementDelegate

- (void)deleteDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell;
- (void)editDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell;
- (void)formatDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell;
- (MTDocumentObjectType)objectTypeRepresentedByCell:(MTCollectionViewCellElement *)cell;

@end

@interface MTCollectionViewCellElement : UICollectionViewCell

@property (nonatomic, weak) id <MTCollectionViewCellElementDelegate> delegate;

@end

#endif
