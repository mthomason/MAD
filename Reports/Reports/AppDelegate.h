//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTManagedDocumentPreferencesUser.h"
#import "MTReportDocument.h"
#import "UIDevice+Hack.h"
#import "CloudManager.h"
#import "MTStoreKitController.h"
#import "MTLog.h"

extern NSString * const MTBundleIdDesigner;
extern NSString * const MTBundleIdViewer;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (NSString *)storyboardName;
+ (NSString *)bundleId;
+ (BOOL)isMadViewer;
+ (BOOL)isMadDesigner;

@end
