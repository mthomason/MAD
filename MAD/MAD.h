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
#import <MAD/MADLegacyStoreConversion.h>
#import <MAD/RptqObject.h>
#import <MAD/RptqStoreContext.h>

// Remaining public headers, so the module umbrella is complete.
// (-Wincomplete-umbrella; keep in sync with the Public headers phase.)
#import <MAD/MADAggregateFunctionGroupByType.h>
#import <MAD/MADAggregateFunctionInputType.h>
#import <MAD/MADAggregateFunctionType.h>
#import <MAD/MADAlignment.h>
#import <MAD/MADAppLaunchContext.h>
#import <MAD/MADConstants.h>
#import <MAD/MADCredentialSourceType.h>
#import <MAD/MADCurrencyFormatter.h>
#import <MAD/MADDesignerLayout.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADDocumentObjectTypeDescriptor.h>
#import <MAD/MADDocumentProtocol.h>
#import <MAD/MADDocumentTextRepresentationProtocol.h>
#import <MAD/MADElementStylizedText.h>
#import <MAD/MADFonts.h>
#import <MAD/MADImageThumbnail.h>
#import <MAD/MADKeyChainKeyValueProtocol.h>
#import <MAD/MADModel.h>
#import <MAD/MADModelDataProtocol.h>
#import <MAD/MADModelDatabase.h>
#import <MAD/MADModelDocument.h>
#import <MAD/MADModelField.h>
#import <MAD/MADModelIDProtocol.h>
#import <MAD/MADModelQuery.h>
#import <MAD/MADModelQueryField.h>
#import <MAD/MADModelQueryLink.h>
#import <MAD/MADModelQueryTable.h>
#import <MAD/MADModelTable.h>
#import <MAD/MADNotificationFileUpdate.h>
#import <MAD/MADNotificationProtocol.h>
#import <MAD/MADOperationBackgroundTaskBegin.h>
#import <MAD/MADOperationBackgroundTaskEnd.h>
#import <MAD/MADOperationCreateDocumentAddConnection.h>
#import <MAD/MADOperationCreateDocumentCreateDocument.h>
#import <MAD/MADOperationCreateDocumentFirstTimeSetup.h>
#import <MAD/MADOperationCreateDocumentImportSchema.h>
#import <MAD/MADOperationCreateDocumentSaveAndCloseNewDocument.h>
#import <MAD/MADOperationDeleteFile.h>
#import <MAD/MADOperationDocumentCloseDocument.h>
#import <MAD/MADOperationHoldsCredentialsProtocol.h>
#import <MAD/MADOperationHoldsPasswordProtocol.h>
#import <MAD/MADOperationHoldsUsernameProtocol.h>
#import <MAD/MADOperationKeyChainDeletePassword.h>
#import <MAD/MADOperationKeyChainGet.h>
#import <MAD/MADOperationKeyChainPut.h>
#import <MAD/MADOperationUniqueUrlForFilename.h>
#import <MAD/MADPaperType.h>
#import <MAD/MADPredicateOperator.h>
#import <MAD/MADPrintPageRendererDataSource.h>
#import <MAD/MADQueryFull.h>
#import <MAD/MADQueryLinkType.h>
#import <MAD/MADReportFormatterDataSourceProtocol.h>
#import <MAD/MADReportSection.h>
#import <MAD/MADReportTextRepresentation.h>
#import <MAD/MADSQLJoinType.h>
#import <MAD/MADSectionLayout.h>
#import <MAD/MADSectionLayoutManager.h>
#import <MAD/MADSectionRepresentation.h>
#import <MAD/MADSortOrder.h>
#import <MAD/MADTableFieldIdentifier.h>
#import <MAD/MADTableFormatter.h>
#import <MAD/MADocumentSectionType.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqDirectionalProperty.h>
#import <MAD/RptqDocumentElementGroupKey+Extras.h>
#import <MAD/RptqDocumentSectionEnumerator.h>
#import <MAD/RptqDocumentSectionWrappingStyle.h>
#import <MAD/RptqNumericFormat.h>
#import <MAD/RptqPoint.h>
#import <MAD/RptqQuerySort+Extras.h>
#import <MAD/RptqRect+Extras.h>
#import <MAD/RptqRect.h>
#import <MAD/RptqSize.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/UIFontDescriptor+MADAdditions.h>
#import <MAD/madmath.h>
#import <MAD/miniz.h>
