//
//  MTCollectionViewCell.h
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+NSObjectIdTag.h"
#import "MAReportDocument.h"

@class MTCollectionViewCellElement;

@protocol MTCollectionViewCellElementDelegate

- (void)deleteDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell;
- (void)editDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell;
- (MTDocumentObjectType)objectTypeRepresentedByCell:(MTCollectionViewCellElement *)cell;

@end

@interface MTCollectionViewCellElement : UICollectionViewCell

@property (nonatomic, assign) id <MTCollectionViewCellElementDelegate> delegate;

@end
