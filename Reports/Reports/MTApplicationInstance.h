//
//  MTApplicaitonInstance.h
//  MAD
//
//  Created by Michael Thomason on 2/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

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
extern NSInteger  const MTGlobalBundleVersionMajor;
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

@interface MTApplicationInstance : NSObject
    <MAReportDocumentCacheProtocol>

@property (nonatomic, assign) MTReportState reportState;

- (void)openReport:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler;

+ (NSString *)applicationName;
+ (NSAttributedString *)localizedAttributedApplicationNameMadDesigner;
+ (NSAttributedString *)localizedAttributedApplicationNameMadViewer;
+ (NSAttributedString *)localizedAttributedApplicationNameMadQuery;

+ (BOOL)isMadViewer;
+ (BOOL)isMadDesigner;
+ (NSString *)bundleId;
+ (NSString *)bundleVersion;

- (void)setActiveDocument:(MAReportDocument *)document;
- (MAReportDocument *)activeDocument;

+ (UIStoryboard *)storyboard;

@end
