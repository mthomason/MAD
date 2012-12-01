//
//  Constants.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "Constants.h"

#pragma mark - Customizable Constants

NSString * const MNSReportDesigner_Phone = @"ReportDesignerPhone";
NSString * const MNSReportDesigner_Pad = @"ReportDesignerPad";

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

NSString * const UIIMAGEDOCUMENTBLANK               = @"UIImageDocumentBlank";
NSString * const APPLICATIONDATA_FILENAME           = @"appdata";
NSString * const MYSQLDATABASEDATA_FILENAME         = @"mydata";
NSString * const QUERYDATA_FILENAME                 = @"query";
NSString * const TRVDATA_FILENAME                   = @"settings";

NSString * const SCHEMA_PATH_EXTENSION              = @"trvq";
NSString * const TRVDATA_PATH_EXTENSION             = @"trvp";
NSString * const REPORT_PATH_EXTENSION              = @"trv";
NSString * const TEMPLATE_PATH_EXTENSION            = @"trvt";

NSString * const TEMPLATES                          = @"Templates";

NSString * const NSDATABASE_USERNAME                = @"username";
NSString * const NSDATABASE_PASSWORD                = @"password";
NSString * const NSDATABASE_DATABASE                = @"database";
NSString * const NSDATABASE_PORT                    = @"port";
NSString * const NSDATABASE_HOST                    = @"host";

NSString * const NSDATABASE_SF_OAUTH_KEY            = @"3MVG9QDx8IX8nP5Secp_EepwcYY2I1BT8m812vnIvve_DEHnQPt5437rXOvFPJY4g41lAc.IXZKILutC_CDLk";
NSString * const NSDATATBASE_SF_OAUTH_CALLBACK_URL  = @"eda://reports.everydayapps.com/";

NSString * const KEY_TBL_SEC_HEADERS                = @"tsh";
NSString * const KEY_TBL_SEC_ROW_COUNT              = @"tsrc";
NSString * const KEY_TBL_SEC_ROW_HEIGHT             = @"tsrh";
NSString * const KEY_TBL_SEC_SECTIONS               = @"tsrs";

CGFloat const MNSTableViewCellHeightDefault = 44.0000f;

CGFloat const MNSTableViewCellTableNameHeightDefault = 44.0000f;
CGFloat const MNSTableViewCellQueryInputHeightDefault = 100.0000f;
CGFloat const MNSTableViewCellInstructionHeightDefault = 100.0000f;
CGFloat const MNSTableViewCellInkNameHeightDefault = 0.0000f;
CGFloat const MNSTableViewCellOverrideHeightDefault = 44.0000f;
CGFloat const MNSTableViewCellQueryLinkHeightDefault = 100.0000f;

NSString * const KEY_DB_TYPE_SF     = @"Salesforce.com";
NSString * const KEY_DB_TYPE_DB     = @"Database.com";

#pragma mark - Core Data Constants
#pragma mark Do not change these.