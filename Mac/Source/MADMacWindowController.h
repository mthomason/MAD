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

/// The workspace currently shown (Query, Designer, or Viewer).  The menu bar and the
/// toolbar forward their commands to it.
@property (nonatomic, assign, readonly) MADMacWorkspaceTab activeWorkspaceTab;

/// The compact, persistent document-type label ("Standard Report" / "Composition
/// Report") shown in the window toolbar across all three workspaces.
@property (nonatomic, strong, readonly) NSTextField *documentTypeLabel;

/// The workspace switcher (labels Query / Designer / Viewer).
@property (nonatomic, strong, readonly, nullable) NSSegmentedControl *workspaceSegmentedControl;

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

/// Presents the native rename sheet for the open report.
- (void)presentRenameSheet:(nullable id)sender;

/// Menu-bar command dispatch.  The menu items use a nil target, so the responder chain
/// reaches these methods; each forwards to the view controller of the active workspace.
- (void)insertElementFromMenu:(NSMenuItem *)sender;
- (void)alignSelectedElementsFromMenu:(NSMenuItem *)sender;
- (void)formatSizeToFit:(nullable id)sender;
- (void)toggleBoldStyle:(nullable id)sender;
- (void)toggleItalicStyle:(nullable id)sender;
- (void)toggleUnderlineStyle:(nullable id)sender;
- (void)copySelection:(nullable id)sender;
- (void)cutSelection:(nullable id)sender;
- (void)pasteSelection:(nullable id)sender;
- (void)deleteSelection:(nullable id)sender;
- (void)duplicateSelection:(nullable id)sender;
- (void)selectAllInCanvas:(nullable id)sender;

- (void)queryAddSelectedTable:(nullable id)sender;
- (void)queryAddSource:(nullable id)sender;
- (void)queryImportReport:(nullable id)sender;
- (void)queryCreateRoot:(nullable id)sender;
- (void)queryShowOutputs:(nullable id)sender;
- (void)queryShowFilters:(nullable id)sender;
- (void)queryShowGroupings:(nullable id)sender;
- (void)queryRename:(nullable id)sender;
- (void)queryArrangeTables:(nullable id)sender;
- (void)queryEditConnection:(nullable id)sender;

- (void)viewerZoomIn:(nullable id)sender;
- (void)viewerZoomOut:(nullable id)sender;
- (void)viewerZoomActualSize:(nullable id)sender;
- (void)selectReportPaperTypeFromMenu:(NSMenuItem *)sender;
- (void)toggleDesignerLeftSidebar:(nullable id)sender;
- (void)toggleDesignerInspector:(nullable id)sender;
- (void)toggleDesignerMinimap:(nullable id)sender;
- (void)toggleQuerySchemaSidebar:(nullable id)sender;
- (void)toggleDesignerGrid:(nullable id)sender;
- (void)toggleDesignerSnap:(nullable id)sender;
- (void)toggleDesignerRulers:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacWindowController_h */
