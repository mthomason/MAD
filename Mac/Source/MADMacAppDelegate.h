//
//  MADMacAppDelegate.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacAppDelegate_h
#define MADMacAppDelegate_h

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADMacAppDelegate : NSObject <NSApplicationDelegate>

- (void)newDocumentFromDatabase:(nullable id)sender;
- (void)openLondonSample:(nullable id)sender;
- (void)openMusicSample:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacAppDelegate_h */
