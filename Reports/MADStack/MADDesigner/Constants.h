//
//  Constants.h
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_Constants_h
#define Reports_Constants_h

#import <Foundation/NSString.h>
#import <CoreGraphics/CGBase.h>

#ifndef NS_DESIGNATED_INITIALIZER
  #if __has_attribute(objc_designated_initializer)
    #define NS_DESIGNATED_INITIALIZER __attribute((objc_designated_initializer))
  #else
    #define NS_DESIGNATED_INITIALIZER
  #endif
#endif

#pragma mark - Layout

// MARK: Margin
#ifdef FALSE
  #undef FALSE
#endif
#ifdef TRUE
  #undef TRUE
#endif
#define FALSE 0
#define TRUE  1

extern NSString * const MTCollectionElementKindSectionLabel;

extern NSString * const MNSStringInterfaceButtonTitleContinue;
extern NSString * const MNSStringInterfaceButtonTitleContinueDesc;
extern NSString * const MNSStringInterfaceButtonTitleTryAgain;
extern NSString * const MNSStringInterfaceButtonTitleTryAgainDesc;
extern NSString * const MNSStringInterfaceButtonTitleAbort;
extern NSString * const MNSStringInterfaceButtonTitleAbortDesc;

extern const CGFloat MNSAnimationDurationShowFromBottom;
extern const CGFloat MNSAnimationDurationShowFromSide;
extern const CGFloat MNSAnimationDurationSlow;
extern const CGFloat MNSAnimationDurationFast;
extern const CGFloat MNSAnimationDurationNormal;
extern const CGFloat MNSAnimationDurationNone;

extern const CGFloat MNSTableViewCellQueryInputHeightDefault;
extern const CGFloat MNSTableViewCellInstructionHeightDefault;
extern const CGFloat MNSTableViewCellOverrideHeightDefault;
extern const CGFloat MNSTableViewCellQueryLinkHeightDefault;

extern const CGFloat MNSDocumentHeight;

extern NSString * const MNSInterfaceButtonDismiss;
extern NSString * const MNSInterfaceTitleError;
extern NSString * const MNSInterfaceMessageErrorDataSourceCreation;

extern NSString * const APPLICATIONDATA_FILENAME;
extern NSString * const MYSQLDATABASEDATA_FILENAME;
extern NSString * const MTPersistentStoreAliasUserPreferences;

extern NSString * const MTDocumentExtentionMobleApplicationDocumentData;
extern NSString * const TEMPLATE_PATH_EXTENSION;
extern NSString * const TEMPLATES;

extern NSString * const NSDATABASE_SF_OAUTH_KEY;
extern NSString * const NSDATATBASE_SF_OAUTH_CALLBACK_URL;

extern NSString * const PDF_PATH_EXTENSION;

extern NSString * const KEY_DB_TYPE_SF;
extern NSString * const KEY_DB_TYPE_DB;

#endif
