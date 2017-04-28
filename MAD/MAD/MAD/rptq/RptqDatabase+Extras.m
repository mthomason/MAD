//
//  RptqDatabase+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDatabase+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSExpressionDescription.h>

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseCredentals.h"

#import "RptqDataHelper.h"

@implementation RptqDatabase (Extras)

#pragma mark -
#pragma mark Static

+ (NSString *)keyDriverID {
    NSString *keyDriverID = NSStringFromSelector(@selector(driverID));
    return keyDriverID;
}

+ (NSString *)keyOwnedByUser {
    NSString *keyOwnedByUser = NSStringFromSelector(@selector(ownedByUser));
    return keyOwnedByUser;
}

+ (NSString *)keyOwnedByUserDriverID {
    NSString *keyOwnedByUser = [self keyOwnedByUser];
    NSString *keyDriverID = [self keyDriverID];
    NSString *keyOwndByUserDriverID = [keyOwnedByUser stringByAppendingString:@"."];
    keyOwndByUserDriverID = [keyOwndByUserDriverID stringByAppendingString:keyDriverID];
    return keyOwndByUserDriverID;
}

+ (NSString *)keyOwnedByUserDatabaseName {
    NSString *keyOwnedByUser = [self keyOwnedByUser];
    NSString *keyDatabaseName = NSStringFromSelector(@selector(dbname));
    NSString *keyOwndByUserDBName = [keyOwnedByUser stringByAppendingString:@"."];
    keyOwndByUserDBName = [keyOwndByUserDBName stringByAppendingString:keyDatabaseName];
    return keyOwndByUserDBName;
}

+ (NSString *)keyDatabaseDriverType {
    NSString *keyDatabaseDriverType = NSStringFromSelector(@selector(databaseDriverTypeEnum));
    return keyDatabaseDriverType;
}

+ (NSFetchRequest *)fetchRequestDatabaseDriverID:(int64_t)identifier {
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    NSString *keyOwndByUserDriverID = [self keyOwnedByUserDriverID];
    NSNumber *idn = @(identifier);
    
    NSExpression *predicateExpression[2];
    predicateExpression[0] = [NSExpression expressionForKeyPath: keyIdentifier];
    predicateExpression[1] = [NSExpression expressionForConstantValue: idn];
    
    NSPredicate *predicate;
    predicate = [NSComparisonPredicate predicateWithLeftExpression: predicateExpression[0]
                                                   rightExpression: predicateExpression[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    
    NSFetchRequest *fetchRequest;
    NSString *entityName = NSStringFromClass([RptqDatabase class]);
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSUInteger expressionCount = 1;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSExpression *expressionForDatabaseDriverType = [NSExpression expressionForKeyPath:keyOwndByUserDriverID];
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    expressionDescription[0].name = keyOwndByUserDriverID;
    expressionDescription[0].expression = expressionForDatabaseDriverType;
    expressionDescription[0].expressionResultType = NSStringAttributeType;
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription
                                                   count:expressionCount];
    fetchRequest.propertiesToFetch = propertiesToFetch;
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.predicate = predicate;
    
    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestDatabaseName:(int64_t)identifier {
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    NSString *keyOwndByUserDBName = [self keyOwnedByUserDatabaseName];
    NSNumber *idn = @(identifier);
    
    NSExpression *predicateExpression[2];
    predicateExpression[0] = [NSExpression expressionForKeyPath: keyIdentifier];
    predicateExpression[1] = [NSExpression expressionForConstantValue: idn];
    
    NSPredicate *predicate;
    predicate = [NSComparisonPredicate predicateWithLeftExpression: predicateExpression[0]
                                                   rightExpression: predicateExpression[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    
    NSFetchRequest *fetchRequest;
    NSString *entityName = NSStringFromClass([RptqDatabase class]);
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSUInteger expressionCount = 1;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSExpression *expressionForDatabaseDriverType = [NSExpression expressionForKeyPath:keyOwndByUserDBName];
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    expressionDescription[0].name = keyOwndByUserDBName;
    expressionDescription[0].expression = expressionForDatabaseDriverType;
    expressionDescription[0].expressionResultType = NSStringAttributeType;
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription
                                                   count:expressionCount];
    fetchRequest.propertiesToFetch = propertiesToFetch;
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.predicate = predicate;
    
    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestDriverName:(int64_t)identifier {
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    NSString *key = [self keyOwnedByUserDatabaseName];
    NSNumber *idn = @(identifier);
    
    NSExpression *predicateExpression[2];
    predicateExpression[0] = [NSExpression expressionForKeyPath: keyIdentifier];
    predicateExpression[1] = [NSExpression expressionForConstantValue: idn];
    
    NSPredicate *predicate;
    predicate = [NSComparisonPredicate predicateWithLeftExpression: predicateExpression[0]
                                                   rightExpression: predicateExpression[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    
    NSFetchRequest *fetchRequest;
    NSString *entityName = NSStringFromClass([RptqDatabase class]);
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSUInteger expressionCount = 1;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSExpression *expressionForDatabaseDriverType = [NSExpression expressionForKeyPath:key];
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    expressionDescription[0].name = key;
    expressionDescription[0].expression = expressionForDatabaseDriverType;
    expressionDescription[0].expressionResultType = NSStringAttributeType;
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription
                                                   count:expressionCount];
    fetchRequest.propertiesToFetch = propertiesToFetch;
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.predicate = predicate;

    return fetchRequest;
}

+ (NSFetchRequest *)fetchRequestDriverType:(int64_t)identifier {
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    NSString *keyDatabaseDriverTypeEnum = [self keyDatabaseDriverType];
    
    NSExpression *predicateExpression[2];
    predicateExpression[0] = [NSExpression expressionForKeyPath: keyIdentifier];
    NSNumber *idn = @(identifier);
    predicateExpression[1] = [NSExpression expressionForConstantValue: idn];
    
    NSPredicate *predicate;
    predicate = [NSComparisonPredicate predicateWithLeftExpression: predicateExpression[0]
                                                   rightExpression: predicateExpression[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    
    NSFetchRequest *fetchRequest;
    NSString *entityName = NSStringFromClass([RptqDatabase class]);
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSUInteger expressionCount = 1;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSExpression *expressionForDatabaseDriverType = [NSExpression expressionForKeyPath:keyDatabaseDriverTypeEnum];
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    expressionDescription[0].name = keyDatabaseDriverTypeEnum;
    expressionDescription[0].expression = expressionForDatabaseDriverType;
    expressionDescription[0].expressionResultType = NSInteger16AttributeType;
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription
                                                   count:expressionCount];
    fetchRequest.propertiesToFetch = propertiesToFetch;
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.predicate = predicate;
    return fetchRequest;
}

+ (RptqDatabase *)databaseForDocument:(RptqDocument *)document
                      andConnecitonId:(int64_t)connectionId {
    
    RptqDatabase *currentDatabase = nil;
    for (RptqDatabase *db in document.hasDatabaseSchemas) {
        if (db.identifier == connectionId) {
            currentDatabase = db;
            break;
        }
    }

    return currentDatabase;
}

+ (instancetype)newDatabaseFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                               driverType:(NSString *)driverIdentifier
                                             connectionId:(int64_t)identifier NS_RETURNS_RETAINED {

    NSString *entityName = NSStringFromClass([self class]);
    NSEntityDescription *databaseEntity = [NSEntityDescription entityForName: entityName
                                                      inManagedObjectContext: objectContext];
    
    RptqDatabase *database = [[self alloc] initWithEntity: databaseEntity
                           insertIntoManagedObjectContext: objectContext];

    NSString *databaseDriverType = [[NSString alloc] initWithString: driverIdentifier];
    database.databaseDriverType = databaseDriverType;
    
    database.identifier = identifier;
    
    return database;
}

#pragma mark -
#pragma mark Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                        managedObjectContext:self.managedObjectContext];
}

- (RptqQuery *)defaultQuery { return self.hasQueries.anyObject; }

- (RptqDatabaseSchemaTable *)getTableWithName:(NSString *)name {
    RptqDatabaseSchemaTable *result = nil;
    for (RptqDatabaseSchemaTable *table in self.hasTables) {
        if ([table.name isEqualToString:name]) {
            result = table;
            break;
        }
    }
    return result;
}

- (MADDatabaseType)databaseType {
    return self.databaseDriverTypeEnum;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Driver type:        %@\n", self.databaseDriverType];
    [description appendFormat:@"Driver type id:     %hd\n", self.databaseDriverTypeEnum];
    [description appendFormat:@"Identifier:         %lld\n", self.identifier];
    [description appendFormat:@"Tables:             %@\n", self.hasTables];
    [description appendFormat:@"Queries:            %@\n", self.hasQueries];
    [description appendFormat:@"Owned by query:     %@\n", self.ownedByQueryAsStaticResource];
    [description appendFormat:@"Owned by user:      %@\n", self.ownedByUser];
    [description appendFormat:@"*********"];
    return description;
}

@end
