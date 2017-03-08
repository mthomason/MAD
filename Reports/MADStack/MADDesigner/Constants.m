//
//  Constants.m
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "Constants.h"

//NSString * const MADFileExtentionMobleApplicationDocument           = @"mad";
//NSString * const MADFileExtentionMobleApplicationDocumentArchive    = @"mada";
//NSString * const MADTrademark                                       = @"MAD";
//NSString * const MADIdentifierGroup                                 = @"group.everydayapps.mad";

#pragma mark - Constants

//BOOL const MTDebug = YES;

#pragma mark Bundle Ids

// in your project define those two somewhere as such:

#pragma mark Product Ids

#pragma mark Storyboard Segues

NSString * const PDF_PATH_EXTENSION                                 = @"pdf";
NSString * const MTDocumentExtentionMobleApplicationDocumentData    = @"madd";

NSString * const TEMPLATE_PATH_EXTENSION                            = @"madt";

#pragma mark Common UI Strings

// MARK: Storyboard Identifiers

const CGFloat MNSAnimationDurationShowFromBottom = 0.7000f;
const CGFloat MNSAnimationDurationShowFromSide = 0.4870f;
const CGFloat MNSAnimationDurationSlow = 0.12000f;
const CGFloat MNSAnimationDurationNormal = 0.7000f;
const CGFloat MNSAnimationDurationFast = 0.3000f;
const CGFloat MNSAnimationDurationNone = 0.0000f;

const CGFloat MNSDocumentHeight = 73.0000f;

NSString * const MNSInterfaceButtonDismiss                          = @"Dismiss";
NSString * const MNSInterfaceTitleError                             = @"error";
NSString * const MNSInterfaceMessageErrorDataSourceCreation         = @"Datasource creation failed.";

NSString * const APPLICATIONDATA_FILENAME                           = @"appdata";
NSString * const MYSQLDATABASEDATA_FILENAME                         = @"mydata";
NSString * const MTPersistentStoreAliasUserPreferences              = @"preferences";

NSString * const TEMPLATES                                          = @"Templates";

NSString * const NSDATABASE_SF_OAUTH_KEY                            = @"3MVG9QDx8IX8nP5Secp_EepwcYY2I1BT8m812vnIvve_DEHnQPt5437rXOvFPJY4g41lAc.IXZKILutC_CDLk";
NSString * const NSDATATBASE_SF_OAUTH_CALLBACK_URL                  = @"eda://reports.everydayapps.com/";

const CGFloat MNSTableViewCellQueryInputHeightDefault = 100.0000f;
const CGFloat MNSTableViewCellQueryLinkHeightDefault = 50.0000f;

// MARK: Segue Identifiers

NSString * const KEY_DB_TYPE_SF     = @"Salesforce.com";
NSString * const KEY_DB_TYPE_DB     = @"Database.com";

#pragma mark - Core Data Constants
#pragma mark Do not change these.
