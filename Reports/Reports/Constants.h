//
//  Constants.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#define MT_DEBUG_MODE

#ifdef MT_DEBUG_MODE
#define MTLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define MTLog( s, ... )
#endif

#define STORYBOARD_NAME() \
            (([[UIDevice currentDevice] userInterfaceIdiom] == \
            UIUserInterfaceIdiomPhone) ? MNSReportDesigner_Phone : MNSReportDesigner_Pad)


#pragma mark - Layout

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

typedef NS_ENUM(NSUInteger, UIViewControllerSchemaTablesSections) {
	UIViewControllerSchemaTablesSectionsInstructions = 0,
    UIViewControllerSchemaTablesSectionsDatasource = 1,
	UIViewControllerSchemaTablesSectionsTables = 2,
	UIViewControllerSchemaTablesSectionsLinks = 3,
	UIViewControllerSchemaTablesSectionsGroups = 4,
	UIViewControllerSchemaTablesSectionsPredicate = 5,
    UIViewControllerSchemaTablesSectionsSql = 6
};

extern NSString * const MTCollectionElementKindSectionLabel;

extern NSString * const MNSStringInterfaceButtonTitleContinue;
extern NSString * const MNSStringInterfaceButtonTitleContinueDesc;
extern NSString * const MNSStringInterfaceButtonTitleTryAgain;
extern NSString * const MNSStringInterfaceButtonTitleTryAgainDesc;
extern NSString * const MNSStringInterfaceButtonTitleAbort;
extern NSString * const MNSStringInterfaceButtonTitleAbortDesc;

extern NSString * const MNSReportDesigner_Phone;
extern NSString * const MNSReportDesigner_Pad;

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
extern NSString * const QUERYDATA_FILENAME;
extern NSString * const TRVDATA_FILENAME;

extern NSString * const SCHEMA_PATH_EXTENSION;
extern NSString * const TRVDATA_PATH_EXTENSION;
extern NSString * const REPORT_PATH_EXTENSION;
extern NSString * const TEMPLATE_PATH_EXTENSION;
extern NSString * const TEMPLATES;

extern NSString * const NSDATABASE_USERNAME;
extern NSString * const NSDATABASE_PASSWORD;
extern NSString * const NSDATABASE_DATABASE;
extern NSString * const NSDATABASE_PORT;
extern NSString * const NSDATABASE_HOST;

extern NSString * const NSDATABASE_SF_OAUTH_KEY;
extern NSString * const NSDATATBASE_SF_OAUTH_CALLBACK_URL;

extern NSString * const KEY_TBL_SEC_HEADERS;
extern NSString * const KEY_TBL_SEC_ROW_COUNT;
extern NSString * const KEY_TBL_SEC_ROW_HEIGHT;
extern NSString * const KEY_TBL_SEC_SECTIONS;

extern NSString * const KEY_DB_TYPE_SF;
extern NSString * const KEY_DB_TYPE_DB;

// MARK: Storyboard References
extern NSString * const MNSIdentifierStoryboardReportDesignerPhone;

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