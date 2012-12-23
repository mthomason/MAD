//
//  AppDelegate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApplicationSettings.h"
#import "MTGraph.h"
#import "MUIViewControllerOpenDocument.h"
#import "UIManagedDocumentPreferencesApplication.h"
#import "UIManagedDocumentPreferencesUser.h"
#import <CoreData/CoreData.h>
#import "NSFileManager+Common.h"
#import "UIColor+EverydayApps.h"
#import "UINavigationControllerQueryDesigner.h"
#import "UINavigationControllerModelControllers.h"
#import "MNSDocumentReport.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (MNSDocumentReport *)activeDocument;
+ (void)setActiveDocument:(MNSDocumentReport *)activeDocument;

@end