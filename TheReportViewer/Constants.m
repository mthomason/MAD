//
//  Constants.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "Constants.h"

#pragma mark - Customizable Constants

CGFloat const ANIMATION_DURATION_SHOW_FROM_BOTTOM = 0.7000f;
CGFloat const ANIMATION_DURATION_SHOW_FROM_BOTTOM_HALF = 0.3500f;
CGFloat const ANIMATION_DURATION_SHOW_FROM_SIDE = 0.4870f;
CGFloat const ANIMATION_DURATION_SLOW = 0.12000f;
CGFloat const ANIMATION_DURATION_NORMAL = 0.7000f;
CGFloat const ANIMATION_DURATION_FAST = 0.3000f;
CGFloat const ANIMATION_DURATION_NONE = 0.0000f;

CGFloat const TVC_DOCUMENT_HEIGHT = 73.0000f;

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

CGFloat const UITABLEVIEWCELL_HEIGHT_DEFAULT = 44.0000f;

CGFloat const UITABLEVIEWCELLTABLENAME_HEIGHT_DEFAULT = 44.0000f;
CGFloat const UITABLEVIEWCELLQUERYINPUT_HEIGHT_DEFAULT = 100.0000f;
CGFloat const UITABLEVIEWCELLINSTRUCTION_HEIGHT_DEFAULT = 100.0000f;
CGFloat const UITABLEVIEWCELLLINKNAME_HEIGHT_DEFAULT = 0.0000f;
CGFloat const UITABLEVIEWCELLOVERRIDE_HEIGHT_DEFAULT = 44.0000f;
CGFloat const UITABLEVIEWCELLQUERYLINK_HEIGHT_DEFAULT = 100.0000f;

NSString * const KEY_DB_TYPE_SF = @"sf";
NSString * const KEY_DB_TYPE_MYSQL = @"my";

#pragma mark - Core Data Constants
#pragma mark Do not change these.