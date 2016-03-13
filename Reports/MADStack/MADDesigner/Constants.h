//
//  Constants.h
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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

typedef NS_ENUM(NSUInteger, MTTabBarItemTag) {
	MTTabBarItemTagQuery = 1,
	MTTabBarItemTagDesigner = 2,
    MTTabBarItemTagViewer = 3
};

typedef NS_ENUM(NSUInteger, MTDocumentObjectBuilder) {
    MTDocumentObjectBuilderType,
    MTDocumentObjectBuilderValue
};

extern NSString * const MADUbiquityIdentifier;
//extern NSString * const MADFileExtentionMobleApplicationDocumentArchive;
//extern NSString * const MADFileExtentionMobleApplicationDocument;
//extern NSString * const MADTrademark;
//extern NSString * const MADIdentifierGroup;

extern NSString * const MTCollectionElementKindSectionLabel;

extern NSString * const MNSStringInterfaceButtonTitleContinue;
extern NSString * const MNSStringInterfaceButtonTitleContinueDesc;
extern NSString * const MNSStringInterfaceButtonTitleTryAgain;
extern NSString * const MNSStringInterfaceButtonTitleTryAgainDesc;
extern NSString * const MNSStringInterfaceButtonTitleAbort;
extern NSString * const MNSStringInterfaceButtonTitleAbortDesc;

// MARK: Storyboard Identifiers

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

// MARK: Segue Identifiers

#endif
