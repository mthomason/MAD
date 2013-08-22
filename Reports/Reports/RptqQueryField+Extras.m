//
//  RptqQueryField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryField+Extras.h"

@implementation RptqQueryField (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(identifier))
                                                                     ascending: NO];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryField class])];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    
    if (error == nil) {
        RptqQueryField *lastObject = [fetchResults lastObject];
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

+ (RptqQueryField *)createNewQueryFieldForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSString *entityName = NSStringFromClass([RptqQueryField class]);
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: entityName inManagedObjectContext: managedObjectContext];
    RptqQueryField *queryField = [[RptqQueryField alloc] initWithEntity:entityDescription insertIntoManagedObjectContext: managedObjectContext];
    return [queryField autorelease];
}

- (NSString *)tableFieldKey {
    return [self toString];
//    return [[self toString] lowercaseString];
}

- (NSString *)display {
    return [[self toStringHumanReadable] lowercaseString];
}

+ (id)getQueryFieldForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectId];
    return result;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [NSString stringWithFormat:@"%@.%@", [[self inQueryTable] alias], [[self databaseSchemaField] name]];
}

- (NSString *)toStringReverse {
    return [NSString stringWithFormat:@"%@.%@", [[self databaseSchemaField] name], [[self inQueryTable] alias]];
}

- (NSString *)toString {
    return [NSString stringWithFormat:@"%@.%@", [[self inQueryTable] queryAlias], [[self databaseSchemaField] name]];
//    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqQueryField *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
