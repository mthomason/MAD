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
#import <MADBarcodes/MADBarcodes.h>

@implementation RptqDocumentObjectBarcode (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocumentObjectBarcode class])];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: queryField
                                                                   ascending: NO];
    id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentObjectBarcode *lastObject = fetchResults.lastObject;
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
    }
    self.identifier = @(identifier);
    
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

    self.add2dComponent = @(barcode.has2dComponent);
    self.borderStyle =       @(barcode.borderStyle);
    self.borderWidth =        @(barcode.borderWidth);
    self.type = @(barcode.barcodeType);
    self.height = @(barcode.height);
    self.humanReadable = @(barcode.humanReadable);
    self.option1 = @(barcode.option1);
    self.option2 = @(barcode.option2);
    self.option3 = @(barcode.option3);
    self.showErrorMessage = @(barcode.showErrorMessages);
    self.whitespaceWidth = @(barcode.whitespaceWidth);
    self.scale = @(barcode.scale);
    self.referencesField1 = fieldOne;
    self.referencesField2 = fieldTwo;
    [self.managedObjectContext save:nil];
}

+ (MTBarcode *)newBarcodeWithDocumentObject:(RptqDocumentObjectBarcode *)documentObject {
    
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
                                                                                  inManagedObjectContext: queryFieldOne.managedObjectContext];
        
        reportObject = [[RptqDocumentObjectBarcode alloc] initWithEntity: entityDescriptionDocumentObjectSubtype
                                          insertIntoManagedObjectContext: queryFieldOne.managedObjectContext];
        
        
        NSNumber *componentEnabled = @(barcode.has2dComponentEnabled);
        NSNumber *borderStyle = @(barcode.borderStyle);
        NSNumber *borderWidth = @(barcode.borderWidth);
        NSData *colorBackground = [NSKeyedArchiver archivedDataWithRootObject:[UIColor whiteColor]];
        NSData *colorForeground = [NSKeyedArchiver archivedDataWithRootObject:[UIColor blackColor]];
        
        NSNumber *height = @(barcode.height);
        NSNumber *humanReadable = @(barcode.humanReadable);
        NSNumber *option1 = @(barcode.option1);
        NSNumber *option2 = @(barcode.option2);
        NSNumber *option3 = @(barcode.option3);
        NSNumber *showErrorMessage = @(barcode.showErrorMessages);
        NSNumber *barcodeType = @(barcode.barcodeType);
        NSNumber *whitespaceWidth = @(barcode.whitespaceWidth);
        NSNumber *useStaticInput1 = @(NO);
        NSNumber *useStaticInput2 = @(NO);
        NSNumber *scale = @(barcode.scale);
        
        reportObject.add2dComponent = componentEnabled;
        reportObject.borderStyle = borderStyle;
        reportObject.borderWidth = borderWidth;
        reportObject.colorBackground = colorBackground;
        reportObject.colorForeground = colorForeground;
        reportObject.height = height;
        reportObject.humanReadable = humanReadable;
        reportObject.referencesField1 = queryFieldOne;
        reportObject.referencesField2 = queryFieldTwo;
        reportObject.option1 = option1;
        reportObject.option2 = option2;
        reportObject.option3 = option3;
        reportObject.showErrorMessage = showErrorMessage;
        reportObject.type = barcodeType;
        reportObject.whitespaceWidth = whitespaceWidth;
        reportObject.useStaticInput1 = useStaticInput1;
        reportObject.useStaticInput2 = useStaticInput2;
        reportObject.scale = scale;

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
