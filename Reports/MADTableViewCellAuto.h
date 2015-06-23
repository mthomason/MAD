//
//  MADTableViewCellAuto.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MADTableViewCellAuto : UITableViewCell

@property (nonatomic, strong) UILabel *label;
//@property (nonatomic, assign) MADVibrantTableViewCellMarginStyle marginStyle;

@property (nonatomic, strong) NSArray *layoutConstraints;
@property (atomic, assign) BOOL updatingConstraints;

- (void)updateConstraints;
- (void)initalize;

@end
