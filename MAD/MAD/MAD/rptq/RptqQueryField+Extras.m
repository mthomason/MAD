//
//  RptqQueryField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQueryField+Extras.h"

#if DEBUG
    #import <objc/runtime.h>
#endif

#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "NSObject+DebugDescription.h"

@implementation RptqQueryField (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(identifier))
                                                                     ascending: NO];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryField class])];
    request.sortDescriptors = @[sortDescriptor];
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    
    if (error == nil) {
        RptqQueryField *lastObject = [fetchResults lastObject];
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
    }
    NSNumber *identifierObj = @(identifier);
    self.identifier = identifierObj;
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

+ (instancetype)queryFieldFactory:(NSManagedObjectContext *)managedObjectContext {
    NSString *entityName = NSStringFromClass([RptqQueryField class]);
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: entityName inManagedObjectContext: managedObjectContext];
    RptqQueryField *queryField = [[RptqQueryField alloc] initWithEntity:entityDescription insertIntoManagedObjectContext: managedObjectContext];
    return queryField;
}

- (NSString *)tableFieldKey {
    return [self toString];
}

- (NSString *)display {
    return [[self toStringHumanReadable] lowercaseString];
}

+ (instancetype)queryFieldForObjectID:(NSManagedObjectID *)objectId managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqQueryField *)[managedObjectContext objectRegisteredForID:objectId];
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

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"***********   RptqQueryField  ***********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Schema field:           %@\n", self.databaseSchemaField];
    [description appendFormat:@"***********   RptqQueryField  ***********"];
    return description;
}

@end
