//
//  MADMacDesignerViewController.h
//  MAD Designer (macOS Native)
//
//  Three-pane AppKit report layout studio:
//    - Top Workspace Bar: Element insertion palette (draggable & clickable), alignment
//      & auto-fit tools, grid/snap toggles, and zoom controls.
//    - Left Sidebar (default 220pt, user-resizable):
//        1. Interactive Page & Section Minimap + Report Sections outline
//        2. Query Fields Browser (drag onto canvas or double-click to insert)
//    - Center Pane: Scrollable, zoomable MADMacDesignerCanvasView with rulers, grid,
//      smart alignment guides, cross-section drag-and-drop, and 8-handle resizing.
//    - Right Inspector (default 260pt, user-resizable, scrollable):
//        Clearly divided into:
//        1. Document Page & Selected Section Card
//        2. Selected Element Inspector Cards (Identity & Section Assignment,
//           Content & Data Binding, Typography & Colors, Geometry & Box Model).
//

#import <Cocoa/Cocoa.h>

@class MADMacDocument;
@class MADMacDesignerCanvasView;
@class MADMacDesignerMinimapView;
@class RptqDocumentSection;
@class RptqDocumentElement;
@class RptqDocumentElementLabel;
@class RptqDocumentElementLabelDataField;
@class RptqDocumentElementAggregate;
@class RptqDocumentElementBarcode;
@class RptqDocumentElementImage;
@class RptqQueryField;

NS_ASSUME_NONNULL_BEGIN

/// The element kinds the Designer can insert.  The raw values are persisted nowhere; they
/// tag the Insert menu items and the canvas drag payload.
typedef NS_ENUM(NSInteger, MADMacPaletteElementKind) {
	MADMacPaletteElementKindLabel = 1,
	MADMacPaletteElementKindDataField = 2,
	MADMacPaletteElementKindAggregate = 3,
	MADMacPaletteElementKindImage = 4,
	MADMacPaletteElementKindBarcode = 5,
	MADMacPaletteElementKindLineRule = 6
};

@interface MADMacDesignerViewController : NSViewController

@property (nonatomic, weak, readonly, nullable) MADMacDocument *madDocument;
@property (nonatomic, strong, readonly) MADMacDesignerCanvasView *canvasView;
@property (nonatomic, strong, readonly) MADMacDesignerMinimapView *minimapView;

/// The field-list heading: "REPORT COLUMNS" for the Result or a composing node,
/// "QUERY FIELDS" for a leaf.
@property (nonatomic, strong, readonly) NSTextField *fieldsHeaderLabel;

/// The query-field list currently shown for the selected node (the search filter applied).
@property (nonatomic, copy, readonly) NSArray<RptqQueryField *> *displayedQueryFields;

/// The visible query-field table (its row count is the filtered list's count).
@property (nonatomic, strong, readonly) NSTableView *queryFieldsTableView;

/// The field-list search field (a non-empty filter narrows the visible list).
@property (nonatomic, strong, readonly) NSSearchField *queryFieldsSearchField;

@property (nonatomic, assign, readonly) CGFloat leftSidebarWidth;
@property (nonatomic, assign, readonly) CGFloat rightInspectorWidth;

- (instancetype)initWithDocument:(MADMacDocument *)document;
- (void)reloadFromDocument;

#pragma mark - Programmatic & Interactive Element Creation

- (nullable RptqDocumentElementLabel *)addStaticLabelInSection:(nullable RptqDocumentSection *)section
													   atPoint:(NSPoint)origin;
- (nullable RptqDocumentElementLabelDataField *)addDataField:(nullable RptqQueryField *)queryField
												   inSection:(nullable RptqDocumentSection *)section
													 atPoint:(NSPoint)origin;
- (nullable RptqDocumentElementAggregate *)addAggregateWithFunction:(int16_t)aggregateType
														 queryField:(nullable RptqQueryField *)queryField
														  inSection:(nullable RptqDocumentSection *)section
															atPoint:(NSPoint)origin;
- (nullable RptqDocumentElementBarcode *)addBarcodeInSection:(nullable RptqDocumentSection *)section
													 atPoint:(NSPoint)origin;
- (nullable RptqDocumentElementImage *)addImageInSection:(nullable RptqDocumentSection *)section
												 atPoint:(NSPoint)origin;
- (nullable RptqDocumentElementLabel *)addLineRuleInSection:(nullable RptqDocumentSection *)section
													atPoint:(NSPoint)origin;

- (void)addStaticLabelAction:(nullable id)sender;
- (void)addDataFieldAction:(nullable id)sender;
- (void)addAggregateAction:(nullable id)sender;
- (void)addBarcodeAction:(nullable id)sender;
- (void)addImageAction:(nullable id)sender;
- (void)addLineRuleAction:(nullable id)sender;

- (BOOL)moveSelectedElementsToSection:(RptqDocumentSection *)targetSection;
- (void)duplicateSelectedElementsAction:(nullable id)sender;
- (void)deleteSelectedElementsAction:(nullable id)sender;
- (void)sizeSelectedElementsToFitAction:(nullable id)sender;
- (void)autoFitSelectedSectionHeightAction:(nullable id)sender;

#pragma mark - Commands & State for the Menu Bar

@property (nonatomic, strong, readonly, nullable) NSPopUpButton *insertPopUpButton;
@property (nonatomic, assign, readonly) NSUInteger selectedElementCount;
@property (nonatomic, assign, readonly) BOOL canInsertElement;
@property (nonatomic, assign, readonly) BOOL canPasteElements;
@property (nonatomic, assign, readonly) BOOL leftSidebarVisible;
@property (nonatomic, assign, readonly) BOOL inspectorVisible;
@property (nonatomic, assign, readonly) BOOL minimapVisible;
@property (nonatomic, assign, readonly) BOOL gridVisible;
@property (nonatomic, assign, readonly) BOOL snapEnabled;
@property (nonatomic, assign, readonly) BOOL rulersVisible;

- (void)insertElementFromMenu:(NSMenuItem *)sender;
- (void)alignSelectedElementsWithMode:(NSInteger)mode;
- (void)toggleBoldStyleAction:(nullable id)sender;
- (void)toggleItalicStyleAction:(nullable id)sender;
- (void)toggleUnderlineStyleAction:(nullable id)sender;
- (void)copySelectedElementsAction:(nullable id)sender;
- (void)cutSelectedElementsAction:(nullable id)sender;
- (void)pasteElementsAction:(nullable id)sender;
- (void)selectAllElementsAction:(nullable id)sender;
- (void)zoomInAction:(nullable id)sender;
- (void)zoomOutAction:(nullable id)sender;
- (void)zoomActualSizeAction:(nullable id)sender;
- (void)toggleLeftSidebarAction:(nullable id)sender;
- (void)toggleInspectorAction:(nullable id)sender;
- (void)toggleMinimapAction:(nullable id)sender;
- (void)toggleGridFromMenu:(nullable id)sender;
- (void)toggleSnapFromMenu:(nullable id)sender;
- (void)toggleRulersFromMenu:(nullable id)sender;

/// Builds the element/section context menu.  Public so the smoke suite can check its
/// completeness without popping the menu up.
- (NSMenu *)buildContextMenuForElement:(nullable RptqDocumentElement *)element
							 inSection:(nullable RptqDocumentSection *)section;

@end

NS_ASSUME_NONNULL_END
