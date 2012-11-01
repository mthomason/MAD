//
//  RptqQueryLinks+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryLinks+Extras.h"

@implementation RptqQueryLinks (Extras)

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
@end