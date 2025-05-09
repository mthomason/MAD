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

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSExpressionDescription.h>

#import <MADFoundation/MADStringUtilities.h>

#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDataHelper.h"

@implementation RptqQueryField (Extras)

- (void)awakeFromInsert {
	[super awakeFromInsert];
	if (self.managedObjectContext.parentContext && self.identifier <= 0) {
		[[NSNotificationCenter defaultCenter] willChangeValueForKey:NSStringFromSelector(@selector(identifier))];
		self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
											managedObjectContext:self.managedObjectContext];
		[[NSNotificationCenter defaultCenter] didChangeValueForKey:NSStringFromSelector(@selector(identifier))];
	}
}

- (BOOL)validateForInsert:(NSError * _Nullable __autoreleasing *)error {
	BOOL success;
	NSError * __autoreleasing errorValidation = nil;
	if (!(success = [super validateForInsert:&errorValidation])) {
		if (error != NULL) { // Check if error is not NULL before dereferencing
			*error = errorValidation.copy; // Copy the error to outError
		}
		os_log_error(OS_LOG_DEFAULT, "Error: %s", errorValidation.localizedDescription.UTF8String);
	}
	return success;
}

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
	NSString *keyPathInQueryTableDropIndex = [MADStringUtilities stringByAppendingPeriodToString: [self keyInQueryTable]];
	return [keyPathInQueryTableDropIndex stringByAppendingString:NSStringFromSelector(@selector(dropIndex))];
}

+ (NSString *)keyDatabaseSchemaTable {
	NSString *keyPathDatabaseSchemaTable = NSStringFromSelector(@selector(databaseSchemaTable));
	return keyPathDatabaseSchemaTable;
}

+ (NSString *)keyTableName {
	NSString *keyPathTableName = [MADStringUtilities stringByAppendingPeriodToString: [self keyInQueryTable]];
	keyPathTableName = [keyPathTableName stringByAppendingString: [self keyDatabaseSchemaTable]];
	keyPathTableName = [MADStringUtilities stringByAppendingPeriodToString: keyPathTableName];
	keyPathTableName = [keyPathTableName stringByAppendingString: [self keyName]];
	return keyPathTableName;
}

+ (NSString *)keyFieldName {
	NSString *keyPathName = [self keyName];
	NSString *keyPathDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
	NSString *keyPathFieldName = [MADStringUtilities stringByAppendingPeriodToString: keyPathDatabaseSchemaField];
	keyPathFieldName = [keyPathFieldName stringByAppendingString:keyPathName];
	return keyPathFieldName;
}

+ (NSString *)keySchemaTable {
	NSString *keyPathSchemaTable = [MADStringUtilities stringByAppendingPeriodToString: [self keyInQueryTable]];
	return [keyPathSchemaTable stringByAppendingString: [self keyDatabaseSchemaTable]];
}

+ (NSString *)keyQueryTableID {
	NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
	NSString *keyInQueryTable = [self keyInQueryTable];
	NSString *key;
	key = [MADStringUtilities stringByAppendingPeriodToString: keyInQueryTable];
	key = [key stringByAppendingString:keyIdentifier];
	return key;
}

+ (NSString *)keyQueryFieldID {
	return NSStringFromSelector(@selector(identifier));
}

+ (NSString *)keySchemaTableID {
	NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
	NSString *keySchemaTable = [self keySchemaTable];
	NSString *key = [MADStringUtilities stringByAppendingPeriodToString: keySchemaTable];
	return [key stringByAppendingString:keyIdentifier];
}

+ (NSString *)keySchemaFieldID {
	NSString *key = [MADStringUtilities stringByAppendingPeriodToString: NSStringFromSelector(@selector(databaseSchemaField))];
	return [key stringByAppendingString:NSStringFromSelector(@selector(identifier))];
}

+ (NSString *)keySchemaFieldName {
	NSString *key = [MADStringUtilities stringByAppendingPeriodToString: NSStringFromSelector(@selector(databaseSchemaField))];
	return [key stringByAppendingString:NSStringFromSelector(@selector(name))];
}

+ (NSString *)keySchemaFieldDataType {
	NSString *key = [MADStringUtilities stringByAppendingPeriodToString: NSStringFromSelector(@selector(databaseSchemaField))];
	return [key stringByAppendingString:NSStringFromSelector(@selector(dataType))];
}

+ (NSString *)keyInQueryTableAlias {
	NSString *key = [MADStringUtilities stringByAppendingPeriodToString: [self keyInQueryTable]];
	return [key stringByAppendingString:NSStringFromSelector(@selector(alias))];
}

+ (NSFetchRequest *)fetchRequestFields:(int64_t)identifier {
	
	NSUInteger expressionInQueryCount = 2;

	NSExpression *pexpressions[expressionInQueryCount];
	NSString *predicateKey;
	NSNumber *idn = @(identifier);
	NSString *keyInQueryTable = [self keyInQueryTable];
	predicateKey = [MADStringUtilities stringByAppendingPeriodToString: keyInQueryTable];
	predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(inQuery))];
	predicateKey = [MADStringUtilities stringByAppendingPeriodToString: predicateKey];
	predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(identifier))];
	
	pexpressions[0] = [NSExpression expressionForKeyPath:predicateKey];
	pexpressions[1] = [NSExpression expressionForConstantValue: idn];
	
	NSPredicate *predicate;
	predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
												   rightExpression: pexpressions[1]
														  modifier: NSDirectPredicateModifier
															  type: NSEqualToPredicateOperatorType
														   options: 0];

	
	NSFetchRequest *fetchQueryTable;
	NSString *entityName;
	entityName = NSStringFromClass([RptqQueryField class]);
	fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:entityName];
	
	NSString *keyPathInQueryTable = [self keyInQueryTable];
	
	NSString *keyPathInQueryTableDropIndex = [self keyInQueryTableDropIndex];
	
	NSString *keyPathDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
	NSString *keyPathFieldName = [self keyFieldName];
	NSString *keyPathTableName = [self keyTableName];
	NSString *keyPathSchemaTable = [self keySchemaTable];
	NSString *keyQueryTableID = [self keyQueryTableID],
			 *keyQueryFieldID = [self keyQueryFieldID],
			 *keySchemaTableID = [self keySchemaTableID],
			 *keySchemaFieldID = [self keySchemaFieldID],
			 *keyQueryTableAlias = [self keyInQueryTableAlias],
			 *keySchemaFieldDataType = [self keySchemaFieldDataType];
	NSString *keySelf = NSStringFromSelector(@selector(self));
	NSUInteger expressionCount = 13;
	NSExpressionDescription *expressionDescription[expressionCount];
	NSString *keys[] = {
		keySelf,
		keyPathInQueryTable,
		keyPathFieldName,
		keyPathTableName,
		keyPathSchemaTable,
		keyPathDatabaseSchemaField,
		
		keyQueryTableID,
		keyQueryFieldID,
		keySchemaTableID,
		keySchemaFieldID,
		keyPathInQueryTableDropIndex,
		keyQueryTableAlias,
		keySchemaFieldDataType
	};
	
	NSExpression *expressions[] = {
		[NSExpression expressionForEvaluatedObject],
		[NSExpression expressionForKeyPath: keyPathInQueryTable],
		[NSExpression expressionForKeyPath: keyPathFieldName],
		[NSExpression expressionForKeyPath: keyPathTableName],
		[NSExpression expressionForKeyPath: keyPathSchemaTable],
		[NSExpression expressionForKeyPath: keyPathDatabaseSchemaField],
		
		[NSExpression expressionForKeyPath: keyQueryTableID],
		[NSExpression expressionForKeyPath: keyQueryFieldID],
		[NSExpression expressionForKeyPath: keySchemaTableID],
		[NSExpression expressionForKeyPath: keySchemaFieldID],
		[NSExpression expressionForKeyPath: keyPathInQueryTableDropIndex],
		[NSExpression expressionForKeyPath: keyQueryTableAlias],
		[NSExpression expressionForKeyPath: keySchemaFieldDataType]
	};

	NSAttributeType types[] = {
		NSObjectIDAttributeType,
		NSObjectIDAttributeType,
		NSStringAttributeType,
		NSStringAttributeType,
		NSObjectIDAttributeType,
		NSObjectIDAttributeType,
		
		NSInteger64AttributeType,
		NSInteger64AttributeType,
		NSInteger64AttributeType,
		NSInteger64AttributeType,
		NSInteger64AttributeType,
		NSStringAttributeType,
		NSInteger16AttributeType,
	};
	
	for (NSUInteger i=0; i<expressionCount; i++) {
		expressionDescription[i] = [[NSExpressionDescription alloc] init];
		expressionDescription[i].name = keys[i].copy;
		expressionDescription[i].expression = expressions[i];
		expressionDescription[i].expressionResultType = types[i];
	}

	NSArray *propertiesToFetch;
	propertiesToFetch = [[NSArray alloc] initWithObjects: expressionDescription
												   count: (NSUInteger)expressionCount];
	
	fetchQueryTable.propertiesToFetch = propertiesToFetch;
	fetchQueryTable.resultType = NSDictionaryResultType;
	fetchQueryTable.predicate = predicate;
	
	for (NSUInteger i=0; i<expressionInQueryCount; i++) {
		pexpressions[i] = nil;
	}

	for (NSUInteger i=0; i<expressionCount; i++) {
		expressionDescription[i] = nil;
		keys[i] = nil;
		expressions[i] = nil;
	}
	return fetchQueryTable;
}

+ (NSFetchRequest *)fetchRequestFieldKeys:(int64_t)identifier {
	
	NSUInteger expressionInQueryCount = 2;

	NSExpression *pexpressions[expressionInQueryCount];
	NSString *predicateKey;
	NSNumber *idn = @(identifier);
	NSString *keyInQueryTable = [self keyInQueryTable];
	predicateKey = [MADStringUtilities stringByAppendingPeriodToString: keyInQueryTable];
	predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(inQuery))];
	predicateKey = [MADStringUtilities stringByAppendingPeriodToString: predicateKey];
	predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(identifier))];
	
	pexpressions[0] = [NSExpression expressionForKeyPath:predicateKey];
	pexpressions[1] = [NSExpression expressionForConstantValue: idn];
	
	NSPredicate *predicate;
	predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
												   rightExpression: pexpressions[1]
														  modifier: NSDirectPredicateModifier
															  type: NSEqualToPredicateOperatorType
														   options: 0];

	
	NSString *entityName;
	NSFetchRequest *fetchQueryTable;
	
	entityName = NSStringFromClass([RptqQueryField class]);
	fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:entityName];
	
	NSString *keyPathInQueryTable = [self keyInQueryTable],
			 *keyPathInQueryTableDropIndex = [self keyInQueryTableDropIndex],
			 *keyPathDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField)),
			 *keyPathFieldName = [self keyFieldName],
			 *keyPathTableName = [self keyTableName],
			 *keyPathSchemaTable = [self keySchemaTable],
			 *keyQueryTableID = [self keyQueryTableID],
			 *keyQueryFieldID = [self keyQueryFieldID],
			 *keySchemaTableID = [self keySchemaTableID],
			 *keySchemaFieldID = [self keySchemaFieldID],
			 *keySelf = NSStringFromSelector(@selector(self));
	NSUInteger expressionCount = 11;
	NSExpressionDescription *expressionDescription[expressionCount];
	
	NSString *keys[] = {
		keySelf,
		keyPathInQueryTable,
		keyPathFieldName,
		keyPathTableName,
		keyPathSchemaTable,
		keyPathDatabaseSchemaField,
		
		keyQueryTableID,
		keyQueryFieldID,
		keySchemaTableID,
		keySchemaFieldID,
		keyPathInQueryTableDropIndex
	};
	
	NSExpression *expressions[] = {
		[NSExpression expressionForEvaluatedObject],
		[NSExpression expressionForKeyPath: keyPathInQueryTable],
		[NSExpression expressionForKeyPath: keyPathFieldName],
		[NSExpression expressionForKeyPath: keyPathTableName],
		[NSExpression expressionForKeyPath: keyPathSchemaTable],
		[NSExpression expressionForKeyPath: keyPathDatabaseSchemaField],
		
		[NSExpression expressionForKeyPath: keyQueryTableID],
		[NSExpression expressionForKeyPath: keyQueryFieldID],
		[NSExpression expressionForKeyPath: keySchemaTableID],
		[NSExpression expressionForKeyPath: keySchemaFieldID],
		[NSExpression expressionForKeyPath: keyPathInQueryTableDropIndex],
	};

	NSAttributeType types[] = {
		NSObjectIDAttributeType,
		NSObjectIDAttributeType,
		NSStringAttributeType,
		NSStringAttributeType,
		NSObjectIDAttributeType,
		NSObjectIDAttributeType,
		
		NSInteger64AttributeType,
		NSInteger64AttributeType,
		NSInteger64AttributeType,
		NSInteger64AttributeType,
		NSInteger64AttributeType,
	};
	
	for (NSUInteger i=0; i<expressionCount; i++) {
		expressionDescription[i] = [[NSExpressionDescription alloc] init];
		expressionDescription[i].name = keys[i].copy;
		expressionDescription[i].expression = expressions[i];
		expressionDescription[i].expressionResultType = types[i];

	}

	NSArray *propertiesToFetch;
	propertiesToFetch = [[NSArray alloc] initWithObjects: expressionDescription
												   count: (NSUInteger)expressionCount];
	
	fetchQueryTable.propertiesToFetch = propertiesToFetch;
	fetchQueryTable.resultType = NSDictionaryResultType;
	fetchQueryTable.predicate = predicate;
	
	for (NSUInteger i=0; i<expressionInQueryCount; i++) {
		pexpressions[i] = nil;
	}

	for (NSUInteger i=0; i<expressionCount; i++) {
		expressionDescription[i] = nil;
		keys[i] = nil;
		expressions[i] = nil;
	}
	return fetchQueryTable;
}

+ (instancetype)newQueryField:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
	NSString *entityName = NSStringFromClass([RptqQueryField class]);
	NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
											  inManagedObjectContext: managedObjectContext];
	RptqQueryField *queryField = [[RptqQueryField alloc] initWithEntity: entity
										 insertIntoManagedObjectContext: managedObjectContext];
	return queryField;
}

- (NSString *)tableFieldKey {
	return [self toString];
}

- (NSString *)display {
	return self.toStringHumanReadable.lowercaseString;
}

+ (instancetype)queryFieldForObjectID:(NSManagedObjectID *)objectId
				 managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	return (RptqQueryField *)[managedObjectContext objectWithID:objectId];
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
