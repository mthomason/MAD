//
//  RptqDocumentObjectLabelDataField+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectLabelDataField.h"

@interface RptqDocumentObjectLabelDataField (Extras)

+ (RptqDocumentObjectLabelDataField *)labelDataFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext withObjectID:(NSManagedObjectID *)objid;

@end