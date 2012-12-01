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

@synthesize labelFieldLeft = _labelFieldLeft, labelFieldRight = _labelFieldRight, labelJoinArrow = _labelJoinArrow, labelJoinDesc = _labelJoinDesc, labelTableLeft = _labelTableLeft, labelTableRight = _labelTableRight;
@synthesize tableID = _tableID;

- (void)dealloc {
    [_tableID release];
    [super dealloc];
}

+ (CGFloat)defaultHeight {
    return MNSTableViewCellQueryLinkHeightDefault;
}

@end