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

- (instancetype)init {
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

- (void)reset {
    _rowCounter = 0;
    _groupCounter = 0;
    _pageCounter = 0;
    _detailRowId = 0;
    _detailRowIdLast = 0;
    _counterHeightUsedCurrentPage = 0.0000f;
}

@end
