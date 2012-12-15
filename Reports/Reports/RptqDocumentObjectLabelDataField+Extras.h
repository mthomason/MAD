//
//  RptqDocumentObjectLabelDataField+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/29/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentObjectLabelDataField.h"
#import "MTProtocolCompare.h"

@interface RptqDocumentObjectLabelDataField (Extras) <MTProtocolCompare>

+ (RptqDocumentObjectLabelDataField *)labelDataFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext withObjectID:(NSManagedObjectID *)objid;

@end