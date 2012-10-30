//
//  AppDelegate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUIViewControllerOpenDocument.h"
#import "UIManagedDocumentTrvApplicationData.h"
#import "UIManagedDocumentTrvFileData.h"
#import <CoreData/CoreData.h>
#import "NSFileManager+Common.h"
#import "UIColor+EverydayApps.h"

#import "UINavigationControllerQueryDesigner.h"
#import "UINavigationControllerModelControllers.h"

@class MUIViewControllerOpenDocumentDelegate;

@interface AppDelegate : UIResponder <UIApplicationDelegate, MUIViewControllerOpenDocumentDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (retain) UIManagedDocumentQuery *managedDocumentQuery;

@property (retain, nonatomic) UIManagedDocumentTrvApplicationData *applicationPreferences;
@property (retain, nonatomic) UIManagedDocumentTrvFileData *openReport;

@end