//
//  MADDesignerLayout.m
//  MAD
//
//  Created by Michael on 8/21/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDesignerLayout.h"
#import <Foundation/NSBundle.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSUndoManager.h>
#import <Foundation/NSValue.h>
#import "MADocumentDesignerProtocol.h"
#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "RptqTextStyle.h"
#import "RptqRect.h"
#import "RptqSize.h"
#import "RptqAlignment.h"
#import "RptqDirectionalAsymmetry.h"
#import "RptqBorder.h"


@implementation MADDesignerLayout

- (void)_applyPerElementValues:(NSDictionary <NSNumber *, id> *)valuesByIdentifier
					actionName:(NSString *)actionName
						reader:(id (^)(RptqDocumentElement *element))reader
						writer:(void (^)(RptqDocumentElement *element, id value))writer {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSMutableDictionary <NSNumber *, id> *previousValues =
		[[NSMutableDictionary alloc] initWithCapacity:valuesByIdentifier.count];
	for (NSNumber *identifier in valuesByIdentifier) {
		RptqDocumentElement *element =
			[RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
												fromObjectContext:delegate.managedObjectContext];
		if (element == nil) {
			continue;
		}
		id oldVal = reader(element);
		previousValues[identifier] = oldVal ?: [NSNull null];
		id newVal = valuesByIdentifier[identifier];
		writer(element, (newVal == [NSNull null]) ? nil : newVal);
	}
	NSDictionary <NSNumber *, id> *capturedPrevious = [previousValues copy];
	NSString *capturedAction = [actionName copy];
	[delegate.undoManager setActionName:capturedAction];
	[delegate.undoManager registerUndoWithTarget:self handler:^(id _Nonnull target) {
		[(MADDesignerLayout *)target _applyPerElementValues:capturedPrevious
												 actionName:capturedAction
													 reader:reader
													 writer:writer];
	}];
}

- (void)_updateElements:(NSSet <NSNumber *> *)identifiers
		   uniformValue:(id)value
			 actionName:(NSString *)actionName
				 reader:(id (^)(RptqDocumentElement *element))reader
				 writer:(void (^)(RptqDocumentElement *element, id value))writer {
	NSMutableDictionary <NSNumber *, id> *values =
		[[NSMutableDictionary alloc] initWithCapacity:identifiers.count];
	id storedValue = value ?: [NSNull null];
	for (NSNumber *identifier in identifiers) {
		values[identifier] = storedValue;
	}
	[self _applyPerElementValues:values actionName:actionName reader:reader writer:writer];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers
			actionName:(NSString *)actionName
		 updateHandler:(void (^)(long long identifier))updateHandler
		   undoHandler:(void (^)(id target))undoHandler {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	for (NSNumber *identifier in identifiers) {
		updateHandler(identifier.longLongValue);
	}
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBold:(BOOL)bold {
	NSString *actionName = NSLocalizedString(bold ? @"Bold" : @"Disable Bold",
											 bold ? @"Bold" : @"Disable Bold");
	[self _updateElements:identifiers
			 uniformValue:@(bold)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.textStyle.bold); }
				   writer:^(RptqDocumentElement *element, id value) { element.textStyle.bold = [value boolValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setItalic:(BOOL)italic {
	NSString *actionName = NSLocalizedString(italic ? @"Italic" : @"Disable Italic",
											 italic ? @"Italic" : @"Disable Italic");
	[self _updateElements:identifiers
			 uniformValue:@(italic)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.textStyle.italic); }
				   writer:^(RptqDocumentElement *element, id value) { element.textStyle.italic = [value boolValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setStrikethrough:(BOOL)strikethrough {
	NSString *actionName = NSLocalizedString(strikethrough ? @"Strikethrough" : @"Disable Strikethrough",
											 strikethrough ? @"Strikethrough" : @"Disable Strikethrough");
	[self _updateElements:identifiers
			 uniformValue:@(strikethrough)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.textStyle.strikethrough); }
				   writer:^(RptqDocumentElement *element, id value) { element.textStyle.strikethrough = [value boolValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setUnderline:(BOOL)underline {
	NSString *actionName = NSLocalizedString(underline ? @"Underline" : @"Disable Underline",
											 underline ? @"Underline" : @"Disable Underline");
	[self _updateElements:identifiers
			 uniformValue:@(underline)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.textStyle.underline); }
				   writer:^(RptqDocumentElement *element, id value) { element.textStyle.underline = [value boolValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setFontsize:(double)fontsize {
	NSString *actionName = NSLocalizedString(@"Font Size", @"Font Size");
	[self _updateElements:identifiers
			 uniformValue:@(fontsize)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.fontsize); }
				   writer:^(RptqDocumentElement *element, id value) { element.fontsize = [value doubleValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setFontname:(NSString *)fontname {
	NSString *actionName = NSLocalizedString(@"Font Name %@", @"Font Name %@");
	actionName = [[NSString alloc] initWithFormat:actionName, fontname];
	[self _updateElements:identifiers
			 uniformValue:[fontname copy]
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return [element.fontname copy]; }
				   writer:^(RptqDocumentElement *element, id value) { element.fontname = [value copy]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setVerticalAlignment:(int16_t)verticalAlignment {
	NSString *actionName = NSLocalizedString(@"Vertical Alignment", @"Vertical Alignment");
	[self _updateElements:identifiers
			 uniformValue:@(verticalAlignment)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.alignment.vertical); }
				   writer:^(RptqDocumentElement *element, id value) { element.alignment.vertical = [value shortValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setHorizontalAlignment:(int16_t)horizontalAlignment {
	NSString *actionName = NSLocalizedString(@"Horizontal Alignment", @"Horizontal Alignment");
	[self _updateElements:identifiers
			 uniformValue:@(horizontalAlignment)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.alignment.horizontal); }
				   writer:^(RptqDocumentElement *element, id value) { element.alignment.horizontal = [value shortValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setSizeWidth:(float)width {
	NSString *actionName = NSLocalizedString(@"Size Width", @"Size Width");
	[self _updateElements:identifiers
			 uniformValue:@(width)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.rect.size.width); }
				   writer:^(RptqDocumentElement *element, id value) { element.rect.size.width = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setSizeHeight:(float)height {
	NSString *actionName = NSLocalizedString(@"Size Height", @"Size Height");
	[self _updateElements:identifiers
			 uniformValue:@(height)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.rect.size.height); }
				   writer:^(RptqDocumentElement *element, id value) { element.rect.size.height = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginBottom:(float)bottom {
	NSString *actionName = NSLocalizedString(@"Margin Bottom", @"Margin Bottom");
	[self _updateElements:identifiers
			 uniformValue:@(bottom)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.margin.bottom); }
				   writer:^(RptqDocumentElement *element, id value) { element.margin.bottom = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginTop:(float)top {
	NSString *actionName = NSLocalizedString(@"Margin Top", @"Margin Top");
	[self _updateElements:identifiers
			 uniformValue:@(top)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.margin.top); }
				   writer:^(RptqDocumentElement *element, id value) { element.margin.top = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginLeft:(float)left {
	NSString *actionName = NSLocalizedString(@"Margin Left", @"Margin Left");
	[self _updateElements:identifiers
			 uniformValue:@(left)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.margin.left); }
				   writer:^(RptqDocumentElement *element, id value) { element.margin.left = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginRight:(float)right {
	NSString *actionName = NSLocalizedString(@"Margin Right", @"Margin Right");
	[self _updateElements:identifiers
			 uniformValue:@(right)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.margin.right); }
				   writer:^(RptqDocumentElement *element, id value) { element.margin.right = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingBottom:(float)bottom {
	NSString *actionName = NSLocalizedString(@"Padding Bottom", @"Padding Bottom");
	[self _updateElements:identifiers
			 uniformValue:@(bottom)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.padding.bottom); }
				   writer:^(RptqDocumentElement *element, id value) { element.padding.bottom = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingTop:(float)top {
	NSString *actionName = NSLocalizedString(@"Padding Top", @"Padding Top");
	[self _updateElements:identifiers
			 uniformValue:@(top)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.padding.top); }
				   writer:^(RptqDocumentElement *element, id value) { element.padding.top = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingLeft:(float)left {
	NSString *actionName = NSLocalizedString(@"Padding Left", @"Padding Left");
	[self _updateElements:identifiers
			 uniformValue:@(left)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.padding.left); }
				   writer:^(RptqDocumentElement *element, id value) { element.padding.left = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingRight:(float)right {
	NSString *actionName = NSLocalizedString(@"Padding Right", @"Padding Right");
	[self _updateElements:identifiers
			 uniformValue:@(right)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.padding.right); }
				   writer:^(RptqDocumentElement *element, id value) { element.padding.right = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderBottom:(float)bottom {
	NSString *actionName = NSLocalizedString(@"Border Bottom", @"Border Bottom");
	[self _updateElements:identifiers
			 uniformValue:@(bottom)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.border.width.bottom); }
				   writer:^(RptqDocumentElement *element, id value) { element.border.width.bottom = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderTop:(float)top {
	NSString *actionName = NSLocalizedString(@"Border Top", @"Border Top");
	[self _updateElements:identifiers
			 uniformValue:@(top)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.border.width.top); }
				   writer:^(RptqDocumentElement *element, id value) { element.border.width.top = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderLeft:(float)left {
	NSString *actionName = NSLocalizedString(@"Border Left", @"Border Left");
	[self _updateElements:identifiers
			 uniformValue:@(left)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.border.width.left); }
				   writer:^(RptqDocumentElement *element, id value) { element.border.width.left = [value floatValue]; }];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderRight:(float)right {
	NSString *actionName = NSLocalizedString(@"Border Right", @"Border Right");
	[self _updateElements:identifiers
			 uniformValue:@(right)
			   actionName:actionName
				   reader:^id(RptqDocumentElement *element) { return @(element.border.width.right); }
				   writer:^(RptqDocumentElement *element, id value) { element.border.width.right = [value floatValue]; }];
}

@end
