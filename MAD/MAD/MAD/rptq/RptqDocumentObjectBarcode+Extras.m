//
//  RptqDocumentObjectBarcode+Extras.m
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentObjectBarcode+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryField+Extras.h"
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

@implementation RptqDocumentObjectBarcode (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObjectBarcode class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectBarcode *lastObject = [fetchResults lastObject];
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
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

- (void)updateWithBarcode:(MTBarcode *)barcode fieldOne:(RptqQueryField *)fieldOne fieldTwo:(RptqQueryField *)fieldTwo {

    [self setAdd2dComponent:    @([barcode has2dComponent])];
    [self setBorderStyle:       @([barcode borderStyle])];
    self.borderWidth =        @([barcode borderWidth]);
    [self setType:              @([barcode barcodeType])];
    [self setHeight:            @([barcode height])];
    [self setHumanReadable:     @([barcode humanReadable])];
    [self setOption1:           @([barcode option1])];
    [self setOption2:           @([barcode option2])];
    [self setOption3:           @([barcode option3])];
    [self setShowErrorMessage:  @([barcode showErrorMessages])];
    [self setWhitespaceWidth:   @([barcode whitespaceWidth])];
    [self setScale:             @([barcode scale])];
    [self setReferencesField1:  fieldOne];
    [self setReferencesField2:  fieldTwo];
    [[self managedObjectContext] save:nil];
}

+ (MTBarcode *)barcodeWithDocumentObject:(RptqDocumentObjectBarcode *)documentObject {
    
    MTBarcodeType type = documentObject.type.unsignedIntegerValue;
    MTBarcode *barcode = [MTBarcode newBarcodeWithType:type];

    barcode.has2dComponentEnabled =     documentObject.add2dComponent.boolValue;
    barcode.borderStyle =               documentObject.borderStyle.unsignedCharValue;
    barcode.borderWidth =               documentObject.borderWidth.integerValue;
    barcode.height =                    documentObject.height.integerValue;
    barcode.humanReadable =             documentObject.humanReadable.boolValue;
    barcode.option1 =                   documentObject.option1.integerValue;
    barcode.option2 =                   documentObject.option2.integerValue;
    barcode.option3 =                   documentObject.option3.integerValue;
    barcode.showErrorMessages =         documentObject.showErrorMessage.boolValue;
    barcode.whitespaceWidth =           documentObject.whitespaceWidth.boolValue;
    barcode.scale =                     documentObject.scale.floatValue;
    barcode.input =                     @"Sample data";
    barcode.primaryData =               @"";
    return barcode;
}

+ (instancetype)barcodeWithMtBarcode:(MTBarcode *)barcode queryFieldOne:(RptqQueryField *)queryFieldOne queryFieldTwo:(RptqQueryField *)queryFieldTwo NS_RETURNS_RETAINED {
    
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
        reportObject.borderWidth = borderWidth;
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
    
    return reportObject;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Encoded text:           %@\n", self.humanReadable];
    [description appendFormat:@"*********"];
    return description;
}

@end
