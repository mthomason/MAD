//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIDevice+Hack.h"
#import "MACloudManager.h"
#import "MTStoreKitController.h"
#import "MTLog.h"
#import "NSURL+Document.h"

extern NSString * const MTBundleIdDesigner;
extern NSString * const MTBundleIdViewer;
extern NSString * const MTGlobalBundleVersion;
extern NSInteger  const MTGlobalBundleVersionMajor;
extern NSString * const MTGlobalBundleShortVersion;
extern NSString * const MTGlobalBundleRev;

@interface AppDelegate : UIResponder
    <UIApplicationDelegate,
        UIDocumentInteractionControllerDelegate,
        UIAlertViewDelegate>

@property (nonatomic, strong) UIWindow *window;

+ (NSString *)storyboardName;
+ (NSString *)bundleId;
+ (BOOL)isMadViewer;
+ (BOOL)isMadDesigner;
+ (NSString *)bundleVersion;

+ (NSAttributedString *)attributedStringMadDesigner;
+ (NSAttributedString *)attributedStringMadViewer;
+ (NSAttributedString *)attributedStringMadQuery;

- (UIFont *)mainFont;
- (UIFont *)detailFont;

@end
