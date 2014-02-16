//
//  MTApplicaitonInstance.h
//  MAD
//
//  Created by Michael Thomason on 2/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@interface MTApplicaitonInstance : NSObject

+ (NSString *)applicationName;
+ (NSAttributedString *)localizedAttributedApplicationNameMadDesigner;
+ (NSAttributedString *)localizedAttributedApplicationNameMadViewer;
+ (NSAttributedString *)localizedAttributedApplicationNameMadQuery;

+ (BOOL)isMadViewer;
+ (BOOL)isMadDesigner;
+ (NSString *)bundleId;
+ (NSString *)bundleVersion;

- (void)setActiveDocument:(id)document;
- (id)activeDocument;

+ (UIStoryboard *)storyboard;

@end
