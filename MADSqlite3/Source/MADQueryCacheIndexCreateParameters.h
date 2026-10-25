//
//  MADQueryCacheIndexCreateParameters.h
//  MAD
//
//  Created by Michael on 1/17/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADQueryCacheIndexCreateParameters_h
#define Reports_MADQueryCacheIndexCreateParameters_h

#import <Foundation/NSObject.h>

@interface MADQueryCacheIndexCreateParameters : NSObject

@property (nonatomic, weak) NSDictionary *columns;
@property (nonatomic, weak) NSArray *sortDescriptors;
@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, copy) NSString *groupName;

@end

#endif
