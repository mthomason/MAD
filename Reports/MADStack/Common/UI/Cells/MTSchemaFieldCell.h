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

@property (nonatomic, weak) IBOutlet id <MTSchemaFieldCellDelegate> delegate;
@property (nonatomic, strong) IBOutlet UILabel *detailLabel;
@property (nonatomic, strong) UIView *parentContainerView;

@end

#endif
