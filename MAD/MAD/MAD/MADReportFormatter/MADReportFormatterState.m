//
//  MADReportFormatterState.m
//  MAD
//
//  Created by Michael Thomason on 2/22/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADReportFormatterState.h"
#import <Foundation/NSValue.h>
#import <Foundation/NSArray.h>
#import <MADFoundation/MADDataProtocol.h>

@implementation MADReportFormatterState

- (instancetype)initWithDataDelegate:(id <MADDataProtocol>)dataDelegate {
    return self = [super init];
}

- (void)resetWithDataDelegate:(id <MADDataProtocol>)dataDelegate {
    NSArray *sortDescriptors = [dataDelegate sortDescriptors];
    _sortDescriptors = sortDescriptors.copy;
    _rowCounter = 0;
    _groupCounter = 0;
    _pageCounter = 0;
    _detailRowId = 0;
    _detailRowIdLast = 0;
    _counterHeightUsedCurrentPage = 0.0;
}

@end
