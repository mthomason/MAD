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

@interface MADMacDesignerViewController : NSViewController

@property (nonatomic, weak, readonly, nullable) MADMacDocument *madDocument;
@property (nonatomic, strong, readonly) MADMacDesignerCanvasView *canvasView;
@property (nonatomic, strong, readonly) MADMacDesignerMinimapView *minimapView;

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

@end

NS_ASSUME_NONNULL_END
