//
//  AppDelegate.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIManagedDocumentTrvApplicationData.h"
#import "UIManagedDocumentTrvFileData.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UIManagedDocumentTrvApplicationData *applicationPreferences;
@property (retain, nonatomic) UIManagedDocumentTrvFileData *openReport;
@end