//
//  MADMacDocumentController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacDocumentController_h
#define MADMacDocumentController_h

#import <Cocoa/Cocoa.h>

@class UTType;

NS_ASSUME_NONNULL_BEGIN

@interface MADMacDocumentController : NSDocumentController

/// Returns all UTType instances recognized as .mad report documents.
+ (NSArray<UTType *> *)allowedMadContentTypes;

/// Returns all UTI and filename-extension strings recognized as .mad report documents.
+ (NSArray<NSString *> *)allowedMadTypeIdentifiers;

/// Returns the currently active open panel, if one is currently visible.
@property (nonatomic, weak, readonly, nullable) NSOpenPanel *activeOpenPanel;

/// Dismisses the active open panel if currently visible.
- (void)dismissOpenPanelIfNeeded;

/// Returns the "New Document" button displayed in the bottom bar of the given open panel.
- (nullable NSButton *)newDocumentButtonForOpenPanel:(NSOpenPanel *)openPanel;

/// Action triggered by the "New Document" button in the open panel.
- (void)newDocumentFromOpenPanel:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacDocumentController_h */
