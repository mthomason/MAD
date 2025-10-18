//
//  RptqDocumentSectionRows+CoreDataClass.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDocumentSectionRows.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentSection.h"
@implementation RptqDocumentSectionRows

@end

@implementation RptqDocumentSectionRows (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentSectionRows *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"RptqDocumentSectionRows"];
}

@dynamic layoutHeight;
@dynamic rowNumber;
@dynamic hasObjects;
@dynamic inSection;

@end
