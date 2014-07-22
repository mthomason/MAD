//
//  Constants.m
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "Constants.h"

#pragma mark - Constants

//BOOL const MTDebug = YES;

#pragma mark Bundle Ids

// in your project define those two somewhere as such:

#pragma mark Product Ids

NSString * const MTStoreKitProductIdentifierDesignerSubscriptionYear1       = @"com.everydayapps.mad.designer.subscription.year";
NSString * const MTStoreKitProductIdentifierDesignerSubscriptionMonth1      = @"com.everydayapps.mad.designer.subscription.month";
NSString * const MTStoreKitProductIdentifierViewerSubscriptionMonth1        = @"com.everydayapps.mad.viewer.subscription.month";
NSString * const MTStoreKitProductIdentifierViewerSubscriptionYear1         = @"com.everydayapps.mad.viewer.subscription.year";

#pragma mark Storyboard Segues

NSString * const MTSegueShowSetUpDatasourceMySqlIdentifier          = @"MTSegueShowSetUpDatasourceMySqlIdentifier";
NSString * const MTSegueShowSetUpDatasourceSqlite3Identifier        = @"MTSegueShowSetUpDatasourceSqlite3Identifier";
NSString * const MTSegueShowSetUpDatasourceSalesForceIdentifier     = @"MTSegueShowSetUpDatasourceSalesForceIdentifier";
NSString * const MTSegueShowSetUpDatasourceSqlServerIdentifier      = @"MTSegueShowSetUpDatasourceTdsIdentifier";
NSString * const MTSegueLicensing                                   = @"MTSegueLicensing";

NSString * const MTBundleDisplayName                                = @"CFBundleDisplayName";

NSString * const MTDocumentTypeUtiMad                               = @"com.everydayapps.productivity.mad";

NSString * const MTSampleDatabaseChinook                            = @"chinook";

NSString * const PDF_PATH_EXTENSION                                 = @"pdf";
NSString * const MTDocumentExtentionMobleApplicationDocumentArchive = @"mada";
NSString * const MTDocumentExtentionMobleApplicationDocument        = @"mad";
NSString * const MTDocumentExtentionSqlite3                         = @"sqlite3";
NSString * const MTDocumentExtentionMobleApplicationDocumentData    = @"madd";
NSString * const MTDocumentExtentionPoratableNetworkGraphic         = @"png";

NSString * const TEMPLATE_PATH_EXTENSION                            = @"madt";

NSString * const MTCollectionElementKindSectionLabel                = @"MTCollectionElementKindSectionLabel";

#pragma mark Common UI Strings

NSString * const MNSStringInterfaceButtonTitleContinue              = @"Continue";
NSString * const MNSStringInterfaceButtonTitleContinueDesc          = @"Continue Button Title";

NSString * const MNSStringInterfaceButtonTitleTryAgain              = @"Try Again";
NSString * const MNSStringInterfaceButtonTitleTryAgainDesc          = @"Try Again Button Title";

NSString * const MNSStringInterfaceButtonTitleAbort                 = @"Abort Application";
NSString * const MNSStringInterfaceButtonTitleAbortDesc             = @"Abort Button Title";

const CGFloat MTDefaultFingerSizeWidth = 44.0000f;
const CGFloat MTDefaultFingerSizeHeight = 44.0000f;
// MARK: Storyboard Identifiers

CGFloat const MNSAnimationDurationShowFromBottom = 0.7000f;
CGFloat const MNSAnimationDurationShowFromBottomHalf = 0.3500f;
CGFloat const MNSAnimationDurationShowFromSide = 0.4870f;
CGFloat const MNSAnimationDurationSlow = 0.12000f;
CGFloat const MNSAnimationDurationNormal = 0.7000f;
CGFloat const MNSAnimationDurationFast = 0.3000f;
CGFloat const MNSAnimationDurationNone = 0.0000f;

CGFloat const MNSDocumentHeight = 73.0000f;

NSString * const MNSInterfaceButtonDismiss                          = @"Dismiss";
NSString * const MNSInterfaceTitleProblem                           = @"Problem";
NSString * const MNSInterfaceTitleError                             = @"error";
NSString * const MNSInterfaceMessageErrorDataSourceCreation         = @"Datasource creation failed.";
NSString * const MNSInterfaceMessageErrorFailedToCreateReport       = @"Failed to create report document.";

NSString * const UIIMAGEDOCUMENTBLANK                               = @"UIImageDocumentBlank";
NSString * const APPLICATIONDATA_FILENAME                           = @"appdata";
NSString * const MYSQLDATABASEDATA_FILENAME                         = @"mydata";
NSString * const MTPersistentStoreAliasMad                          = @"analyitics";
NSString * const MTPersistentStoreAliasUserPreferences              = @"preferences";

NSString * const TEMPLATES                                          = @"Templates";

NSString * const NSDATABASE_SF_OAUTH_KEY                            = @"3MVG9QDx8IX8nP5Secp_EepwcYY2I1BT8m812vnIvve_DEHnQPt5437rXOvFPJY4g41lAc.IXZKILutC_CDLk";
NSString * const NSDATATBASE_SF_OAUTH_CALLBACK_URL                  = @"eda://reports.everydayapps.com/";

NSString * const MTTableHeaderSectionKey                            = @"MTTableHeaderSectionKey";
NSString * const MTTableSectionRowKey                               = @"MTTableSectionRowKey";
NSString * const MTTableSectionRowHeightKey                         = @"MTTableSectionRowHeightKey";
NSString * const MTTableSectionSectionsKey                          = @"MTTableSectionSectionsKey";

CGFloat const MNSTableViewCellHeightDefault = 44.0000f;

CGFloat const MNSTableViewCellTableNameHeightDefault = 44.0000f;
CGFloat const MNSTableViewCellQueryInputHeightDefault = 100.0000f;
CGFloat const MNSTableViewCellInstructionHeightDefault = 100.0000f;
CGFloat const MNSTableViewCellInkNameHeightDefault = 0.0000f;
CGFloat const MNSTableViewCellOverrideHeightDefault = 44.0000f;
CGFloat const MNSTableViewCellQueryLinkHeightDefault = 50.0000f;

// MARK: Segue Identifiers
NSString * const MNSIdentifierSegueShowAddDatabaseDrivers           = @"MNSIdentifierSegueShowAddDatabaseDrivers";
NSString * const MNSIdentifierSegueShowLayoutSettings               = @"showLayoutSettings";
NSString * const MNSIdentifierSegueShowDatabasesDrivers             = @"showDatabasesDrivers";
NSString * const MNSIdentifierSegueShowAddTableViewController       = @"showAddTableViewController";
NSString * const MNSIdentifierSegueShowAddLinkViewController        = @"showAddLinkViewController";
NSString * const MNSIdentifierSegueShowAddPredicateViewController   = @"showAddPredicateViewController";
NSString * const MNSIdentifierSegueShowAddGroupViewController       = @"showAddGroupViewController";
//NSString * const MNSIdentifierSegueShowReportLayout                 = @"showReportLayout";
NSString * const MNSIdentifierSegueShowReportViewerFromQuery        = @"showReportViewerFromQuery";
NSString * const MNSSegueShowSql                                    = @"MNSSegueShowSql";
NSString * const MTSegueOpenInViewer                                = @"MTSegueOpenInViewer";

NSString * const KEY_DB_TYPE_SF     = @"Salesforce.com";
NSString * const KEY_DB_TYPE_DB     = @"Database.com";

#pragma mark - Core Data Constants
#pragma mark Do not change these.
