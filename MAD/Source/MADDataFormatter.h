//
//  MADDataFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/24/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDataFormatter_h
#define MAD_MADDataFormatter_h

#import <objc/NSObject.h>

@class MADQuery;
@protocol MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol;

@interface MADDataFormatter : NSObject


	@property (nonatomic, strong) MADQuery <MADQueryDatabaseProtocol> *query;
	@property (nonatomic, assign) BOOL didRefresh;
	@property (nonatomic, assign, readonly) BOOL needsFormat;

+ (instancetype)newDataFormatter:(MADQuery <MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol> *)query;
- (instancetype)initWithQuery:(MADQuery <MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol> *)query;

@end

#endif
