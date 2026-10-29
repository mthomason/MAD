//
//  MADMacDesignerCanvasView.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacDesignerCanvasView.h"
#import "MADMacDocument.h"

#import <MAD/MAD.h>
#import <MADBarcodes/MADBarcodes.h>

static const CGFloat kCanvasOuterMargin = 24.0;
static const CGFloat kSectionHeaderHeight = 26.0;
static const CGFloat kSectionResizeBarHeight = 6.0;
static const CGFloat kMinSectionContentHeight = 36.0;
static const CGFloat kElementResizeHandleSize = 8.0;

typedef NS_ENUM(NSInteger, MADMacCanvasDragMode) {
	MADMacCanvasDragModeNone = 0,
	MADMacCanvasDragModeMoveElement = 1,
	MADMacCanvasDragModeResizeElement = 2,
	MADMacCanvasDragModeResizeSection = 3,
};

@interface MADMacDesignerCanvasView ()

@property (nonatomic, strong, readwrite) NSMutableSet<NSNumber *> *selectedElementIdentifiers;
@property (nonatomic, assign) MADMacCanvasDragMode dragMode;
@property (nonatomic, strong, nullable) RptqDocumentElement *dragElement;
@property (nonatomic, strong, nullable) RptqDocumentSection *dragSection;
@property (nonatomic, assign) NSPoint dragStartPoint;
@property (nonatomic, assign) CGPoint initialElementOrigin;
@property (nonatomic, assign) CGSize initialElementSize;
@property (nonatomic, assign) CGFloat initialSectionHeight;

@end

@implementation MADMacDesignerCanvasView

- (instancetype)initWithFrame:(NSRect)frameRect {
	if (self = [super initWithFrame:frameRect]) {
		_zoomScale = 1.0;
		_selectedElementIdentifiers = [[NSMutableSet alloc] init];
	}
	return self;
}

- (BOOL)isFlipped {
	return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)setZoomScale:(CGFloat)zoomScale {
	_zoomScale = MAX(0.5, MIN(2.5, zoomScale));
	[self recalculateCanvasFrame];
	[self setNeedsDisplay:YES];
}

- (CGFloat)paperWidthPoints {
	RptqDocument *doc = _document.rptqDocument;
	if (doc != nil) {
		CGSize sz = [MTPaper sizeForType:(MTPaperType)doc.papersize];
		if (sz.width > 100.0) return sz.width;
	}
	return 612.0;
}

- (CGFloat)contentHeightForSection:(RptqDocumentSection *)section {
	CGFloat h = (CGFloat)section.layoutHeight;
	if (h < kMinSectionContentHeight) {
		h = MAX(kMinSectionContentHeight, (CGFloat)section.height - 44.0);
	}
	for (RptqDocumentSectionRows *row in section.hasRows) {
		for (RptqDocumentElement *el in row.hasObjects) {
			CGFloat bottom = (CGFloat)el.dropPoint.y + MAX(18.0, (CGFloat)el.rect.size.height) + 8.0;
			if (bottom > h) h = bottom;
		}
	}
	return MAX(kMinSectionContentHeight, h);
}

- (void)recalculateCanvasFrame {
	NSArray<RptqDocumentSection *> *sections = [_document orderedSections] ?: @[];
	if (_selectedSection == nil && sections.count > 0) {
		_selectedSection = _document.rptqDocument.hasDetailSection ?: sections.firstObject;
	}

	CGFloat totalUnscaledHeight = kCanvasOuterMargin * 2.0;
	for (RptqDocumentSection *section in sections) {
		totalUnscaledHeight += kSectionHeaderHeight + [self contentHeightForSection:section] + kSectionResizeBarHeight + 10.0;
	}

	CGFloat paperW = [self paperWidthPoints] + (kCanvasOuterMargin * 2.0);
	NSSize newSize = NSMakeSize(ceil(paperW * _zoomScale), ceil(MAX(640.0, totalUnscaledHeight) * _zoomScale));
	if (!NSEqualSizes(self.frame.size, newSize)) {
		[self setFrameSize:newSize];
	}
}

- (nullable RptqDocumentElement *)primarySelectedElement {
	NSNumber *firstID = _selectedElementIdentifiers.anyObject;
	if (firstID == nil || _document.managedObjectContext == nil) return nil;
	return [RptqDocumentElement newDocumentElementWithIdentifier:firstID.longLongValue
											   fromObjectContext:_document.managedObjectContext];
}

- (void)selectElement:(nullable RptqDocumentElement *)element inSection:(nullable RptqDocumentSection *)section {
	[_selectedElementIdentifiers removeAllObjects];
	if (element != nil) {
		[_selectedElementIdentifiers addObject:@(element.identifier)];
	}
	if (section != nil) {
		_selectedSection = section;
	}
	[self setNeedsDisplay:YES];
	[self.delegate canvasViewSelectionDidChange:self];
}

#pragma mark - Drawing

- (NSRect)elementRectInSectionContent:(RptqDocumentElement *)element {
	CGFloat x = (CGFloat)element.dropPoint.x;
	CGFloat y = (CGFloat)element.dropPoint.y;
	CGFloat w = MAX(32.0, (CGFloat)element.rect.size.width);
	CGFloat h = MAX(16.0, (CGFloat)element.rect.size.height);
	return NSMakeRect(x, y, w, h);
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];

	[[NSColor underPageBackgroundColor] setFill];
	NSRectFill(dirtyRect);

	NSGraphicsContext *nsCtx = [NSGraphicsContext currentContext];
	[nsCtx saveGraphicsState];

	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleBy:_zoomScale];
	[transform concat];

	CGFloat paperWidth = [self paperWidthPoints];
	NSArray<RptqDocumentSection *> *sections = [_document orderedSections] ?: @[];

	CGFloat yCursor = kCanvasOuterMargin;
	for (RptqDocumentSection *section in sections) {
		CGFloat contentH = [self contentHeightForSection:section];
		CGFloat totalSectionH = kSectionHeaderHeight + contentH + kSectionResizeBarHeight;
		NSRect sectionFrame = NSMakeRect(kCanvasOuterMargin, yCursor, paperWidth, totalSectionH);

		// Paper card background
		[[NSColor whiteColor] setFill];
		NSRectFill(sectionFrame);

		// Section Header Bar
		NSRect headerRect = NSMakeRect(kCanvasOuterMargin, yCursor, paperWidth, kSectionHeaderHeight);
		BOOL isSelectedSec = (_selectedSection != nil && _selectedSection.identifier == section.identifier);
		NSColor *headerColor = isSelectedSec
			? [NSColor colorWithCalibratedRed:0.16 green:0.38 blue:0.68 alpha:1.0]
			: [NSColor colorWithCalibratedWhite:0.25 alpha:1.0];
		[headerColor setFill];
		NSRectFill(headerRect);

		NSString *secTitle = [NSString stringWithFormat:@"%@   (%.0f pt)%@",
							  [_document displayTitleForSection:section],
							  contentH,
							  section.visibility ? @"" : @" [Hidden]"];
		NSDictionary *headerAttrs = @{
			NSFontAttributeName: [NSFont boldSystemFontOfSize:11.5],
			NSForegroundColorAttributeName: [NSColor whiteColor]
		};
		[secTitle drawInRect:NSMakeRect(headerRect.origin.x + 10.0, headerRect.origin.y + 5.0, headerRect.size.width - 20.0, 16.0)
			  withAttributes:headerAttrs];

		// Content Area + subtle 12pt grid
		NSRect contentRect = NSMakeRect(kCanvasOuterMargin, yCursor + kSectionHeaderHeight, paperWidth, contentH);
		[[NSColor colorWithCalibratedWhite:0.94 alpha:1.0] setStroke];
		NSBezierPath *grid = [NSBezierPath bezierPath];
		grid.lineWidth = 0.5;
		for (CGFloat gx = contentRect.origin.x + 12.0; gx < NSMaxX(contentRect); gx += 12.0) {
			[grid moveToPoint:NSMakePoint(gx, contentRect.origin.y)];
			[grid lineToPoint:NSMakePoint(gx, NSMaxY(contentRect))];
		}
		for (CGFloat gy = contentRect.origin.y + 12.0; gy < NSMaxY(contentRect); gy += 12.0) {
			[grid moveToPoint:NSMakePoint(contentRect.origin.x, gy)];
			[grid lineToPoint:NSMakePoint(NSMaxX(contentRect), gy)];
		}
		[grid stroke];

		// Elements in Section
		for (RptqDocumentSectionRows *row in section.hasRows) {
			for (RptqDocumentElement *element in row.hasObjects) {
				NSRect relRect = [self elementRectInSectionContent:element];
				NSRect absRect = NSOffsetRect(relRect, contentRect.origin.x, contentRect.origin.y);
				[self drawElement:element inRect:absRect];
			}
		}

		// Resize Handle Bar at Bottom of Section
		NSRect resizeBar = NSMakeRect(kCanvasOuterMargin, NSMaxY(contentRect), paperWidth, kSectionResizeBarHeight);
		[[NSColor colorWithCalibratedWhite:0.86 alpha:1.0] setFill];
		NSRectFill(resizeBar);

		[[NSColor colorWithCalibratedWhite:0.70 alpha:1.0] setStroke];
		NSFrameRectWithWidth(sectionFrame, 1.0);

		yCursor += totalSectionH + 10.0;
	}

	[nsCtx restoreGraphicsState];
}

- (void)drawElement:(RptqDocumentElement *)element inRect:(NSRect)rect {
	NSColor *bgColor = (NSColor *)element.backgroundColor;
	if ([bgColor isKindOfClass:[NSColor class]] && bgColor.alphaComponent > 0.01) {
		[bgColor setFill];
		NSRectFill(rect);
	} else {
		[[NSColor colorWithCalibratedRed:0.97 green:0.98 blue:1.0 alpha:0.85] setFill];
		NSRectFill(rect);
	}

	// Element content by type
	if ([element isKindOfClass:[RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *bcElem = (RptqDocumentElementBarcode *)element;
		NSString *sampleValue = bcElem.useStaticInput1 && bcElem.inputStatic1.length > 0
			? bcElem.inputStatic1
			: (bcElem.referencesField1.databaseSchemaField.name ?: @"123456789012");
		MADBarcode *barcode = [MADBarcode newBarcode:bcElem
											  input1:sampleValue
											  input2:(bcElem.inputStatic2 ?: @"")];
		[barcode drawInRect:NSInsetRect(rect, 2.0, 2.0)];
	} else if ([element isKindOfClass:[RptqDocumentElementImage class]]) {
		RptqDocumentElementImage *imgElem = (RptqDocumentElementImage *)element;
		NSImage *img = (NSImage *)imgElem.image;
		if ([img isKindOfClass:[NSImage class]]) {
			[img drawInRect:NSInsetRect(rect, 2.0, 2.0)];
		} else {
			NSDictionary *attrs = @{
				NSFontAttributeName: [NSFont systemFontOfSize:11.0],
				NSForegroundColorAttributeName: [NSColor secondaryLabelColor]
			};
			[@"[Image Element]" drawInRect:NSInsetRect(rect, 4.0, 2.0) withAttributes:attrs];
		}
	} else {
		NSString *display = [element designerRepresentationText];
		if (display.length == 0) {
			if ([element isKindOfClass:[RptqDocumentElementLabel class]]) {
				display = ((RptqDocumentElementLabel *)element).text ?: @"Label";
			} else {
				display = @"Element";
			}
		}

		NSString *fontFamily = element.fontname.length > 0 ? element.fontname : @"Helvetica";
		CGFloat fontSize = element.fontsize > 4.0 ? (CGFloat)element.fontsize : 12.0;
		NSFontDescriptor *desc = [NSFontDescriptor newFontDescriptorForFontName:fontFamily
																	   fontSize:fontSize
																		   bold:element.textStyle.bold
																		 italic:element.textStyle.italic];
		NSFont *font = [NSFont fontWithDescriptor:desc size:fontSize] ?: [NSFont systemFontOfSize:fontSize];

		NSMutableParagraphStyle *para = [[NSMutableParagraphStyle alloc] init];
		para.lineBreakMode = NSLineBreakByTruncatingTail;
		switch (element.alignment.horizontal) {
			case MADHorizontalAlignmentCenter: para.alignment = NSTextAlignmentCenter; break;
			case MADHorizontalAlignmentRight: para.alignment = NSTextAlignmentRight; break;
			case MADHorizontalAlignmentJustified: para.alignment = NSTextAlignmentJustified; break;
			default: para.alignment = NSTextAlignmentLeft; break;
		}

		NSColor *fgColor = [element.foregroundColor isKindOfClass:[NSColor class]]
			? (NSColor *)element.foregroundColor
			: [NSColor blackColor];

		NSMutableDictionary *attrs = [@{
			NSFontAttributeName: font,
			NSForegroundColorAttributeName: fgColor,
			NSParagraphStyleAttributeName: para,
		} mutableCopy];
		if (element.textStyle.underline) {
			attrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
		}
		if (element.textStyle.strikethrough) {
			attrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
		}

		NSRect textRect = NSInsetRect(rect, 3.0, 1.0);
		[display drawInRect:textRect withAttributes:attrs];
	}

	// Custom border if set
	CGFloat bTop = (CGFloat)element.border.width.top;
	CGFloat bBottom = (CGFloat)element.border.width.bottom;
	CGFloat bLeft = (CGFloat)element.border.width.left;
	CGFloat bRight = (CGFloat)element.border.width.right;
	if (bTop > 0 || bBottom > 0 || bLeft > 0 || bRight > 0) {
		[[NSColor blackColor] setStroke];
		NSFrameRectWithWidth(rect, MAX(1.0, MAX(MAX(bTop, bBottom), MAX(bLeft, bRight))));
	}

	// Selection outline & resize handle
	BOOL isSelected = [_selectedElementIdentifiers containsObject:@(element.identifier)];
	if (isSelected) {
		[[NSColor systemBlueColor] setStroke];
		NSFrameRectWithWidth(rect, 2.0);
		NSRect handleRect = NSMakeRect(NSMaxX(rect) - kElementResizeHandleSize,
									   NSMaxY(rect) - kElementResizeHandleSize,
									   kElementResizeHandleSize,
									   kElementResizeHandleSize);
		[[NSColor systemBlueColor] setFill];
		NSRectFill(handleRect);
	} else {
		[[NSColor colorWithCalibratedRed:0.55 green:0.65 blue:0.80 alpha:0.65] setStroke];
		NSFrameRectWithWidth(rect, 0.75);
	}
}

#pragma mark - Mouse & Keyboard Handling

- (NSPoint)unscaledPointFromEvent:(NSEvent *)event {
	NSPoint pt = [self convertPoint:event.locationInWindow fromView:nil];
	return NSMakePoint(pt.x / _zoomScale, pt.y / _zoomScale);
}

- (void)mouseDown:(NSEvent *)event {
	[self.window makeFirstResponder:self];
	NSPoint pt = [self unscaledPointFromEvent:event];
	CGFloat paperWidth = [self paperWidthPoints];
	NSArray<RptqDocumentSection *> *sections = [_document orderedSections] ?: @[];

	_dragMode = MADMacCanvasDragModeNone;
	_dragElement = nil;
	_dragSection = nil;

	CGFloat yCursor = kCanvasOuterMargin;
	for (RptqDocumentSection *section in sections) {
		CGFloat contentH = [self contentHeightForSection:section];
		CGFloat totalSectionH = kSectionHeaderHeight + contentH + kSectionResizeBarHeight;
		NSRect sectionFrame = NSMakeRect(kCanvasOuterMargin, yCursor, paperWidth, totalSectionH);
		NSRect contentRect = NSMakeRect(kCanvasOuterMargin, yCursor + kSectionHeaderHeight, paperWidth, contentH);
		NSRect resizeBar = NSMakeRect(kCanvasOuterMargin, NSMaxY(contentRect) - 2.0, paperWidth, kSectionResizeBarHeight + 4.0);

		if (NSPointInRect(pt, resizeBar)) {
			_selectedSection = section;
			_dragMode = MADMacCanvasDragModeResizeSection;
			_dragSection = section;
			_dragStartPoint = pt;
			_initialSectionHeight = contentH;
			[self setNeedsDisplay:YES];
			[self.delegate canvasViewSelectionDidChange:self];
			return;
		}

		if (NSPointInRect(pt, sectionFrame)) {
			_selectedSection = section;

			// Hit-test elements in reverse order (topmost first)
			RptqDocumentSectionRows *row = section.hasRows.firstObject;
			NSArray<RptqDocumentElement *> *elements = row.hasObjects.array ?: @[];
			for (RptqDocumentElement *element in [elements reverseObjectEnumerator]) {
				NSRect relRect = [self elementRectInSectionContent:element];
				NSRect absRect = NSOffsetRect(relRect, contentRect.origin.x, contentRect.origin.y);
				NSRect handleRect = NSMakeRect(NSMaxX(absRect) - kElementResizeHandleSize - 2.0,
											   NSMaxY(absRect) - kElementResizeHandleSize - 2.0,
											   kElementResizeHandleSize + 4.0,
											   kElementResizeHandleSize + 4.0);

				if ([_selectedElementIdentifiers containsObject:@(element.identifier)] && NSPointInRect(pt, handleRect)) {
					_dragMode = MADMacCanvasDragModeResizeElement;
					_dragElement = element;
					_dragStartPoint = pt;
					_initialElementSize = CGSizeMake(absRect.size.width, absRect.size.height);
					return;
				}

				if (NSPointInRect(pt, absRect)) {
					BOOL shift = (event.modifierFlags & NSEventModifierFlagShift) != 0;
					if (!shift && ![_selectedElementIdentifiers containsObject:@(element.identifier)]) {
						[_selectedElementIdentifiers removeAllObjects];
					}
					[_selectedElementIdentifiers addObject:@(element.identifier)];
					_dragMode = MADMacCanvasDragModeMoveElement;
					_dragElement = element;
					_dragStartPoint = pt;
					_initialElementOrigin = CGPointMake(element.dropPoint.x, element.dropPoint.y);
					[self setNeedsDisplay:YES];
					[self.delegate canvasViewSelectionDidChange:self];
					return;
				}
			}

			// Clicked empty space in section
			[_selectedElementIdentifiers removeAllObjects];
			[self setNeedsDisplay:YES];
			[self.delegate canvasViewSelectionDidChange:self];
			return;
		}

		yCursor += totalSectionH + 10.0;
	}
}

- (void)mouseDragged:(NSEvent *)event {
	if (_dragMode == MADMacCanvasDragModeNone) return;
	NSPoint pt = [self unscaledPointFromEvent:event];
	CGFloat dx = pt.x - _dragStartPoint.x;
	CGFloat dy = pt.y - _dragStartPoint.y;

	if (_dragMode == MADMacCanvasDragModeMoveElement && _dragElement != nil) {
		CGFloat newX = MAX(0.0, round(_initialElementOrigin.x + dx));
		CGFloat newY = MAX(0.0, round(_initialElementOrigin.y + dy));
		[_dragElement setOriginPoint:CGPointMake(newX, newY)];
		[self setNeedsDisplay:YES];
		[self.delegate canvasViewSelectionDidChange:self];
	} else if (_dragMode == MADMacCanvasDragModeResizeElement && _dragElement != nil) {
		CGFloat newW = MAX(24.0, round(_initialElementSize.width + dx));
		CGFloat newH = MAX(14.0, round(_initialElementSize.height + dy));
		[_dragElement setSizeWidth:(float)newW height:(float)newH];
		[self setNeedsDisplay:YES];
		[self.delegate canvasViewSelectionDidChange:self];
	} else if (_dragMode == MADMacCanvasDragModeResizeSection && _dragSection != nil) {
		CGFloat newH = MAX(kMinSectionContentHeight, round(_initialSectionHeight + dy));
		[_dragSection setInterfaceHeight:newH];
		[self recalculateCanvasFrame];
		[self setNeedsDisplay:YES];
		[self.delegate canvasViewSelectionDidChange:self];
	}
}

- (void)mouseUp:(NSEvent *) __unused event {
	if (_dragMode != MADMacCanvasDragModeNone) {
		_dragMode = MADMacCanvasDragModeNone;
		_dragElement = nil;
		_dragSection = nil;
		[self recalculateCanvasFrame];
		[_document notifyDocumentMutated];
		[self.delegate canvasViewDidMutateElements:self];
	}
}

- (void)keyDown:(NSEvent *)event {
	NSString *chars = event.charactersIgnoringModifiers;
	if (chars.length > 0) {
		unichar ch = [chars characterAtIndex:0];
		if (ch == NSDeleteCharacter || ch == NSBackspaceCharacter || ch == NSDeleteFunctionKey) {
			[self deleteSelectedElements:self];
			return;
		}
	}
	[super keyDown:event];
}

- (void)deleteSelectedElements:(nullable id) __unused sender {
	if (_selectedElementIdentifiers.count == 0) return;
	RptqStoreContext *ctx = _document.managedObjectContext;
	if (ctx == nil) return;

	for (NSNumber *ident in [_selectedElementIdentifiers copy]) {
		RptqDocumentElement *el = [RptqDocumentElement newDocumentElementWithIdentifier:ident.longLongValue
																	  fromObjectContext:ctx];
		if (el != nil) {
			RptqDocumentSectionRows *row = el.inSectionRow;
			if (row != nil) {
				NSMutableOrderedSet *objs = [row.hasObjects mutableCopy];
				[objs removeObject:el];
				row.hasObjects = objs;
			}
			[ctx deleteObject:el error:NULL];
		}
	}
	[_selectedElementIdentifiers removeAllObjects];
	[_document notifyDocumentMutated];
	[self setNeedsDisplay:YES];
	[self.delegate canvasViewSelectionDidChange:self];
}

@end
