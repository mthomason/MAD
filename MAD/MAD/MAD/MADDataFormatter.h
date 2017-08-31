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

@class MADQuery;
@protocol MADQueryDatabaseProtocol;

@interface MADDataFormatter : NSObject

    + (instancetype)newDataFormatter:(MADQuery <MADQueryDatabaseProtocol> *)query;

    @property (nonatomic, strong) MADQuery <MADQueryDatabaseProtocol> *query;
    @property (nonatomic, assign) BOOL didRefresh;
    @property (nonatomic, assign, readonly) BOOL needsFormat;

    - (instancetype)initWithQuery:(MADQuery <MADQueryDatabaseProtocol> *)query;

@end

#endif
