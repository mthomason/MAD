//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApplicationSettings.h"
#import "UIManagedDocumentPreferencesUser.h"
#import "MNSDocumentReport.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (MNSDocumentReport *)activeDocument;
+ (void)setActiveDocument:(MNSDocumentReport *)activeDocument;
+ (BOOL)isPad;
+ (NSString *)storyboardName;

@end