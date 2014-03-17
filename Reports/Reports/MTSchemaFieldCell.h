//
//  MTSchemaFieldCell.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTSchemaFieldCell_h
#define Reports_MTSchemaFieldCell_h

#import <UIKit/UIKit.h>

@class MTSchemaFieldCell;

@protocol MTSchemaFieldCellDelegate
@optional
- (void)tableViewCell:(MTSchemaFieldCell *)tableViewCell didUpdateAnchorPointLeftTo:(CGPoint)anchorPointLeft andAnchorPointRightTo:(CGPoint)anchorPointRight;
@end

@interface MTSchemaFieldCell : UITableViewCell

@property (nonatomic, assign) IBOutlet id <MTSchemaFieldCellDelegate> delegate;
@property (nonatomic, retain) IBOutlet UILabel *detailLabel;
@property (nonatomic, retain) UIView *parentContainerView;

@end

#endif
