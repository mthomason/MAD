//
//  RptqDocumentObjectLabelDataField+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectLabelDataField+Extras.h"

@implementation RptqDocumentObjectLabelDataField (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectLabelDataField class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectLabelDataField *lastObject = [fetchResults lastObject];
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


+ (id)getLabelDataFieldForObjectID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectLabelDataField class])];
    request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objid];
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    RptqDocumentObjectLabelDataField *result = nil;
    if (results) result = [results lastObject];
    return result;
}

+ (RptqDocumentObject *)addNewLabelDataFeildForField:(RptqField *)field toDetailSectionOfDocument:(RptqDocument *)document withManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *entityDescriptionDocumentObject = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObject class])
                                                                       inManagedObjectContext: managedObjectContext];
    NSEntityDescription *entityDescriptionDocumentObjectLabelDataField = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentObjectLabelDataField class])
                                                                                     inManagedObjectContext: managedObjectContext];
    
    RptqDocumentObject *dataObject = [[RptqDocumentObject alloc] initWithEntity: entityDescriptionDocumentObject
                                                 insertIntoManagedObjectContext: managedObjectContext];
    
    
    RptqDocumentObjectLabelDataField *reportObject = [[RptqDocumentObjectLabelDataField alloc] initWithEntity: entityDescriptionDocumentObjectLabelDataField
                                                                               insertIntoManagedObjectContext: managedObjectContext];

    dataObject.isLabelDataField = reportObject;
    
    dataObject.isLabelDataField.text = [NSString stringWithFormat:@"%@.%@", [[field inTable] name], [field name]];
    dataObject.isLabelDataField.referencesField = field;
    dataObject.originx = @(CGPointZero.x);
    dataObject.originy = @(CGPointZero.y);
    dataObject.sizewidth = @(200.0000f);
    dataObject.sizeheight = @(44.0000f);
    dataObject.type = @(MNSObjectTypeLabelDataField);
    
    reportObject.referencesField = field;
    //dataObject.isLabelDataField = reportObject;
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:[[document hasDetailSection] hasObjects]];
    [hasObjects insertObject:dataObject atIndex:0];
    [[document hasDetailSection] setHasObjects:hasObjects];
    //RptqDocumentSection *detailSection = [document hasDetailSection];
    //[detailSection addHasObjectsObjectFixed:dataObject];
    [reportObject release];
    return [dataObject autorelease];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqDocumentObjectLabelDataField *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end