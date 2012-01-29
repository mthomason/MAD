//
//  UITableViewCellQueryLink.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellQueryLink.h"
#import "Constants.h"

@implementation UITableViewCellQueryLink

@synthesize labelFieldLeft, labelFieldRight, labelJoinArrow, labelJoinDesc, labelTableLeft, labelTableRight;

+ (CGFloat)defaultHeight {
    return UITABLEVIEWCELLQUERYLINK_HEIGHT_DEFAULT;
}

@end