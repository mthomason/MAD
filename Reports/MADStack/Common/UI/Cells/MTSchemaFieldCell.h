//
//  MTSchemaFieldCell.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTSchemaFieldCell_h
#define Reports_MTSchemaFieldCell_h

#import <UIKit/UITableViewCell.h>

@class MTSchemaFieldCell;

@protocol MADSchemaFieldCellProtocol;

@interface MTSchemaFieldCell : UITableViewCell

    @property (nonatomic, weak) IBOutlet id <MADSchemaFieldCellProtocol> delegate;
    @property (nonatomic, strong) IBOutlet UILabel *detailLabel;
    @property (nonatomic, strong) UIView *parentContainerView;

@end

#endif
