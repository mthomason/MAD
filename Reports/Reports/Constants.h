//
//  Constants.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#define STORYBOARD_NAME() \
            (([[UIDevice currentDevice] userInterfaceIdiom] == \
            UIUserInterfaceIdiomPhone) ? REPORTDESIGNER_PHONE : REPORTDESIGNER_PAD)

extern NSString * const REPORTDESIGNER_PHONE;
extern NSString * const REPORTDESIGNER_PAD;

extern CGFloat const ANIMATION_DURATION_SHOW_FROM_BOTTOM;
extern CGFloat const ANIMATION_DURATION_SHOW_FROM_BOTTOM_HALF;
extern CGFloat const ANIMATION_DURATION_SHOW_FROM_SIDE;
extern CGFloat const ANIMATION_DURATION_SLOW;
extern CGFloat const ANIMATION_DURATION_FAST;
extern CGFloat const ANIMATION_DURATION_NORMAL;
extern CGFloat const ANIMATION_DURATION_NONE;

extern CGFloat const UITABLEVIEWCELL_HEIGHT_DEFAULT;
extern CGFloat const UITABLEVIEWCELLTABLENAME_HEIGHT_DEFAULT;
extern CGFloat const UITABLEVIEWCELLQUERYINPUT_HEIGHT_DEFAULT;
extern CGFloat const UITABLEVIEWCELLINSTRUCTION_HEIGHT_DEFAULT;
extern CGFloat const UITABLEVIEWCELLLINKNAME_HEIGHT_DEFAULT;
extern CGFloat const UITABLEVIEWCELLOVERRIDE_HEIGHT_DEFAULT;
extern CGFloat const UITABLEVIEWCELLQUERYLINK_HEIGHT_DEFAULT;

extern CGFloat const TVC_DOCUMENT_HEIGHT;

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