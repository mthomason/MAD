//
//  RptqDocumentElementFormula+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/18/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqDocumentElementFormula+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDocument.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSectionRows.h"

#import "RptqDataHelper.h"

@implementation RptqDocumentElementFormula (Extras)

- (NSString *)designerRepresentationText {
    return self.source;
}

#pragma mark - RptqDocumentElementFactory

+ (RptqDocumentElement *)addDocumentObject:(NSDictionary *)documentObjectDefination
                                toDocument:(RptqDocument *)document {

    NSManagedObjectContext *managedObjectContext = document.managedObjectContext;
    
    NSEntityDescription *edFormula;
    edFormula = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentElementFormula class])
                            inManagedObjectContext: managedObjectContext];
    
    NSString *formulaText = documentObjectDefination[MTDocumentObjectDefinationObject];
    
    RptqDocumentElementFormula *element;
    element = [[RptqDocumentElementFormula alloc] initWithEntity: edFormula
                                  insertIntoManagedObjectContext: managedObjectContext];
    
    element.source = formulaText;
    element.type = MADPrintPageElementTypeFormula;
    
    NSMutableOrderedSet <RptqDocumentElement *> *hasObjects;
    hasObjects = [document.hasDetailSection.hasRows[0] hasObjects].mutableCopy;
    [hasObjects insertObject:element atIndex:0];
    [document.hasDetailSection.hasRows[0] setHasObjects:hasObjects];
    
    return element;
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return self.name;
}

- (NSString *)toString {
    return [self toStringHumanReadable];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:             %lld\n",    self.identifier];
    [description appendFormat:@"Name:                   %@\n",      self.name];
    [description appendFormat:@"Source:                 %@\n",      self.source];
    [description appendFormat:@"Result type:            %hd\n",     self.resultType];
    [description appendFormat:@"Function scope:         %hd\n",     self.functionScope];
    [description appendFormat:@"Function type:          %hd\n",     self.functionType];
    [description appendFormat:@"Input type:             %hd\n",     self.inputType];
    [description appendFormat:@"*********"];
    return description;
}

@end
