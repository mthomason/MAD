//
//  UITableViewCellTableName.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellTableName.h"
#import "Constants.h"

@implementation UITableViewCellTableName

@synthesize tableID = _tableID;

- (void)dealloc {
    [super dealloc];
    if (_tableID != nil) [_tableID release];
}

+ (CGFloat)defaultHeight {
    return UITABLEVIEWCELLTABLENAME_HEIGHT_DEFAULT;
}

@end