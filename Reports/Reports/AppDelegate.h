//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApplicationSettings.h"
#import "MTManagedDocumentPreferencesUser.h"
#import "MTReportDocument.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (MTReportDocument *)activeDocument;
+ (void)setActiveDocument:(MTReportDocument *)activeDocument;
+ (BOOL)isPad;
+ (NSString *)storyboardName;

@end