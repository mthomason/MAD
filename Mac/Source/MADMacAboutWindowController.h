//
//  MADMacAboutWindowController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacAboutWindowController_h
#define MADMacAboutWindowController_h

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MADMacAboutTab) {
	MADMacAboutTabOverview = 0,
	MADMacAboutTabLicensing = 1,
	MADMacAboutTabAcknowledgements = 2,
};

@interface MADMacAboutWindowController : NSWindowController

@property (nonatomic, assign, readonly) MADMacAboutTab selectedTab;
@property (nonatomic, strong, readonly) NSTextField *titleLabel;
@property (nonatomic, strong, readonly) NSTextField *subtitleLabel;
@property (nonatomic, strong, readonly) NSTextField *versionLabel;
@property (nonatomic, strong, readonly) NSTextField *copyrightLabel;
@property (nonatomic, strong, readonly) NSTextField *licenseSummaryLabel;
@property (nonatomic, strong, readonly) NSSegmentedControl *sectionSegmentedControl;
@property (nonatomic, strong, readonly) NSTextView *overviewTextView;
@property (nonatomic, strong, readonly) NSTextView *licensingTextView;
@property (nonatomic, strong, readonly) NSTableView *componentTableView;
@property (nonatomic, strong, readonly) NSTextView *acknowledgementsTextView;

- (instancetype)init;
- (instancetype)initWithBundle:(nullable NSBundle *)bundle;

- (void)switchToTab:(MADMacAboutTab)tab;
- (void)selectComponentAtIndex:(NSInteger)index;
- (void)openGitHubAction:(nullable id)sender;

+ (NSString *)bundleDisplayNameForBundle:(nullable NSBundle *)bundle;
+ (NSString *)versionTextForBundle:(nullable NSBundle *)bundle;
+ (NSString *)buildTextForBundle:(nullable NSBundle *)bundle;
+ (NSString *)humanReadableCopyrightForBundle:(nullable NSBundle *)bundle;
+ (NSString *)mitLicenseAndBrandNoticeText;

+ (NSAttributedString *)overviewAttributedText;
+ (NSAttributedString *)licensingAttributedTextFromBundle:(nullable NSBundle *)bundle;
+ (NSAttributedString *)acknowledgementsAttributedText;
+ (NSAttributedString *)acknowledgementsAttributedTextFromBundle:(nullable NSBundle *)bundle;
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)thirdPartyComponents;
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)bundledLicenseFiles;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacAboutWindowController_h */
