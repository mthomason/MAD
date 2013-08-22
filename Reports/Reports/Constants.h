//
//  Constants.h
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#pragma mark - Layout

#ifndef MTDebugOn
#define MTDebugOn YES
#endif

// MARK: Margin

struct MTMargin {
    CGFloat left;
    CGFloat right;
    CGFloat top;
    CGFloat bottom;
};
typedef struct MTMargin MTMargin;


CG_INLINE MTMargin
MTMarginMake(CGFloat top, CGFloat right, CGFloat bottom, CGFloat left) {
    MTMargin margin;
    margin.top = top;
    margin.right = right;
    margin.bottom = bottom;
    margin.left = left;
    return margin;
}

CG_INLINE MTMargin
MTMarginMakeQuick(CGFloat m) {
    MTMargin margin;
    margin.top = m;
    margin.right = m;
    margin.bottom = m;
    margin.left = m;
    return margin;
}

// MARK: Margin

struct MTPadding {
    CGFloat left;
    CGFloat right;
    CGFloat top;
    CGFloat bottom;
};
typedef struct MTPadding MTPadding;

CG_INLINE MTPadding
MTPaddingMake(CGFloat top, CGFloat right, CGFloat bottom, CGFloat left) {
    MTPadding padding;
    padding.top = top;
    padding.right = right;
    padding.bottom = bottom;
    padding.left = left;
    return padding;
}

CG_INLINE MTPadding
MTPaddingMakeQuick(CGFloat p) {
    MTPadding padding;
    padding.top = p;
    padding.right = p;
    padding.bottom = p;
    padding.left = p;
    return padding;
}

typedef NS_ENUM(NSUInteger, MNSSortOrder) {
	MNSSortOrderAccending = 0,
	MNSSortOrderDecending
};

typedef NS_ENUM(NSUInteger, MTAggregateGroupByType) {
    MTAggregateGroupByTypePage = 2,
    MTAggregateGroupByTypeReport = 3,
    MTAggregateGroupByTypeSection = 5,
};

/*
typedef NS_ENUM(NSUInteger, MTAggregateGroupType) {
	MTAggregateGroupTypeField = 1,
	MTAggregateGroupTypeFormula = 2
};*/

typedef NS_ENUM(NSUInteger, MTAggregateFunctionType) {
    MTAggregateFunctionTypeSum = 2,
    MTAggregateFunctionTypeMean = 3,
    MTAggregateFunctionTypeFirst = 5,
    MTAggregateFunctionTypeLast = 7,
    MTAggregateFunctionTypeCount = 11,
    MTAggregateFunctionTypeMin = 13,
    MTAggregateFunctionTypeMax = 17,
};

typedef NS_ENUM(NSUInteger, MTAggregateFunctionInputType) {
    MTAggregateFunctionInputTypeField = 0,
    MTAggregateFunctionInputTypeFormula
};

typedef NS_ENUM(NSUInteger, MTDocumentObjectType) {
	MTDocumentObjectTypeLabelDynamic = 0,
	MTDocumentObjectTypeLabelStatic = 1,
	MTDocumentObjectTypeImage = 2,
    MTDocumentObjectTypeChart = 3,
    MTDocumentObjectTypeFormula = 4,
    MTDocumentObjectTypeAggregate = 5,
    MTDocumentObjectTypeGroupKey = 6,
    MTDocumentObjectTypeAggregateFunctionList = 7,
    MTDocumentObjectTypeWhtiespace = 8
};

typedef NS_ENUM(NSUInteger, MTDocumentObjectBuilder) {
    MTDocumentObjectBuilderType,
    MTDocumentObjectBuilderValue
};

typedef NS_ENUM(NSUInteger, MTQuerySections) {
	MTQuerySectionsDocumentGroups = 0,
    MTQuerySectionsDatasource = 1,
	MTQuerySectionsTables = 2,
	MTQuerySectionsLinks = 3,
	MTQuerySectionsGroups = 4,
	MTQuerySectionsPredicate = 5,
    MTQuerySectionsSql = 6
};

typedef NS_ENUM(NSUInteger, MTControlState) {
	MTControlStateOff = 0,
	MTControlStateOn,
    MTControlStateAmbiguous
};

typedef NS_ENUM(NSUInteger, MTVerticalAlignment) {
	MTVerticalAlignmentTop = 0,
	MTVerticalAlignmentCenter = 1,
	MTVerticalAlignmentBottom = 2
};

typedef NS_ENUM(NSUInteger, MTHorizontalAlignment) {
	MTHorizontalAlignmentLeft = 0,
	MTHorizontalAlignmentCenter = 1,
	MTHorizontalAlignmentRight = 2,
	MTHorizontalAlignmentJustified = 3,
	MTHorizontalAlignmentNatrual = 4
};

extern const CGFloat MTDefaultFingerSizeWidth;
extern const CGFloat MTDefaultFingerSizeHeight;

extern NSString * const MTSqlFrom;;

extern NSString * const MTBundleIdMadDesigner;
extern NSString * const MTBundleIdMadViewer;

extern NSString * const MTStoreKitProductIdentifierDesignerSubscriptionYear1;
extern NSString * const MTStoreKitProductIdentifierDesignerSubscriptionMonth1;
extern NSString * const MTStoreKitProductIdentifierViewerSubscriptionMonth1;
extern NSString * const MTStoreKitProductIdentifierViewerSubscriptionYear1;

extern NSString * const MTSegueShowSetUpDatasourceMySqlIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSalesForceIdentifier;
extern NSString * const MTSegueShowSetUpDatasourceSqlServerIdentifier;
extern NSString * const MTSegueLicensing;
extern NSString * const MTBundleDisplayName;

extern NSString * const MTDocumentTypeUtiMad;

extern NSString * const MTCollectionElementKindSectionLabel;

extern NSString * const MNSStringInterfaceButtonTitleContinue;
extern NSString * const MNSStringInterfaceButtonTitleContinueDesc;
extern NSString * const MNSStringInterfaceButtonTitleTryAgain;
extern NSString * const MNSStringInterfaceButtonTitleTryAgainDesc;
extern NSString * const MNSStringInterfaceButtonTitleAbort;
extern NSString * const MNSStringInterfaceButtonTitleAbortDesc;

// MARK: Storyboard Identifiers

extern NSString * const MTStoryboardReportDesigner;
extern NSString * const MTStoryboardReportDesignerPad;
extern NSString * const MTStoryboardReportDesignerLagacy;
extern NSString * const MTStoryboardReportDesignerPadLagacy;

extern NSString * const MTStoryboardReportViewer;
extern NSString * const MTStoryboardReportViewerPad;
extern NSString * const MTStoryboardReportViewerLagacy;
extern NSString * const MTStoryboardReportViewerPadLagacy;

extern CGFloat const MNSAnimationDurationShowFromBottom;
extern CGFloat const MNSAnimationDurationShowFromBottomHalf;
extern CGFloat const MNSAnimationDurationShowFromSide;
extern CGFloat const MNSAnimationDurationSlow;
extern CGFloat const MNSAnimationDurationFast;
extern CGFloat const MNSAnimationDurationNormal;
extern CGFloat const MNSAnimationDurationNone;

extern CGFloat const MNSTableViewCellHeightDefault;
extern CGFloat const MNSTableViewCellTableNameHeightDefault;
extern CGFloat const MNSTableViewCellQueryInputHeightDefault;
extern CGFloat const MNSTableViewCellInstructionHeightDefault;
extern CGFloat const MNSTableViewCellInkNameHeightDefault;
extern CGFloat const MNSTableViewCellOverrideHeightDefault;
extern CGFloat const MNSTableViewCellQueryLinkHeightDefault;

extern CGFloat const MNSDocumentHeight;

extern NSString * const MNSInterfaceButtonDismiss;
extern NSString * const MNSInterfaceTitleProblem;
extern NSString * const MNSInterfaceTitleError;
extern NSString * const MNSInterfaceMessageErrorDataSourceCreation;
extern NSString * const MNSInterfaceMessageErrorFailedToCreateReport;

extern NSString * const UIIMAGEDOCUMENTBLANK;
extern NSString * const APPLICATIONDATA_FILENAME;
extern NSString * const MYSQLDATABASEDATA_FILENAME;
extern NSString * const MTPersistentStoreAliasMad;
extern NSString * const MTPersistentStoreAliasUserPreferences;

extern NSString * const MTDocumentExtentionMobleApplicationDocument;
extern NSString * const MTDocumentExtentionMobleApplicationDocumentArchive;
extern NSString * const MTDocumentExtentionMobleApplicationDocumentData;
extern NSString * const TEMPLATE_PATH_EXTENSION;
extern NSString * const TEMPLATES;

extern NSString * const NSDATABASE_SF_OAUTH_KEY;
extern NSString * const NSDATATBASE_SF_OAUTH_CALLBACK_URL;

extern NSString * const MTTableHeaderSectionKey;
extern NSString * const MTTableSectionRowKey;
extern NSString * const MTTableSectionRowHeightKey;
extern NSString * const MTTableSectionSectionsKey;
extern NSString * const PDF_PATH_EXTENSION;

extern NSString * const KEY_DB_TYPE_SF;
extern NSString * const KEY_DB_TYPE_DB;

// MARK: Storyboard References

// MARK: View Controller Identifiers
extern NSString * const MNSIdentifierUIViewControllerTableHeaderTables;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderLayout;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderDatasource;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderLinks;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderGroups;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderPredicate;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderQuery;
extern NSString * const MUIViewControllerActivitySpinner;

// MARK: Segue Identifiers
extern NSString * const MTSegueOpenInViewer;
extern NSString * const MNSIdentifierSegueShowLayoutSettings;
extern NSString * const MNSIdentifierSegueShowDatabasesDrivers;
extern NSString * const MNSIdentifierSegueShowAddDatabaseDrivers;
extern NSString * const MNSIdentifierSegueShowAddTableViewController;
extern NSString * const MNSIdentifierSegueShowAddLinkViewController;
extern NSString * const MNSIdentifierSegueShowAddPredicateViewController;
extern NSString * const MNSIdentifierSegueShowAddGroupViewController;
extern NSString * const MNSIdentifierSegueShowReportLayout;
extern NSString * const MNSIdentifierSegueShowReportViewerFromQuery;
extern NSString * const MNSSegueShowSql;
