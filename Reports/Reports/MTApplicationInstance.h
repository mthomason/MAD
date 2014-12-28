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

typedef NS_ENUM(NSUInteger, MTReportState) {
	MTReportStateOpen = 0,
	MTReportStateClosed
};

extern NSString * const MTBundleIdMadDesigner;
extern NSString * const MTBundleIdMadViewer;

extern NSString * const MTGlobalBundleVersion;
extern NSString * const MTGlobalBundleShortVersion;
extern NSString * const MTGlobalBundleRev;

@class MADocument, MTReportDesigner, MTReportViewer, MTQueryDesigner, MTUser, MADFileManager;

@interface MTApplicationInstance : NSObject

@property (nonatomic, assign) MTReportState reportState;

@property (nonatomic, strong, readonly) MTUser *user;
@property (nonatomic, strong, readonly) MTReportDesigner *reportDesigner;
@property (nonatomic, strong, readonly) MTReportViewer *reportViewer;
@property (nonatomic, strong, readonly) MTQueryDesigner *queryDesigner;

@property (nonatomic, strong, readonly) MADFileManager *fileManager;

- (void)initalizeAppearance;
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

+ (NSString *)madDesigner;
+ (NSString *)madViewer;
+ (NSString *)madQuery;

+ (void)drawMadWatermarkInRect:(CGRect)rect;
+ (NSString *)bundleDisplayName;

- (void)closeReportWithCompletionHandler:(void (^)(BOOL))completionHandler;
- (MADocument *)openDocument;

@end

#endif
