//
//  UITableViewCellInstruction.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTAutoLayoutTableViewCell.h"

@interface UITableViewCellInstruction : MTAutoLayoutTableViewCell

@property (nonatomic, assign) IBOutlet UILabel *labelGroupType;
@property (nonatomic, assign) IBOutlet UILabel *labelGroupTypeDetail;

+ (CGFloat)defaultHeight;

@end
