//
//  RptqField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqField+Extras.h"

@implementation RptqField (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqField class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqField *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
    switch (flag) {
        case NSSnapshotEventMergePolicy:
            break;
        case NSSnapshotEventRefresh:
            break;
        case NSSnapshotEventRollback:
            break;
        case NSSnapshotEventUndoDeletion:
            break;
        case NSSnapshotEventUndoInsertion:
            break;
        case NSSnapshotEventUndoUpdate:
            break;
        default:
            break;
    }
}

#pragma mark - Static

+ (RptqField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                               label:(NSString *)label name:(NSString *)name
                                         andDatatype:(NSString *)dataType {
    NSEntityDescription *fieldEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqField class]) inManagedObjectContext: objectContext];
    RptqField *rptqField = [[RptqField alloc] initWithEntity: fieldEntity
                              insertIntoManagedObjectContext: objectContext];
    [rptqField setLabel:    label];
    [rptqField setName:     name];
    [rptqField setDatatype: dataType];
    return [rptqField autorelease];
}

+ (RptqField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andField:(MTDatabaseField *)field {
    NSEntityDescription *fieldEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqField class]) inManagedObjectContext: objectContext];
    RptqField *rptqField = [[RptqField alloc] initWithEntity: fieldEntity
                              insertIntoManagedObjectContext: objectContext];
    [rptqField setLabel:    [field label]];
    [rptqField setName:     [field name]];
    [rptqField setDatatype: [field datatype]];
    return [rptqField autorelease];
}

- (NSString *)display {
    return [[NSString stringWithFormat:@"%@.%@", [[self inTable] name], [self name]] lowercaseString];
}

/*
+ (void)addFieldToQueryForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
}

+ (void)removeFieldFromQueryInManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
}
*/

// MARK: MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [NSString stringWithFormat:@"%@.%@", [[self inTable] name], [self name]];
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [self toStringHumanReadable];
}

+ (id)getFieldForObjectID:(NSManagedObjectID *)objectID fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqField class])];
    request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objectID];
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    RptqField *result = nil;
    if (results) result = [results lastObject];
    return result;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqField *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end