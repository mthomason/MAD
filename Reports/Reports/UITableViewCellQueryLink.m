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

- (void)dealloc {
    [_tableID release];
    [super dealloc];
}

+ (CGFloat)defaultHeight {
    return MNSTableViewCellQueryLinkHeightDefault;
}

@end