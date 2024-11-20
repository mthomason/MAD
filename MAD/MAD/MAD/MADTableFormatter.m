//
//  MADTableFormatter.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADTableFormatter.h"
#import <MADAPI/MADQuery.h>

@implementation MADTableFormatter

@dynamic didRefresh;

- (instancetype)initWithQuery:(MADQuery <MADQueryDatabaseProtocol> *)query {
    if (self = [super initWithQuery:query]) {

        self.query = query;
        self.didRefresh = NO;
        
    }
    return self;
}

#pragma mark - Reading cached data

- (BOOL)needsFormat { return super.needsFormat; }

@end
