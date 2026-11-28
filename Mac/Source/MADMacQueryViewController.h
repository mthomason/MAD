//
//  MADMacQueryViewController.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacQueryViewController_h
#define MADMacQueryViewController_h

#import <Cocoa/Cocoa.h>
#import <MAD/MAD.h>

@class MADMacDocument;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MADMacQueryWorkspaceMode) {
	MADMacQueryWorkspaceModeDesigner = 0,
	MADMacQueryWorkspaceModeSQL = 1,
};

@interface MADMacQueryViewController : NSViewController <NSMenuItemValidation>

@property (nonatomic, weak, nullable) MADMacDocument *document;
@property (nonatomic, assign, readonly) MADMacQueryWorkspaceMode workspaceMode;

/// Width of the left-hand database schema table list (default 200px; user-resizable, fixed on window resize).
@property (nonatomic, assign, readonly) CGFloat schemaSidebarWidth;

/// Identifier of the currently selected query link on the visual canvas, or 0 if none.
@property (nonatomic, assign, readonly) int64_t selectedLinkIdentifier;

- (instancetype)initWithDocument:(MADMacDocument *)document;
- (void)reloadFromDocument;
- (void)switchToMode:(MADMacQueryWorkspaceMode)mode;

/// The query the workspace edits (the document's selection, or its report query).
- (nullable RptqQuery *)selectedQuery;

/// State used by the menu bar to enable and title its commands.
@property (nonatomic, assign, readonly) BOOL editingRootQuery;
@property (nonatomic, assign, readonly) BOOL editingComposingNode;
@property (nonatomic, assign, readonly) BOOL canAddSelectedTable;
@property (nonatomic, assign, readonly) BOOL canCreateRoot;
@property (nonatomic, assign, readonly) BOOL schemaSidebarVisible;

/// Query authoring actions (also reachable from the menu bar and the top-bar menus).
- (void)addSelectedSchemaTable:(nullable id)sender;
- (void)addSourceQueryAction:(nullable id)sender;
- (void)importChildQueryAction:(nullable id)sender;
- (void)addRootQueryAction:(nullable id)sender;
- (void)toggleOutputsPopover:(nullable id)sender;
- (void)toggleFiltersPopover:(nullable id)sender;
- (void)toggleGroupsPopover:(nullable id)sender;
- (void)renameQueryAction:(nullable id)sender;
- (void)autoArrangeTablesAction:(nullable id)sender;
- (void)editDatabaseConnectionAction:(nullable id)sender;
- (void)toggleSchemaSidebarAction:(nullable id)sender;

/// Adds a database schema table (and all of its schema fields) to the query and places it on the visual canvas.
- (nullable RptqQueryTable *)addSchemaTableToQuery:(RptqDatabaseSchemaTable *)schemaTable;

/// Adds a source query as a table of the composed root (creating a root query field per
/// source field), when the root is the selected query.
- (nullable RptqQueryTable *)addUpstreamQueryToRoot:(RptqQuery *)sourceQuery;

/// Removes a query table (and any connected links, groups, predicates, and bound elements) from the query.
- (void)removeQueryTable:(RptqQueryTable *)queryTable;

/// Connects a field in one query table to a field in another query table with a default Left Outer Join.
- (nullable RptqQueryLinks *)connectQueryField:(RptqQueryField *)leftField
								  toQueryField:(RptqQueryField *)rightField;

/// Selects a visual link on the canvas and optionally presents the join-type editor popover.
- (void)selectQueryLink:(nullable RptqQueryLinks *)link showPopover:(BOOL)showPopover;

/// Modifies the join type (e.g. MADLinkTypeLeftOuterJoin, MADLinkTypeInnerJoin, etc.) of an existing query link.
- (void)updateQueryLink:(RptqQueryLinks *)link joinType:(MADLinkType)joinType;

/// Deletes an existing query link from the query.
- (void)deleteQueryLink:(RptqQueryLinks *)link;

/// Returns the floating AppKit table card view for the given RptqQueryTable identifier, if present on the canvas.
- (nullable NSView *)tableCardViewForQueryTableID:(int64_t)queryTableID;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacQueryViewController_h */
