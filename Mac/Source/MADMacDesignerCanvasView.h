//
//  MADMacDesignerCanvasView.h
//  MAD Designer (macOS Native)
//
//  Interactive AppKit report layout canvas displaying proportional paper bands
//  for each RptqDocumentSection (Report Header, Page Header, Group Headers,
//  Detail, Group Footers, Page Footer, Report Footer), with rulers, grid,
//  smart alignment guides, cross-section drag & drop, 8-handle element resizing,
//  rubber-band marquee selection, and inline label editing.
//

#import <Cocoa/Cocoa.h>

@class MADMacDocument;
@class RptqDocumentSection;
@class RptqDocumentElement;
@class RptqDocumentElementLabel;
@class MADMacDesignerCanvasView;

NS_ASSUME_NONNULL_BEGIN

/// Pasteboard type for dragging a query field (payload: string of fieldNumber) onto the canvas.
extern NSPasteboardType const MADMacDesignerPasteboardTypeQueryField;

/// Pasteboard type for dragging an element tool kind (payload: string of MADElementType integer) onto the canvas.
extern NSPasteboardType const MADMacDesignerPasteboardTypeElementKind;

@protocol MADMacDesignerCanvasViewDelegate <NSObject>
@optional
- (void)designerCanvasSelectionDidChange:(MADMacDesignerCanvasView *)canvasView;
- (void)designerCanvasDidMutateDocument:(MADMacDesignerCanvasView *)canvasView;
/// Called on mouseUp after an interactive element move (within the same section) or resize completes.
/// Each dictionary contains: @"element", @"oldOrigin" (NSValue Point), @"oldSize" (NSValue Size),
/// @"newOrigin" (NSValue Point), @"newSize" (NSValue Size).
- (void)designerCanvas:(MADMacDesignerCanvasView *)canvasView
	didCommitElementGeometry:(NSArray<NSDictionary<NSString *, id> *> *)changes;
/// Called on mouseUp after elements are dragged to a different section or moved with section change.
/// Each dictionary contains: @"element", @"oldSection", @"newSection",
/// @"oldOrigin" (NSValue Point), @"newOrigin" (NSValue Point).
- (void)designerCanvas:(MADMacDesignerCanvasView *)canvasView
	didMoveElements:(NSArray<NSDictionary<NSString *, id> *> *)moves;
/// Called on mouseUp after an interactive section height drag completes.
- (void)designerCanvas:(MADMacDesignerCanvasView *)canvasView
	didCommitSectionResize:(RptqDocumentSection *)section
				 oldHeight:(CGFloat)oldHeight
				 newHeight:(CGFloat)newHeight;
/// Called when a query field is dropped from the sidebar onto a canvas section.
- (void)designerCanvas:(MADMacDesignerCanvasView *)canvasView
	didDropQueryFieldWithIdentifier:(int64_t)fieldIdentifier
						  inSection:(RptqDocumentSection *)section
							atPoint:(NSPoint)dropPoint;
/// Called when an element palette item is dropped onto a canvas section.
- (void)designerCanvas:(MADMacDesignerCanvasView *)canvasView
	didDropElementKind:(NSInteger)elementKind
			 inSection:(RptqDocumentSection *)section
			   atPoint:(NSPoint)dropPoint;
/// Called when the user right-clicks an element or section on the canvas.
- (void)designerCanvas:(MADMacDesignerCanvasView *)canvasView
	requestContextMenuForElement:(nullable RptqDocumentElement *)element
					   inSection:(nullable RptqDocumentSection *)section
					   withEvent:(NSEvent *)event;
/// Called when the user finishes inline editing of a static label on the canvas.
- (void)designerCanvas:(MADMacDesignerCanvasView *)canvasView
	didInlineEditLabel:(RptqDocumentElementLabel *)label
			   oldText:(NSString *)oldText
			   newText:(NSString *)newText;
- (void)designerCanvasRequestDeleteSelection:(MADMacDesignerCanvasView *)canvasView;
- (void)designerCanvasRequestDuplicateSelection:(MADMacDesignerCanvasView *)canvasView;
@end

@interface MADMacDesignerCanvasView : NSView

@property (nonatomic, weak, nullable) MADMacDocument *document;
@property (nonatomic, weak, nullable) id<MADMacDesignerCanvasViewDelegate> delegate;

@property (nonatomic, assign) CGFloat zoomScale;
@property (nonatomic, assign) BOOL showGrid;
@property (nonatomic, assign) BOOL snapToGrid;
@property (nonatomic, assign) BOOL showRulers;
@property (nonatomic, assign) CGFloat gridSpacing;

@property (nonatomic, strong, nullable) RptqDocumentSection *selectedSection;
@property (nonatomic, strong, readonly) NSOrderedSet<RptqDocumentElement *> *selectedElements;
@property (nonatomic, strong, nullable, readonly) RptqDocumentElement *primarySelectedElement;

- (void)selectElement:(nullable RptqDocumentElement *)element extendSelection:(BOOL)extend;
- (void)setSelectedElementsSet:(NSOrderedSet<RptqDocumentElement *> *)elements;
- (void)clearElementSelection;
- (void)selectAllElementsInSelectedSection;

- (NSArray<RptqDocumentSection *> *)orderedSections;
- (nullable RptqDocumentSection *)sectionContainingElement:(RptqDocumentElement *)element;
- (NSArray<RptqDocumentElement *> *)elementsInSection:(RptqDocumentSection *)section;

/// Reads the authoritative section-local frame (using element.rect.origin and element.rect.size).
- (NSRect)elementRectInSectionContent:(RptqDocumentElement *)element;

/// Sets both element.rect.origin (via setOriginPoint:) and element.dropPoint so they stay synchronized.
- (void)setElement:(RptqDocumentElement *)element originInSectionContent:(NSPoint)origin;

/// Computes a non-overlapping placement point in the given section for a new element of the given size.
- (NSPoint)nextAvailableOriginInSection:(RptqDocumentSection *)section forElementSize:(NSSize)size;

/// Transfers an element from its current section row to targetSection's first row and updates its origin.
- (BOOL)moveElement:(RptqDocumentElement *)element
		  toSection:(RptqDocumentSection *)targetSection
		   atOrigin:(NSPoint)origin;

/// Scrolls the enclosing scroll view so the specified section is visible.
- (void)scrollToSection:(RptqDocumentSection *)section;

/// Begins inline text editing on a static label element.
- (void)beginInlineEditingForLabel:(RptqDocumentElementLabel *)label;

- (void)recalculateCanvasSize;

@end

/// Interactive miniature overview of the report page, section bands, positioned elements,
/// and the visible scroll viewport.
@interface MADMacDesignerMinimapView : NSView

@property (nonatomic, weak, nullable) MADMacDesignerCanvasView *canvasView;

@end

NS_ASSUME_NONNULL_END
