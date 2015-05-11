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

NSString * const PDF_PATH_EXTENSION                                 = @"pdf";
NSString * const MTDocumentExtentionMobleApplicationDocumentData    = @"madd";

NSString * const TEMPLATE_PATH_EXTENSION                            = @"madt";

NSString * const MTCollectionElementKindSectionLabel                = @"MTCollectionElementKindSectionLabel";

#pragma mark Common UI Strings

NSString * const MNSStringInterfaceButtonTitleContinue              = @"Continue";
NSString * const MNSStringInterfaceButtonTitleContinueDesc          = @"Continue Button Title";

NSString * const MNSStringInterfaceButtonTitleTryAgain              = @"Try Again";
NSString * const MNSStringInterfaceButtonTitleTryAgainDesc          = @"Try Again Button Title";

NSString * const MNSStringInterfaceButtonTitleAbort                 = @"Abort Application";
NSString * const MNSStringInterfaceButtonTitleAbortDesc             = @"Abort Button Title";

// MARK: Storyboard Identifiers

CGFloat const MNSAnimationDurationShowFromBottom = 0.7000f;
CGFloat const MNSAnimationDurationShowFromSide = 0.4870f;
CGFloat const MNSAnimationDurationSlow = 0.12000f;
CGFloat const MNSAnimationDurationNormal = 0.7000f;
CGFloat const MNSAnimationDurationFast = 0.3000f;
CGFloat const MNSAnimationDurationNone = 0.0000f;

CGFloat const MNSDocumentHeight = 73.0000f;

NSString * const MNSInterfaceButtonDismiss                          = @"Dismiss";
NSString * const MNSInterfaceTitleError                             = @"error";
NSString * const MNSInterfaceMessageErrorDataSourceCreation         = @"Datasource creation failed.";

NSString * const UIIMAGEDOCUMENTBLANK                               = @"UIImageDocumentBlank";
NSString * const APPLICATIONDATA_FILENAME                           = @"appdata";
NSString * const MYSQLDATABASEDATA_FILENAME                         = @"mydata";
NSString * const MTPersistentStoreAliasUserPreferences              = @"preferences";

NSString * const TEMPLATES                                          = @"Templates";

NSString * const NSDATABASE_SF_OAUTH_KEY                            = @"3MVG9QDx8IX8nP5Secp_EepwcYY2I1BT8m812vnIvve_DEHnQPt5437rXOvFPJY4g41lAc.IXZKILutC_CDLk";
NSString * const NSDATATBASE_SF_OAUTH_CALLBACK_URL                  = @"eda://reports.everydayapps.com/";

CGFloat const MNSTableViewCellQueryInputHeightDefault = 100.0000f;
CGFloat const MNSTableViewCellInstructionHeightDefault = 100.0000f;
CGFloat const MNSTableViewCellOverrideHeightDefault = 44.0000f;
CGFloat const MNSTableViewCellQueryLinkHeightDefault = 50.0000f;

// MARK: Segue Identifiers

NSString * const KEY_DB_TYPE_SF     = @"Salesforce.com";
NSString * const KEY_DB_TYPE_DB     = @"Database.com";

#pragma mark - Core Data Constants
#pragma mark Do not change these.
