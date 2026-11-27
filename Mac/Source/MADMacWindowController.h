//
//  MADMacWindowController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacWindowController_h
#define MADMacWindowController_h

#import <Cocoa/Cocoa.h>

@class MADMacDocument, MADMacQueryViewController, MADMacDesignerViewController, MADMacViewerViewController, MADMacConnectionWindowController;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MADMacWorkspaceTab) {
	MADMacWorkspaceTabQuery = 0,
	MADMacWorkspaceTabDesigner = 1,
	MADMacWorkspaceTabViewer = 2,
};

@interface MADMacWindowController : NSWindowController <NSToolbarDelegate>

@property (nonatomic, weak, readonly, nullable) MADMacDocument *madDocument;
@property (nonatomic, strong, readonly) MADMacQueryViewController *queryViewController;
@property (nonatomic, strong, readonly) MADMacDesignerViewController *designerViewController;
@property (nonatomic, strong, readonly) MADMacViewerViewController *viewerViewController;
@property (nonatomic, strong, readonly, nullable) MADMacConnectionWindowController *activeConnectionSheetController;

/// The compact, persistent document-type label ("Standard Report" / "Composition
/// Report") shown in the window toolbar across all three workspaces.
@property (nonatomic, strong, readonly) NSTextField *documentTypeLabel;

/// The composition node picker (the Result and each source), shown in the toolbar only
/// for a Composition Report.  Nil for a Standard Report and before the toolbar is built.
@property (nonatomic, strong, readonly, nullable) NSPopUpButton *nodePickerPopup;

/// Refreshes the document-type label from the document model (`isComposed`).
- (void)refreshDocumentTypeLabel;

/// The node picker's action: sets the document's selection; every workspace follows.
- (void)nodePickerChanged:(NSPopUpButton *)sender;

- (instancetype)initWithDocument:(MADMacDocument *)document;
- (void)switchToWorkspaceTab:(MADMacWorkspaceTab)tab;
- (void)refreshReportAction:(nullable id)sender;
- (void)exportReportAction:(nullable id)sender;
- (void)printReportAction:(nullable id)sender;
- (void)editDatabaseConnectionAction:(nullable id)sender;
- (MADMacConnectionWindowController *)presentConnectionSettingsWithPrompt:(nullable NSString *)prompt
																onUpdated:(nullable void (^)(void))onUpdated;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacWindowController_h */
