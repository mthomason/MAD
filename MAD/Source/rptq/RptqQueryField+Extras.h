//
//  RptqQueryField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqQueryField_Extras_h
#define Reports_RptqQueryField_Extras_h

#import <MAD/RptqQueryField.h>
#import <MAD/RptqStoreContext.h>
#import <MADDataStructures/MTProtocolLog.h>

@interface RptqQueryField (Extras) <MTProtocolLog>

	+ (instancetype)newQueryField:(RptqStoreContext *)managedObjectContext;
	+ (instancetype)queryFieldForObjectID:(int64_t)objectID
					 managedObjectContext:(RptqStoreContext *)managedObjectContext;

	- (NSString *)display;
	- (NSString *)tableFieldKey;
	- (NSString *)toStringReverse;

	+ (NSString *)keyFieldName;
	+ (NSString *)keyTableName;
	+ (NSString *)keySchemaTable;
	+ (NSString *)keyQueryTableID;
	+ (NSString *)keyQueryFieldID;
	+ (NSString *)keySchemaTableID;
	+ (NSString *)keySchemaFieldID;
	+ (NSString *)keyInQueryTable;
	+ (NSString *)keyInQueryTableAlias;
	+ (NSString *)keySchemaFieldName;
	+ (NSString *)keySchemaFieldDataType;

@end

#endif
