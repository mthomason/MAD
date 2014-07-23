//
//  MTApplicaitonInstance.h
//  MAD
//
//  Created by Michael Thomason on 2/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTApplicationInstance_h
#define Reports_MTApplicationInstance_h

#import <Foundation/Foundation.h>
#import "MAReportDocument.h"

typedef NS_ENUM(NSUInteger, MTReportState) {
	MTReportStateOpen = 0,
	MTReportStateClosed
};

extern NSString * const MTBundleIdMadDesigner;
extern NSString * const MTBundleIdMadViewer;

extern NSString * const MTGlobalBundleVersion;
extern NSString * const MTGlobalBundleShortVersion;
extern NSString * const MTGlobalBundleRev;

extern NSString * const MTStoryboardReportDesigner;
extern NSString * const MTStoryboardReportDesignerPad;
extern NSString * const MTStoryboardReportDesignerLagacy;
extern NSString * const MTStoryboardReportDesignerPadLagacy;

extern NSString * const MTStoryboardReportViewer;
extern NSString * const MTStoryboardReportViewerPad;
extern NSString * const MTStoryboardReportViewerLagacy;
extern NSString * const MTStoryboardReportViewerPadLagacy;

@class MTReportDesigner, MTReportViewer, MTQueryDesigner, MTUser;

@interface MTApplicationInstance : NSObject

@property (nonatomic, assign) MTReportState reportState;

@property (nonatomic, strong, readonly) MTUser *user;
@property (nonatomic, strong, readonly) MTReportDesigner *reportDesigner;
@property (nonatomic, strong, readonly) MTReportViewer *reportViewer;
@property (nonatomic, strong, readonly) MTQueryDesigner *queryDesigner;

- (void)openReport:(NSURL *)url withCompletionHandler:(void (^)(BOOL))completionHandler;
- (void)closeReportWithCompletionHandler:(void (^)(BOOL))completionHandler;

- (MAReportDocument *)activeDocument;

- (void)initalizeAppearance;
- (id)mainWindow;
- (void)deleteCoreDataCache;
- (void)registerDefaultsFromSettingsBundle;

+ (NSString *)applicationName;
+ (NSAttributedString *)localizedAttributedApplicationNameMadDesigner;
+ (NSAttributedString *)localizedAttributedApplicationNameMadViewer;
+ (NSAttributedString *)localizedAttributedApplicationNameMadQuery;

+ (BOOL)isMadViewer;
+ (BOOL)isMadDesigner;
+ (NSString *)bundleId;
+ (NSString *)bundleVersion;

+ (UIStoryboard *)storyboard;

+ (void)drawMadWatermarkInRect:(CGRect)rect;
+ (NSString *)bundleDisplayName;

@end

#endif
