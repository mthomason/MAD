//
//  RptqDatabaseCredentals+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqUserCredentals_Extras_h
#define Reports_RptqUserCredentals_Extras_h

#import <MADAPI/MADConnectionsPropertiesProtocol.h>
#import <MAD/RptqDatabaseCredentals.h>
#import <MAD/RptqStoreContext.h>

@interface RptqDatabaseCredentals (Extras) <MADConnectionsPropertiesProtocol>

+ (instancetype)newDatabaseCredental:(RptqStoreContext *)objectContext;
+ (NSArray <RptqDatabaseCredentals *> *)newDatabaseCredentals:(RptqStoreContext *)objectContext;
- (NSString *)databaseSchemaName;

@end

#endif
