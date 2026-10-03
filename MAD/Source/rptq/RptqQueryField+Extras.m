//
//  RptqQueryField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqQueryField+Extras.h"

#if DEBUG
	#import <objc/runtime.h>
#endif

#import <os/log.h>

#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSError.h>

#import <MADFoundation/MADStringUtilities.h>

#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDataHelper.h"

@implementation RptqQueryField (Extras)

+ (NSString *)keyInQueryTable {
	return NSStringFromSelector(@selector(inQueryTable));
}

+ (NSString *)keyName {
	return NSStringFromSelector(@selector(name));
}

+ (NSString *)dropIndex {
	return NSStringFromSelector(@selector(dropIndex));
}

+ (NSString *)keyInQueryTableDropIndex {
	NSString *keyPathInQueryTableDropIndex = [MADStringUtilities stringByAppendingPeriod: [self keyInQueryTable]];
	return [keyPathInQueryTableDropIndex stringByAppendingString:NSStringFromSelector(@selector(dropIndex))];
}

+ (NSString *)keyDatabaseSchemaTable {
	NSString *keyPathDatabaseSchemaTable = NSStringFromSelector(@selector(databaseSchemaTable));
	return keyPathDatabaseSchemaTable;
}

+ (NSString *)keyTableName {
	NSString *keyPathTableName = [MADStringUtilities stringByAppendingPeriod: [self keyInQueryTable]];
	keyPathTableName = [keyPathTableName stringByAppendingString: [self keyDatabaseSchemaTable]];
	keyPathTableName = [MADStringUtilities stringByAppendingPeriod: keyPathTableName];
	keyPathTableName = [keyPathTableName stringByAppendingString: [self keyName]];
	return keyPathTableName;
}

+ (NSString *)keyFieldName {
	NSString *keyPathName = [self keyName];
	NSString *keyPathDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
	NSString *keyPathFieldName = [MADStringUtilities stringByAppendingPeriod: keyPathDatabaseSchemaField];
	keyPathFieldName = [keyPathFieldName stringByAppendingString:keyPathName];
	return keyPathFieldName;
}

+ (NSString *)keySchemaTable {
	NSString *keyPathSchemaTable = [MADStringUtilities stringByAppendingPeriod: [self keyInQueryTable]];
	return [keyPathSchemaTable stringByAppendingString: [self keyDatabaseSchemaTable]];
}

+ (NSString *)keyQueryTableID {
	NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
	NSString *keyInQueryTable = [self keyInQueryTable];
	return [[MADStringUtilities stringByAppendingPeriod: keyInQueryTable] stringByAppendingString:keyIdentifier];
}

+ (NSString *)keyQueryFieldID {
	return NSStringFromSelector(@selector(identifier));
}

+ (NSString *)keySchemaTableID {
	NSString *keySchemaTable = [self keySchemaTable];
	return [[MADStringUtilities stringByAppendingPeriod: keySchemaTable] stringByAppendingString:NSStringFromSelector(@selector(identifier))];
}

+ (NSString *)keySchemaFieldID {
	NSString *key = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(databaseSchemaField))];
	return [key stringByAppendingString:NSStringFromSelector(@selector(identifier))];
}

+ (NSString *)keySchemaFieldName {
	NSString *key = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(databaseSchemaField))];
	return [key stringByAppendingString:NSStringFromSelector(@selector(name))];
}

+ (NSString *)keySchemaFieldDataType {
	NSString *key = [MADStringUtilities stringByAppendingPeriod: NSStringFromSelector(@selector(databaseSchemaField))];
	return [key stringByAppendingString:NSStringFromSelector(@selector(dataType))];
}

+ (NSString *)keyInQueryTableAlias {
	NSString *key = [MADStringUtilities stringByAppendingPeriod: [self keyInQueryTable]];
	return [key stringByAppendingString:NSStringFromSelector(@selector(alias))];
}

+ (instancetype)newQueryField:(RptqStoreContext *)managedObjectContext NS_RETURNS_RETAINED {
	return (RptqQueryField *)[managedObjectContext insertObjectForEntity:NSStringFromClass([RptqQueryField class])
															  identifier:0];
}

- (NSString *)tableFieldKey {
	return [self toString];
}

- (NSString *)display {
	return self.toStringHumanReadable.lowercaseString;
}

+ (instancetype)queryFieldForObjectID:(int64_t)objectId
				 managedObjectContext:(RptqStoreContext *)managedObjectContext {
	return (RptqQueryField *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryField class])
													   identifier:objectId];
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
	return [MADStringUtilities stringByAppendingKeyPath: self.databaseSchemaField.name toString:self.inQueryTable.alias];
}

- (NSString *)toStringReverse {
	return [self inQueryTable] ?
			[MADStringUtilities stringByAppendingKeyPath: self.inQueryTable.alias toString:self.databaseSchemaField.name] : @"";
}

- (NSString *)toString {
	NSString *queryAlias = [self.inQueryTable queryAlias];
	return [MADStringUtilities stringByAppendingKeyPath: self.databaseSchemaField.name toString:queryAlias];
}

- (NSString *)toStringDebug {
	return [NSString stringWithFormat:@"%@", self];
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"***********   RptqQueryField  ***********\n"];
	[description appendFormat:@"Identifier:             %lld\n", self.identifier];
	[description appendFormat:@"Schema field:           %@\n", self.databaseSchemaField];
	[description appendFormat:@"***********   RptqQueryField  ***********"];
	return description;
}

@end
