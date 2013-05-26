//
//  MTCollectionViewCell.h
//  Reports
//
//  Created by Michael Thomason on 12/21/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTCollectionViewCellElement;

@protocol MTCollectionViewCellElementDelegate
- (void)deleteDocumentObjectRepresentedByCell:(MTCollectionViewCellElement *)cell;
@end

@interface MTCollectionViewCellElement : UICollectionViewCell

@property (nonatomic, assign) IBOutlet id <MTCollectionViewCellElementDelegate> delegate;

@end
