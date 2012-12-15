//
//  RptqQueryLinks+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryLinks+Extras.h"

@implementation RptqQueryLinks (Extras)

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
    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

+ (id)queryLinkWithID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc {
    RptqQueryLinks *result = nil;
    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: moc] retain];
    if (doc) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryLinks class])];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"tableleft" ascending:YES];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objid];
        NSError *error = nil;
        NSArray *results = [[moc executeFetchRequest:request error:&error] retain];
        if ([results count] == 1) {
            result = [[[results objectAtIndex: 0] retain] autorelease];
        } else if ([results count] > 1) {
            for (RptqQueryLinks *link in results) {
                result = [[link retain] autorelease];
                break;
            }
        } else {
            NSLog(@"Could not find item to delete.  This is a bug.  :(");
        }
        [results release];                            
        
    }
    [doc release];
    return result;
}

+ (void)deleteLinkWithID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc {
    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: moc] retain];
    if (doc) {
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryLinks class])];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"tableleft" ascending:YES];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objid];
        NSError *error = nil;
        NSArray *results = [[moc executeFetchRequest:request error:&error] retain];
        if ([results count] == 1) {
            [moc deleteObject:[results objectAtIndex: 0]];
        } else if ([results count] > 1) {
            for (RptqQueryLinks *link in results) {
                if (link) {
                    [moc deleteObject: link];
                }
            }
        } else {
            NSLog(@"Could not find item to delete.  This is a bug.  :(");
        }
        [results release];                            
        
    }
    [doc release];
}

+ (id)createQueryLinkWithLeftField:(RptqField *)fieldLeft
                         rightField:(RptqField *)fieldRight
                           andJoinType:(MNSLinkType)joinType {
    NSEntityDescription *rqtEd = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryLinks class]) inManagedObjectContext:[[UIManagedDocumentReport activeDocument] managedObjectContext]];
    
    RptqQueryLinks *queryLinks = [[RptqQueryLinks alloc] initWithEntity: rqtEd
                                         insertIntoManagedObjectContext: [[UIManagedDocumentReport activeDocument] managedObjectContext]];
    
    [queryLinks setHasLeftField:    fieldLeft];
    [queryLinks setHasRightField:   fieldRight];
    
    [queryLinks setTableleft:       [[fieldLeft inTable] name]];
    [queryLinks setFieldleft:       [fieldLeft name]];
    [queryLinks setTableright:      [[fieldRight inTable] name]];
    [queryLinks setFieldright:      [fieldRight name]];
    [queryLinks setJointype:        [MNSLinkTypeReuseIds objectAtIndex: joinType]];
    [queryLinks setJointypeenum:    [NSNumber numberWithInteger: joinType]];

    return [queryLinks autorelease];
}

+ (void)insertQueryLink:(RptqQueryLinks *)queryLink intoManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    [[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] addHasQueryLinks: [NSSet setWithObject: queryLink]];
}

- (NSString *)linkDescription {
    return [NSString stringWithFormat:@"%@ (%@)",
            [MNSLinkTypeSymbols objectAtIndex: [[self jointypeenum] integerValue]],
            [MNSLinkTypeNames objectAtIndex: [[self jointypeenum] integerValue]]];
}

// MARK: MTProtocolLog

- (NSString *)humanReadableObjectIdentifier {
    NSMutableString *result = [[NSMutableString alloc] initWithString:[[self hasLeftField] name]];
    [result appendFormat:@" %@ ", [self linkDescription]];
    [result appendString:[[self hasRightField] name]];
    return [result autorelease];
}

- (NSString *)toString {
    return [self humanReadableObjectIdentifier];
}

- (NSString *)toStringForDebugging {
    return [self humanReadableObjectIdentifier];
}

@end