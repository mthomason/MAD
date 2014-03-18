//
//  AppDelegate.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_AppDelegate_h
#define Reports_AppDelegate_h

#import <UIKit/UIKit.h>

@class MTApplicationInstance, MAReportDocument,
            RptqDocument, RptqDatabase, RptqQuery;
@interface AppDelegate : UIResponder
    <UIApplicationDelegate,
        UIDocumentInteractionControllerDelegate,
        UIAlertViewDelegate>

+ (MTApplicationInstance *)app;
+ (UIWindow *)window;

+ (MAReportDocument *)activeReportDocument;
+ (RptqDocument *)activeRptqDocument;
+ (RptqDatabase *)activeRptqDatabase;
+ (RptqQuery *)activeRptqQuery;


@property (nonatomic, strong) UIWindow *window;

- (UIFont *)mainFont;
- (UIFont *)detailFont;

@end

#endif