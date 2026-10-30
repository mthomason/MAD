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

@interface MADMacQueryViewController : NSViewController

@property (nonatomic, weak, nullable) MADMacDocument *document;
@property (nonatomic, assign, readonly) MADMacQueryWorkspaceMode workspaceMode;

/// Width of the left-hand database schema table list (default 200px; user-resizable, fixed on window resize).
@property (nonatomic, assign, readonly) CGFloat schemaSidebarWidth;

/// Identifier of the currently selected query link on the visual canvas, or 0 if none.
@property (nonatomic, assign, readonly) int64_t selectedLinkIdentifier;

- (instancetype)initWithDocument:(MADMacDocument *)document;
- (void)reloadFromDocument;
- (void)switchToMode:(MADMacQueryWorkspaceMode)mode;

/// Adds a database schema table (and all of its schema fields) to the query and places it on the visual canvas.
- (nullable RptqQueryTable *)addSchemaTableToQuery:(RptqDatabaseSchemaTable *)schemaTable;

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
