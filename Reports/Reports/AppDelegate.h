//
//  AppDelegate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApplicationSettings.h"
#import "MUIViewControllerOpenDocument.h"
#import "UIManagedDocumentPreferencesApplication.h"
#import "UIManagedDocumentPreferencesUser.h"
#import <CoreData/CoreData.h>
#import "NSFileManager+Common.h"
#import "UIColor+EverydayApps.h"
#import "UINavigationControllerQueryDesigner.h"
#import "UINavigationControllerModelControllers.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, MUIViewControllerOpenDocumentDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (retain) UIManagedDocumentReport *managedDocumentQuery;

@property (retain, nonatomic) UIManagedDocumentPreferencesApplication *applicationPreferences;
@property (retain, nonatomic) UIManagedDocumentPreferencesUser *openReport;

@end