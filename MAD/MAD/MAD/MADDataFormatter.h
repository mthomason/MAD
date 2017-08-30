//
//  MADDataFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/24/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDataFormatter_h
#define MAD_MADDataFormatter_h

#import <objc/NSObject.h>

@class MTQuery;
@protocol MADQueryDatabaseProtocol;

@interface MADDataFormatter : NSObject

    + (instancetype)newDataFormatter:(MTQuery <MADQueryDatabaseProtocol> *)query;

    @property (nonatomic, strong) MTQuery <MADQueryDatabaseProtocol> *query;
    @property (nonatomic, assign) BOOL didRefresh;
    @property (nonatomic, assign, readonly) BOOL needsFormat;

    - (instancetype)initWithQuery:(MTQuery <MADQueryDatabaseProtocol> *)query;

@end

#endif
