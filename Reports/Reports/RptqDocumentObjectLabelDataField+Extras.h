//
//  RptqDocumentObjectLabelDataField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectLabelDataField.h"
#import "MTProtocolCompare.h"
#import "RptqDocument.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqField.h"
#import "RptqDocumentSection+Extras.h"

@interface RptqDocumentObjectLabelDataField (Extras) <MTProtocolCompare>

+ (id)getLabelDataFieldForObjectID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc;
+ (RptqDocumentObject *)addNewLabelDataFeildForField:(RptqField *)field toDetailSectionOfDocument:(RptqDocument *)document withManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
