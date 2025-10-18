//
//  RptqQueryField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_RptqQueryField_Extras_h
#define Reports_RptqQueryField_Extras_h

#import <MAD/RptqQueryField.h>
#import <MADDataStructures/MTProtocolLog.h>

@interface RptqQueryField (Extras) <MTProtocolLog>

	+ (instancetype)newQueryField:(NSManagedObjectContext *)managedObjectContext;
	+ (instancetype)queryFieldForObjectID:(NSManagedObjectID *)objectID
					 managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

	+ (NSFetchRequest<NSDictionary *> *)fetchRequestFieldKeys:(int64_t)identifier;
	+ (NSFetchRequest *)fetchRequestFields:(int64_t)identifier;

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
