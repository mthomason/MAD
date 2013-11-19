//
//  RptqDocumentObjectBarcode+Extras.m
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectBarcode+Extras.h"

@implementation RptqDocumentObjectBarcode (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectBarcode class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectBarcode *lastObject = [fetchResults lastObject];
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

+ (RptqDocumentObjectBarcode *)barcodeWithMtBarcode:(MTBarcode *)barcode queryFieldOne:(RptqQueryField *)queryFieldOne queryFieldTwo:(RptqQueryField *)queryFieldTwo {
    
    RptqDocumentObjectBarcode *reportObject = nil;
    
    if (queryFieldOne != nil) {

        NSString *className = NSStringFromClass([RptqDocumentObjectBarcode class]);
        NSEntityDescription *entityDescriptionDocumentObjectSubtype = [NSEntityDescription entityForName: className
                                                                                  inManagedObjectContext: [queryFieldOne managedObjectContext]];
        
        reportObject = [[RptqDocumentObjectBarcode alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                          insertIntoManagedObjectContext: [queryFieldOne managedObjectContext]];
        
        
        NSNumber *componentEnabled = @([barcode has2dComponentEnabled]);
        NSNumber *borderStyle = @([barcode borderStyle]);
        NSNumber *borderWidth = @([barcode borderWidth]);
        NSData *colorBackground = [NSKeyedArchiver archivedDataWithRootObject:[UIColor whiteColor]];
        NSData *colorForeground = [NSKeyedArchiver archivedDataWithRootObject:[UIColor blackColor]];
        
        NSNumber *height = @([barcode height]);
        NSNumber *humanReadable = @([barcode humanReadable]);
        NSNumber *option1 = @([barcode option1]);
        NSNumber *option2 = @([barcode option2]);
        NSNumber *option3 = @([barcode option3]);
        NSNumber *showErrorMessage = @([barcode showErrorMessages]);
        NSNumber *barcodeType = @([barcode barcodeType]);
        NSNumber *whitespaceWidth = @([barcode whitespaceWidth]);
        NSNumber *useStaticInput1 = @(NO);
        NSNumber *useStaticInput2 = @(NO);
        NSNumber *scale = @([barcode scale]);
        
        [reportObject setAdd2dComponent:componentEnabled];
        [reportObject setBorderStyle:borderStyle];
        [reportObject setBorderWidth:borderWidth];
        [reportObject setColorBackground:colorBackground];
        [reportObject setColorForeground:colorForeground];
        [reportObject setHeight:height];
        [reportObject setHumanReadable:humanReadable];
        [reportObject setReferencesField1: queryFieldOne];
        [reportObject setReferencesField2: queryFieldTwo];
        [reportObject setOption1: option1];
        [reportObject setOption2: option2];
        [reportObject setOption3: option3];
        [reportObject setShowErrorMessage: showErrorMessage];
        [reportObject setType:barcodeType];
        [reportObject setWhitespaceWidth:whitespaceWidth];
        [reportObject setUseStaticInput1:useStaticInput1];
        [reportObject setUseStaticInput2:useStaticInput2];
        [reportObject setScale:scale];

    }
    
    
    return [reportObject autorelease];
}

@end
