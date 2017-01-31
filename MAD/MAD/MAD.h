//
//  MAD.h
//  MAD
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/NSObjCRuntime.h>

FOUNDATION_EXPORT double MADVersionNumber;
FOUNDATION_EXPORT const unsigned char MADVersionString[];

#import <MAD/MADocument.h>
#import <MAD/MADErrorUserInfo.h>
#import <MAD/MADActivityProtocol.h>

#import <MAD/MTDatabase.h>
#import <MAD/MTDatabaseTable.h>
#import <MAD/MTDatabaseField.h>

#import <MAD/MTDatabaseCache.h>
#import <MAD/MADDatabaseConnection.h>

#import <MAD/MADDataFormatter.h>

#import <MAD/MADSectionLayoutAttributes.h>

#import <MAD/MTPaper.h>
#import <MAD/MTReportViewerPrintPageRenderer.h>
#import <MAD/MTReportFormatter.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+CoreDataProperties.h>
#import <MAD/RptqDocument+Extras.h>

#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+CoreDataProperties.h>
#import <MAD/RptqDatabase+Extras.h>

#import <MAD/MADReportSectionRepresentation.h>

#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+CoreDataProperties.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaTable+CoreDataProperties.h>
#import <MAD/RptqDatabaseSchemaTable+Extras.h>

#import <MAD/RptqDocumentElementFactory.h>

#import <MAD/RptqQuery.h>
#import <MAD/RptqQuery+CoreDataProperties.h>
#import <MAD/RptqQuery+Extras.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+CoreDataProperties.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqQueryGroup.h>
#import <MAD/RptqQueryGroup+CoreDataProperties.h>
#import <MAD/RptqQueryGroup+Extras.h>

#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryLinks+CoreDataProperties.h>
#import <MAD/RptqQueryLinks+Extras.h>

#import <MAD/RptqQueryPredicate.h>
#import <MAD/RptqQueryPredicate+CoreDataProperties.h>
#import <MAD/RptqQueryPredicate+Extras.h>

#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+CoreDataProperties.h>
#import <MAD/RptqQueryTable+Extras.h>

#import <MAD/RptqQuerySort.h>
#import <MAD/RptqQuerySort+CoreDataProperties.h>

#import <MAD/RptqQueryCache.h>
#import <MAD/RptqQueryCache+CoreDataProperties.h>

#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+CoreDataProperties.h>
#import <MAD/RptqDocumentElement+Extras.h>

#import <MAD/RptqDocumentElementAggregate.h>
#import <MAD/RptqDocumentElementAggregate+CoreDataProperties.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>

#import <MAD/RptqDocumentElementBarcode.h>
#import <MAD/RptqDocumentElementBarcode+CoreDataProperties.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>

#import <MAD/RptqDocumentElementChart.h>
#import <MAD/RptqDocumentElementChart+CoreDataProperties.h>

#import <MAD/RptqDocumentElementFormula.h>
#import <MAD/RptqDocumentElementFormula+CoreDataProperties.h>
#import <MAD/RptqDocumentElementFormula+Extras.h>

#import <MAD/RptqDocumentElementGroupKey.h>
#import <MAD/RptqDocumentElementGroupKey+CoreDataProperties.h>

#import <MAD/RptqDocumentElementImage.h>
#import <MAD/RptqDocumentElementImage+CoreDataProperties.h>
#import <MAD/RptqDocumentElementImage+Extras.h>

#import <MAD/RptqDocumentElementLabel.h>
#import <MAD/RptqDocumentElementLabel+CoreDataProperties.h>
#import <MAD/RptqDocumentElementLabel+Extras.h>

#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementLabelDataField+CoreDataProperties.h>
#import <MAD/RptqDocumentElementLabelDataField+Extras.h>

#import <MAD/RptqDocumentElementLabelLink.h>
#import <MAD/RptqDocumentElementLabelLink+CoreDataProperties.h>
#import <MAD/RptqDocumentElementLabelLink+Extras.h>

#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDocumentSection+CoreDataProperties.h>
#import <MAD/RptqDocumentSection+Extras.h>

#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/RptqDocumentSectionRows+CoreDataProperties.h>
#import <MAD/RptqDocumentSectionRows+Extras.h>

#import <MAD/RptqDatabaseCredentals.h>
//#import <MAD/RptqDatabaseCredentals+CoreDataProperties.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>

#import <MAD/RptqFieldSelectorManager.h>

#import <MAD/MADActivityItemProviderDelegate.h>

