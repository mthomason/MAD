//
//  RptqQueryLinks+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryLinks+Extras.h"
#import "AppDelegate.h"
#import "RptqDocument+ActiveDocument.h"

@implementation RptqQueryLinks (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryLinks class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqQueryLinks *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    [self setDesignerOriginX:@(0.0000f)];
    [self setDesignerOriginY:@(0.0000f)];
    [self setDesignerSizeHeight:@(0.0000f)];
    [self setDesignerSizeWidth:@(0.0000f)];
    [self setDesignerInitalLayout:@(YES)];
    
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

+ (NSArray *)queriesForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqQuery *query = [RptqDocument queryForManagedObjectContext:managedObjectContext];
    NSSet *queryLinks = [query hasQueryLinks];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"identifier" ascending: YES];
    NSArray *results = [[queryLinks sortedArrayUsingDescriptors:@[sortDescriptor]] retain];
    return [results autorelease];
}

+ (id)getQueryLinkWithID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectId];
    return result;
}

+ (void)deleteLinkWithID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqQueryLinks *link = [RptqQueryLinks getQueryLinkWithID:objid fromObjectContext:managedObjectContext];
    if (link) {
        [managedObjectContext deleteObject: link];
    }
}

+ (id)createQueryLinkWithLeftField:(RptqQueryField *)fieldLeft
                         rightField:(RptqQueryField *)fieldRight
                           andJoinType:(MNSLinkType)joinType {
    NSEntityDescription *rqtEd = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryLinks class]) inManagedObjectContext:[[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
    
    RptqQueryLinks *queryLinks = [[RptqQueryLinks alloc] initWithEntity: rqtEd
                                         insertIntoManagedObjectContext: [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext]];
    
    [queryLinks setHasLeftField:    fieldLeft];
    [queryLinks setHasRightField:   fieldRight];
    
    [queryLinks setTableleft:       [[fieldLeft inQueryTable] alias]];
    [queryLinks setFieldleft:       [[fieldLeft databaseSchemaField] name]];
    [queryLinks setTableright:      [[fieldRight inQueryTable] alias]];
    [queryLinks setFieldright:      [[fieldRight databaseSchemaField] name]];
    [queryLinks setJointype:        [MNSLinkTypeReuseIds objectAtIndex: joinType]];
    [queryLinks setJointypeenum:    [NSNumber numberWithInteger: joinType]];

    return [queryLinks autorelease];
}

+ (void)insertQueryLink:(RptqQueryLinks *)queryLink intoManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    [[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] addHasQueryLinks: [NSSet setWithObject: queryLink]];
}

- (NSString *)linkDescription {
    NSString *linkDescription;

    // FIXME: Should display the correct algebraic glyphs.
//    switch ([[self jointype] integerValue]) {

//        case MNSLinkTypeLeftOuterJoin:
            linkDescription = [NSString stringWithFormat:@"%@", [MNSLinkTypeNames objectAtIndex: [[self jointypeenum] integerValue]]];
//            break;
            
//        default:
//            linkDescription = [NSString stringWithFormat:@"%@ (%@)",
//                               [MNSLinkTypeSymbols objectAtIndex: [[self jointypeenum] integerValue]],
//                               [MNSLinkTypeNames objectAtIndex: [[self jointypeenum] integerValue]]];
//            break;
//    }
    
    return linkDescription;
}

// MARK: MTProtocolLog

- (NSString *)toStringHumanReadable {
    NSMutableString *result = [[NSMutableString alloc] initWithString:[[[self hasLeftField] databaseSchemaField] name]];
    [result appendFormat:@" %@ ", [self linkDescription]];
    [result appendString:[[[self hasRightField] databaseSchemaField] name]];
    return [result autorelease];
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [self toStringHumanReadable];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqQueryLinks *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end