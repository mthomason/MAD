# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MAD subset the Linux build compiles (docs/project/MAD_LINUX.md §9): 168 of the 199
# implementation files under MAD/Source -- the data, model, store, query and
# archive side, and since Phase E the render half (the formatter, the page walk,
# the element family and the shared render reads).  The 31 that stay on Apple
# fall in four groups, each named below.  Keep this list in step with
# docs/project/MAD_LINUX.md §4 and §5.2.
#
# Excluded, and why:
#
#   The UI tail (§5.2): a view, a renderer, or a UIFont/UIImage holder.
#     MADAccessibilityLine.m            UIBezierPath/CALayer drawing
#     MADActivityIndicator.m            UIView subclass
#     MADActivityIndicatorLabel.m       UILabel subclass
#     MADActivityItemProviderPdf.m      UIActivityItemProvider (share sheet)
#     MADAppLaunchContext.m             UIKit application-state helpers
#     MADElementStylizedText.m          UIFont/UIFontDescriptor metrics
#     MADFonts.m                        UIFont families
#     MADImageThumbnail.m               UIImage rewriting
#     MADOperationBackgroundTaskBegin.m  UIApplication background tasks
#     MADOperationBackgroundTaskEnd.m    (no suspension concept headless)
#     MADPrintPageElementBarcode.m      barcode printing (MADBarcodes)
#     MADPrintPageRenderer.m            UIPrintPageRenderer: the PDF seam
#     MADSectionLayoutAttributes.m      UICollectionViewLayoutAttributes
#     MADSectionLayoutManager.m         the above's client
#     UIDocument+Extras.m               UIDocument category
#     UIFontDescriptor+MADAdditions.m   UIFontDescriptor category
#
#   The document class, and the operations that build, close or delete one --
#   Phase D settles the rest.  MADocument is a UIDocument, so it stays out; the
#   headless reader that replaces it for the data path is here instead
#   (MADHeadlessDocument, on MADDocumentDataProtocol and MADDocumentRenderProtocol
#   -- which the refresh chain in MADOperationRefresh* and the render half both run
#   against, and which is in this build).
#     MADocument.m                        UIDocument subclass
#     MADOperationCreateDocument*.m       five operations that build one
#     MADOperationDeleteFile.m            file management on a document
#     MADOperationDocumentCloseDocument.m closes one
#
#   The keychain (§4): MADOperationKeyChain{Get,Put,DeletePassword}.m --
#   the refresh path takes credentials from an operation dependency, never
#   the keychain, and MADFoundation's MADKeyChain is out for the same reason
#
#   MADBarcodes (§3: unused and unmaintained; its base class is a
#   CoreGraphics renderer).  The element *type* stays in the model -- the
#   two creation paths above log and skip it off Apple.
#     rptq/RptqDocumentElementBarcode+Extras.m  the MTBarcodeProtocol conformance
#     MADDocumentObjectDataReferenceBarcode.m   its data reference

set(MAD_SOURCES
	"${SOURCE_DIR}/MADAlignment.m"
	"${SOURCE_DIR}/MADArchiveManager.m"
	"${SOURCE_DIR}/MADConstants.m"
	"${SOURCE_DIR}/madmath.c"
	"${SOURCE_DIR}/MADCurrencyFormatter.m"
	"${SOURCE_DIR}/MADDataFormatter.m"
	"${SOURCE_DIR}/MADDataTable+Constructor.m"
	"${SOURCE_DIR}/MADDocumentStore.m"
	"${SOURCE_DIR}/MADHeadlessDocument.m"
	"${SOURCE_DIR}/MADDatabase+Constructor.m"
	"${SOURCE_DIR}/MADDatabaseConnection+Constructor.m"
	"${SOURCE_DIR}/MADDatabaseField+Constructor.m"
	"${SOURCE_DIR}/MADDesignerLayout.m"
	"${SOURCE_DIR}/MADDesignerQuery.m"
	"${SOURCE_DIR}/MADDesignerViewer.m"
	"${SOURCE_DIR}/MADDocumentObjectDataReference.m"
	"${SOURCE_DIR}/MADDocumentObjectTypeDescriptor.m"
	"${SOURCE_DIR}/MADFont.m"
	"${SOURCE_DIR}/model/MADModel.m"
	"${SOURCE_DIR}/model/MADModelDatabase.m"
	"${SOURCE_DIR}/model/MADModelDocument.m"
	"${SOURCE_DIR}/model/MADModelField.m"
	"${SOURCE_DIR}/model/MADModelQuery.m"
	"${SOURCE_DIR}/model/MADModelQueryField.m"
	"${SOURCE_DIR}/model/MADModelQueryLink.m"
	"${SOURCE_DIR}/model/MADModelQueryTable.m"
	"${SOURCE_DIR}/model/MADModelTable.m"
	"${SOURCE_DIR}/MADNotificationDidFormatPage.m"
	"${SOURCE_DIR}/MADNotificationFileUpdate.m"
	"${SOURCE_DIR}/MADOperationRefresh.m"
	"${SOURCE_DIR}/MADOperationRefreshInitialize.m"
	"${SOURCE_DIR}/MADOperationRefreshInitalizeMainDataTable.m"
	"${SOURCE_DIR}/MADOperationUniqueUrlForFilename.m"
	"${SOURCE_DIR}/MADPageOptions.m"
	"${SOURCE_DIR}/MADParameters+QueryCacheAggregate.m"
	"${SOURCE_DIR}/MADPathUtilities.m"
	"${SOURCE_DIR}/MADQuery+Extras.m"
	"${SOURCE_DIR}/MADQueryActiveQueryFields.m"
	"${SOURCE_DIR}/MADQueryCacheAggregateFunction.m"
	"${SOURCE_DIR}/MADQueryCacheIndexCreateTemplate.m"
	"${SOURCE_DIR}/MADQueryCacheJournalModeDefault.m"
	"${SOURCE_DIR}/MADQueryCacheSelectGroupKeys.m"
	"${SOURCE_DIR}/MADQueryCustomNoResults.m"
	"${SOURCE_DIR}/MADQueryDefinitionField.m"
	"${SOURCE_DIR}/MADQueryDefinitionGroup.m"
	"${SOURCE_DIR}/MADQueryDefinitionLinks.m"
	"${SOURCE_DIR}/MADQueryDefinitionPredicate.m"
	"${SOURCE_DIR}/MADQueryDefinitionSort.m"
	"${SOURCE_DIR}/MADQueryDefinitionTable.m"
	"${SOURCE_DIR}/MADQueryFull.m"
	"${SOURCE_DIR}/MADQueryFullTableEnumerator.m"
	"${SOURCE_DIR}/MADQueryMaxFieldLength.m"
	"${SOURCE_DIR}/MADQueryPredicate.m"
	"${SOURCE_DIR}/MADQuerySampleDataField.m"
	"${SOURCE_DIR}/MADQuerySampleDataTable.m"
	"${SOURCE_DIR}/MADQuerySampleDataTableRange.m"
	"${SOURCE_DIR}/MADQuerySelectExpression.m"
	"${SOURCE_DIR}/MADQuerySelectExpressionActiveFields.m"
	"${SOURCE_DIR}/sql/MADSQLCompileError.m"
	"${SOURCE_DIR}/sql/MADSQLStatement.m"
	"${SOURCE_DIR}/sql/MADSQLTokenizer.m"
	"${SOURCE_DIR}/sql/MADSQLParser.m"
	"${SOURCE_DIR}/sql/MADSQLQueryCompiler.m"
	"${SOURCE_DIR}/sql/MADSQLStatementResolver.m"
	"${SOURCE_DIR}/MADQuerySelectExpressionAllFields.m"
	"${SOURCE_DIR}/MADPrintPageElement.m"
	"${SOURCE_DIR}/MADPrintPageElement+Constructor.m"
	"${SOURCE_DIR}/MADQueryTest.m"
	"${SOURCE_DIR}/MADDocumentRenderDataSource.m"
	"${SOURCE_DIR}/MADReportExporterCSV.m"
	"${SOURCE_DIR}/MADReportExporterHTML.m"
	"${SOURCE_DIR}/MADReportExporterHTMLFlow.m"
	"${SOURCE_DIR}/MADReportExporterJSON.m"
	"${SOURCE_DIR}/MADReportExporterJSONReport.m"
	"${SOURCE_DIR}/MADReportExporterPDF.m"
	"${SOURCE_DIR}/MADReportExporterRegistry.m"
	"${SOURCE_DIR}/MADReportExporterText.m"
	"${SOURCE_DIR}/MADReportExportSource.m"
	"${SOURCE_DIR}/MADReportExportWriter.m"
	"${SOURCE_DIR}/MADReportFormatter.m"
	"${SOURCE_DIR}/MADReportFormatterCache.m"
	"${SOURCE_DIR}/MADReportFormatterState.m"
	"${SOURCE_DIR}/MADReportLineRepresentation.m"
	"${SOURCE_DIR}/MADReportLineStyle.m"
	"${SOURCE_DIR}/MADReportPageRepresentation.m"
	"${SOURCE_DIR}/MADReportPageBuilder.m"
	"${SOURCE_DIR}/MADReportRow.m"
	"${SOURCE_DIR}/MADReportRows.m"
	"${SOURCE_DIR}/MADReportSection.m"
	"${SOURCE_DIR}/MADReportSectionEnumerator.m"
	"${SOURCE_DIR}/MADReportSectionRepresentation.m"
	"${SOURCE_DIR}/MADReportSectionRowsRepresentation.m"
	"${SOURCE_DIR}/MADReportTextRepresentation.m"
	"${SOURCE_DIR}/MADSQLJoinType.m"
	"${SOURCE_DIR}/MADSectionGroupLayout.m"
	"${SOURCE_DIR}/MADSectionLayout.m"
	"${SOURCE_DIR}/MADSectionRepresentation.m"
	"${SOURCE_DIR}/MADSectionsLayout.m"
	"${SOURCE_DIR}/model/MADTableFieldIdentifier.m"
	"${SOURCE_DIR}/MADTableFormatter.m"
	"${SOURCE_DIR}/MADocumentSectionType.m"
	"${SOURCE_DIR}/MADocumentState.m"
	"${SOURCE_DIR}/NSPredicate+Creators.m"
	"${SOURCE_DIR}/madtar.m"

	"${SOURCE_DIR}/paper/MTPaper.m"
	"${SOURCE_DIR}/rptq/MADSchemaFieldSelectorModel.m"
	"${SOURCE_DIR}/rptq/RptqBorder+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDataHelper.m"
	"${SOURCE_DIR}/rptq/RptqDatabase+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDatabaseCredentals+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDatabaseCredentals+MADDatabaseConnection.m"
	"${SOURCE_DIR}/rptq/RptqDatabaseSchemaField+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDatabaseSchemaTable+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDirectionalAsymmetry+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDirectionalProperty+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocument+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentElement+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentSection+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentElementAggregate+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentElementFormula+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentElementGroupKey+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentElementImage+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentElementLabel+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentElementLabelDataField+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentElementLabelLink+Extras.m"
	"${SOURCE_DIR}/rptq/RptqDocumentSectionEnumerator.m"
	"${SOURCE_DIR}/rptq/RptqDocumentSectionRows+Extras.m"
	"${SOURCE_DIR}/rptq/RptqPoint+Extras.m"
	"${SOURCE_DIR}/rptq/RptqQuery+Extras.m"
	"${SOURCE_DIR}/rptq/RptqQueryField+Extras.m"
	"${SOURCE_DIR}/rptq/RptqQueryGroup+Extras.m"
	"${SOURCE_DIR}/rptq/RptqQueryLinks+Extras.m"
	"${SOURCE_DIR}/rptq/RptqQueryPredicate+Extras.m"
	"${SOURCE_DIR}/rptq/RptqQuerySort+Extras.m"
	"${SOURCE_DIR}/rptq/RptqQueryTable+Extras.m"
	"${SOURCE_DIR}/rptq/RptqRect+Extras.m"
	"${SOURCE_DIR}/rptq/RptqSize+Extras.m"
	"${SOURCE_DIR}/rptq/autogen/RptqAlignment.m"
	"${SOURCE_DIR}/rptq/autogen/RptqBorder.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDatabase.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDatabaseCredentals.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDatabaseSchemaField.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDatabaseSchemaTable.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDirectionalAsymmetry.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDirectionalProperty.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocument.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElement.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElementAggregate.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElementBarcode.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElementChart.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElementFormula.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElementGroupKey.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElementImage.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElementLabel.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElementLabelDataField.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentElementLabelLink.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentSection.m"
	"${SOURCE_DIR}/rptq/autogen/RptqDocumentSectionRows.m"
	"${SOURCE_DIR}/rptq/autogen/RptqNumericFormat.m"
	"${SOURCE_DIR}/rptq/autogen/RptqPoint.m"
	"${SOURCE_DIR}/rptq/autogen/RptqQuery.m"
	"${SOURCE_DIR}/rptq/autogen/RptqQueryField.m"
	"${SOURCE_DIR}/rptq/autogen/RptqQueryGroup.m"
	"${SOURCE_DIR}/rptq/autogen/RptqQueryLinks.m"
	"${SOURCE_DIR}/rptq/autogen/RptqQueryPredicate.m"
	"${SOURCE_DIR}/rptq/autogen/RptqQuerySort.m"
	"${SOURCE_DIR}/rptq/autogen/RptqQueryTable.m"
	"${SOURCE_DIR}/rptq/autogen/RptqRect.m"
	"${SOURCE_DIR}/rptq/autogen/RptqSize.m"
	"${SOURCE_DIR}/rptq/autogen/RptqTextStyle.m"
	"${SOURCE_DIR}/rptq/store/MADLegacyStoreConversion.m"
	"${SOURCE_DIR}/rptq/store/MADStore.m"
	"${SOURCE_DIR}/rptq/store/MADStoreGraph.m"
	"${SOURCE_DIR}/rptq/store/MADStoreObject.m"
	"${SOURCE_DIR}/rptq/store/MADStoreSchema.m"
	"${SOURCE_DIR}/rptq/store/RptqObject.m"
	"${SOURCE_DIR}/rptq/store/RptqStoreContext.m"
)
