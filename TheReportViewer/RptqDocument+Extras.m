//
//  NSObject+RptqDocument_Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocument+Extras.h"
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqUserCredentals.h"
#import "RptqTable.h"
#import "RptqQuery.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

@implementation RptqDocument (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

+ (void)queryDatabaseFor: (NSManagedObjectContext *)objectContext
              completion: (void (^)(NSArray *results))completion {
    RptqDocument *doc = [[RptqDocument getMainDocumentForManagedObjectContext: objectContext] retain];
    if (doc) {
        if ([doc hasDatabaseSchema]) {
            NSString *driverType = [[[doc hasDatabaseSchema] database_driver_type] retain];
            if ([driverType isEqualToString: KEY_DB_TYPE_SF]) {

            } else if ([driverType isEqualToString: KEY_DB_TYPE_DB]) {
                
            } else if ([driverType isEqualToString: KEY_DB_TYPE_MYSQL]) {
                
            }
            [driverType release];
        }
    }
    [doc release];
}

+ (RptqDocument *)createMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
    
    NSError *error = nil;
    NSArray *documents = [objectContext executeFetchRequest:request error:&error];
    
    if (!error) {
        //Delete any contents of the existing object modal.
        if (documents && [documents count] > 0) {
            [documents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [objectContext deleteObject: obj];
            }];
        }
    }
    
    NSEntityDescription *ed                     = [NSEntityDescription entityForName:NSStringFromClass([RptqDocument class]) inManagedObjectContext: objectContext];
    RptqDocument *document                      = [[RptqDocument alloc] initWithEntity:ed insertIntoManagedObjectContext:objectContext];

    [document setHasReportHeaderSection:          [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    [document setHasReportFooterSection:          [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    [document setHasPageHeaderSection:            [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    [document setHasPageFooterSection:            [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    [document setHasDetailSection:                [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSection class]) inManagedObjectContext: objectContext]];
    
    document.hasReportHeaderSection.type =      [NSNumber numberWithInteger:MNSDocumentSectionTypeReportHeader];
    document.hasReportFooterSection.type =      [NSNumber numberWithInteger:MNSDocumentSectionTypeReportFooter];
    document.hasPageHeaderSection.type =        [NSNumber numberWithInteger:MNSDocumentSectionTypePageHeader];
    document.hasPageFooterSection.type =        [NSNumber numberWithInteger:MNSDocumentSectionTypePageFooter];
    document.hasDetailSection.type =            [NSNumber numberWithInteger:MNSDocumentSectionTypeBody];

    [document setHasDatabaseSchema:               [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDatabase class]) inManagedObjectContext: objectContext]];
    [document setHasQuery:                        [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqQuery class]) inManagedObjectContext: objectContext]];
    [[document hasDatabaseSchema] setOwnedByUser: [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqUserCredentals class]) inManagedObjectContext: objectContext]];

    [[document hasReportHeaderSection] setHeight:[NSNumber numberWithFloat:44.0000f]];
    [[document hasReportFooterSection] setHeight:[NSNumber numberWithFloat:44.0000f]];
    [[document hasPageHeaderSection] setHeight:[NSNumber numberWithFloat:44.0000f]];
    [[document hasPageFooterSection] setHeight:[NSNumber numberWithFloat:44.0000f]];
    [[document hasDetailSection] setHeight:[NSNumber numberWithFloat:44.0000f]];

    [[document hasReportHeaderSection] setVisibility:[NSNumber numberWithBool:YES]];
    [[document hasReportFooterSection] setVisibility:[NSNumber numberWithBool:YES]];
    [[document hasPageHeaderSection] setVisibility:[NSNumber numberWithBool:YES]];
    [[document hasPageFooterSection] setVisibility:[NSNumber numberWithBool:YES]];
    [[document hasDetailSection] setVisibility:[NSNumber numberWithBool:YES]];

    NSLog(@"Document, %@", document);
   return [document autorelease];
}

+ (RptqDocument *)getMainDocumentForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    RptqDocument *doc = nil;
    if (objectContext) {
        NSFetchRequest *docFetchRequest = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
        NSError *error = nil;
        NSArray *documents = [objectContext executeFetchRequest:docFetchRequest error:&error];
        if (!error) {
            if ([documents count] > 0) {
                doc = [documents objectAtIndex: 0];
                if (doc) {
                    [[doc retain] autorelease];
                }
            } else {
                NSLog(@"Document doesn't exist");
            }
        } else {
            NSLog(@"Error: %@, %@", [error localizedDescription], [error localizedFailureReason]);
        }
    }
    //Create the document if it does not exist.
    if (!doc) {
        doc = [[[RptqDocument createMainDocumentForManagedObjectContext:objectContext] retain] autorelease];
    }
    return doc;
}

@end