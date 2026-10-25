//
//  Constants.m
//  Reports
//
//  Created by Michael Thomason on 1/5/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "Constants.h"

#pragma mark Common UI Strings

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

const CGFloat MNSTableViewCellQueryInputHeightDefault = 100.0000f;
