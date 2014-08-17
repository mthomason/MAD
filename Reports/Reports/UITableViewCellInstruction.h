//
//  UITableViewCellInstruction.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewCellInstruction_h
#define Reports_UITableViewCellInstruction_h

#import <UIKit/UIKit.h>
#import "MTAutoLayoutTableViewCell.h"
#import "Constants.h"

@interface UITableViewCellInstruction : MTAutoLayoutTableViewCell

@property (nonatomic, weak) IBOutlet UILabel *labelGroupType;
@property (nonatomic, weak) IBOutlet UILabel *labelGroupTypeDetail;

- (id)initWithCoder:(NSCoder *)aDecoder;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
+ (CGFloat)defaultHeight;

@end

#endif
