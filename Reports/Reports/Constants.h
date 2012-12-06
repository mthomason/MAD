//
//  Constants.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#define STORYBOARD_NAME() \
            (([[UIDevice currentDevice] userInterfaceIdiom] == \
            UIUserInterfaceIdiomPhone) ? MNSReportDesigner_Phone : MNSReportDesigner_Pad)

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

//Storyboard References
extern NSString * const MNSIdentifierStoryboardReportDesignerPhone;

//View Controller Identifiers
extern NSString * const MNSIdentifierUIViewControllerTableHeaderTables;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderLayout;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderDatasource;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderLinks;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderGroups;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderPredicate;
extern NSString * const MNSIdentifierUIViewControllerTableHeaderQuery;

//Segue Identifiers
extern NSString * const MNSIdentifierSegueShowLayoutSettings;
extern NSString * const MNSIdentifierSegueShowDatabasesDrivers;
extern NSString * const MNSIdentifierSegueShowAddDatabaseDrivers;
extern NSString * const MNSIdentifierSegueShowAddTableViewController;
extern NSString * const MNSIdentifierSegueShowAddLinkViewController;
extern NSString * const MNSIdentifierSegueShowAddPredicateViewController;
extern NSString * const MNSIdentifierSegueShowAddGroupViewController;
extern NSString * const MNSIdentifierSegueShowReportLayout;
extern NSString * const MNSIdentifierSegueShowReportViewerFromQuery;