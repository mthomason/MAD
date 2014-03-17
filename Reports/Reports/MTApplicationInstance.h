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
extern NSString * const MTBundleIdDesigner;
extern NSString * const MTBundleIdViewer;

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
    <MTDatabaseCacheProtocol>

@property (nonatomic, assign) MTReportState reportState;

@property (nonatomic, retain, readonly) MTUser *user;
@property (nonatomic, retain, readonly) MTReportDesigner *reportDesigner;
@property (nonatomic, retain, readonly) MTReportViewer *reportViewer;
@property (nonatomic, retain, readonly) MTQueryDesigner *queryDesigner;

- (void)openReport:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler;
- (void)closeReportWithCompletionHandler:(void (^)(BOOL))completionHandler;


- (MAReportDocument *)activeDocument;

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

@end

#endif
