//
//  UITableViewCellInstruction.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellInstruction.h"
#import "Constants.h"

@implementation UITableViewCellInstruction

@synthesize labelGroupType = _labelGroupType, labelGroupTypeDetail = _labelGroupTypeDetail;

+ (CGFloat)defaultHeight {
    return UITABLEVIEWCELL_HEIGHT_DEFAULT;
}

@end