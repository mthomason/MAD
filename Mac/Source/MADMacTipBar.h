//
//  MADMacTipBar.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacTipBar_h
#define MADMacTipBar_h

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Posted by Help > Show Tips Again.  A visible tip bar shows itself again.
extern NSNotificationName const MADMacTipBarDidResetNotification;

/// A small, dismissible, localized first-run hint at the top of a workspace.  The
/// dismissal is remembered per identifier in NSUserDefaults.
@interface MADMacTipBar : NSView

/// `identifier` names the defaults key (for example "query"); `text` is already localized.
+ (instancetype)tipBarWithIdentifier:(NSString *)identifier text:(NSString *)text;

@property (nonatomic, copy, readonly) NSString *tipIdentifier;
@property (nonatomic, strong, readonly) NSTextField *textLabel;
@property (nonatomic, strong, readonly) NSButton *dismissButton;
@property (nonatomic, assign, readonly, getter=isDismissed) BOOL dismissed;

/// Shows the bar when this tip has not been dismissed.
- (void)showIfNeeded;

/// Marks this tip dismissed and hides the bar.
- (void)dismissTip:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacTipBar_h */
