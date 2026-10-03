//
//  MADQueryReport.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQueryFull_h
#define Reports_MTQueryFull_h

#import <MADAPI/MADQuery.h>
#import <MAD/RptqStoreContext.h>

@class NSManagedObjectID, NSManagedObjectContext, RptqQuery;

@interface MADQueryFull : MADQuery <MADQueryFieldKeysProtocol, MADQueryDataDelegateProtocol>

- (instancetype)initWithQuery:(RptqQuery *)query andQueryLimit:(NSUInteger)queryLimit;

- (NSString *)copySQLWithManagedObjectContext:(RptqStoreContext *)managedObjectContext
										error:(NSError * __autoreleasing *)error;

- (NSString *)SQLOnlyActiveFields:(BOOL)onlyActiveFields
			 managedObjectContext:(RptqStoreContext *)managedObjectContext
							error:(NSError **)error;

@property (nonatomic, assign) NSUInteger limitResults;

@end

#endif
