//
//  MADMacAppDelegate.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacAppDelegate_h
#define MADMacAppDelegate_h

#import <Cocoa/Cocoa.h>

@class MADMacAboutWindowController;

NS_ASSUME_NONNULL_BEGIN

@interface MADMacAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong, readonly) MADMacAboutWindowController *aboutWindowController;

- (void)newDocumentFromDatabase:(nullable id)sender;
- (void)showAboutWindow:(nullable id)sender;
- (void)showAboutOverview:(nullable id)sender;
- (void)showAboutLicensing:(nullable id)sender;
- (void)showAboutAcknowledgements:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacAppDelegate_h */
