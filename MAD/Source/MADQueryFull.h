//
//  MADQueryReport.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryFull_h
#define Reports_MTQueryFull_h

#import <MADAPI/MADQuery.h>
#import <MAD/RptqStoreContext.h>

@class RptqQuery;

@interface MADQueryFull : MADQuery <MADQueryFieldKeysProtocol, MADQueryDataDelegateProtocol>

- (instancetype)initWithQuery:(RptqQuery *)query andQueryLimit:(NSUInteger)queryLimit;

/// The source database that supplies the dialect for the selected query.  The
/// document sets it to the database built for that query's `inDatabase`; when it
/// is nil the generator falls back to the data delegate's database, which is the
/// single-source behaviour this class had before query selection was explicit.
@property (nonatomic, strong) MADDatabase *database;

- (NSString *)copySQLWithManagedObjectContext:(RptqStoreContext *)managedObjectContext
										error:(NSError * __autoreleasing *)error;

- (NSString *)SQLOnlyActiveFields:(BOOL)onlyActiveFields
			 managedObjectContext:(RptqStoreContext *)managedObjectContext
							error:(NSError * __autoreleasing *)error;

@property (nonatomic, assign) NSUInteger limitResults;

@end

#endif
