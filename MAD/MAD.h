//
//  MAD.h
//  MAD
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>

FOUNDATION_EXPORT double MADVersionNumber;
FOUNDATION_EXPORT const unsigned char MADVersionString[];

#import <MAD/MADocument.h>
#import <MAD/MADActivityProtocol.h>
#import <MAD/MADActivityItemProviderDelegate.h>

#import <MAD/MADDataFormatter.h>

#import <MAD/MADSectionLayoutAttributes.h>
#import <MAD/MADSectionsLayout.h>

#import <MAD/MTPaper.h>
#import <MAD/MADPrintPageRenderer.h>
#import <MAD/MADReportFormatter.h>

#import <MAD/MADDatabase+Constructor.h>
#import <MAD/MADDatabaseConnection+Constructor.h>
#import <MAD/MADDataTable+Constructor.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+Extras.h>

#import <MAD/MADReportSectionRepresentation.h>

#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>

#import <MAD/RptqDocumentElementFactory.h>

#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+Extras.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryGroup+Extras.h>

#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryLinks+Extras.h>

#import <MAD/RptqQueryPredicate.h>
#import <MAD/RptqQueryPredicate+Extras.h>

#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>

#import <MAD/RptqQuerySort.h>

#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>

#import <MAD/RptqDocumentElementAggregate.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>

#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>

#import <MAD/RptqDocumentElementChart.h>

#import <MAD/RptqDocumentElementFormula.h>
#import <MAD/RptqDocumentElementFormula+Extras.h>

#import <MAD/RptqDocumentElementGroupKey.h>

#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqDocumentElementImage+Extras.h>

#import <MAD/RptqDocumentElementLabel.h>
#import <MAD/RptqDocumentElementLabel+Extras.h>

#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementLabelDataField+Extras.h>

#import <MAD/RptqDocumentElementLabelLink.h>
#import <MAD/RptqDocumentElementLabelLink+Extras.h>

#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+Extras.h>

#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/RptqDocumentSectionRows+Extras.h>

#import <MAD/RptqDatabaseCredentals.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>

#import <MAD/MADSchemaFieldSelectorModel.h>
#import <MAD/MADQuery+Extras.h>

#import <MAD/MADStoreSchema.h>
#import <MAD/MADStoreObject.h>
#import <MAD/MADStoreGraph.h>
#import <MAD/MADStore.h>
