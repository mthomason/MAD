//
//  MADDesignerLayout.m
//  MAD
//
//  Created by Michael on 8/21/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerLayout.h"
#import <Foundation/NSBundle.h>
#import <Foundation/NSUndoManager.h>
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

- (void)updateElements:(NSSet <NSNumber *> *)identifiers
			actionName:(NSString *)actionName
		 updateHandler:(void (^)(long long identifier))updateHandler
		   undoHandler:(void (^)(id target))undoHandler {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	//NSString *actionName = NSLocalizedString(underline ? @"Font Size" : @"Font Size",
	//                                         underline ? @"Font Size" : @"Font Size");
	NSNumber *identifier;
	//RptqDocumentElement *element;
	//double previousFontsize = 0.0;
	for (identifier in identifiers) {
		updateHandler(identifier.longLongValue);
		//element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
		//                                              fromObjectContext:self.managedObjectContext];
		//previousFontsize = element.fontsize;
		//element.fontsize = fontsize;
	}
	//void (^undoHandler)(id target);
	//NSSet <NSNumber *> *elementIDs = identifiers.copy;
	//undoHandler = ^(id  _Nonnull target) {
	//    [(MADocument *)target updateElements:elementIDs setFontsize:previousFontsize];
	//};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBold:(BOOL)bold {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(bold ? @"Bold" : @"Disable Bold",
											 bold ? @"Bold" : @"Disable Bold");
	NSNumber *identifier;
	RptqDocumentElement *element;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		element.textStyle.bold = bold;
	}
	
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	if (bold) {
		undoHandler = ^(id  _Nonnull target) {
			[(typeof(self))target updateElements:elementIDs setBold:NO];
		};
	} else {
		undoHandler = ^(id  _Nonnull target) {
			[(typeof(self))target updateElements:elementIDs setBold:YES];
		};
	}
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setItalic:(BOOL)italic {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(italic ? @"Italic" : @"Disable Italic",
											 italic ? @"Italic" : @"Disable Italic");
	NSNumber *identifier;
	RptqDocumentElement *element;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		element.textStyle.italic = italic;
	}
	
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	if (italic) {
		undoHandler = ^(id  _Nonnull target) {
			[(typeof(self))target updateElements:elementIDs setItalic:NO];
		};
	} else {
		undoHandler = ^(id  _Nonnull target) {
			[(typeof(self))target updateElements:elementIDs setItalic:YES];
		};
	}
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setStrikethrough:(BOOL)strikethrough {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(strikethrough ? @"Strikethrough" : @"Disable Strikethrough",
											 strikethrough ? @"Strikethrough" : @"Disable Strikethrough");
	NSNumber *identifier;
	RptqDocumentElement *element;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		element.textStyle.strikethrough = strikethrough;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	if (strikethrough) {
		undoHandler = ^(id  _Nonnull target) {
			[(typeof(self))target updateElements:elementIDs setStrikethrough:NO];
		};
	} else {
		undoHandler = ^(id  _Nonnull target) {
			[(typeof(self))target updateElements:elementIDs setStrikethrough:YES];
		};
	}
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setUnderline:(BOOL)underline {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(underline ? @"Underline" : @"Disable Underline",
											 underline ? @"Underline" : @"Disable Underline");
	NSNumber *identifier;
	RptqDocumentElement *element;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		element.textStyle.underline = underline;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	if (underline) {
		undoHandler = ^(id  _Nonnull target) {
			[(typeof(self))target updateElements:elementIDs setUnderline:NO];
		};
	} else {
		undoHandler = ^(id  _Nonnull target) {
			[(typeof(self))target updateElements:elementIDs setUnderline:YES];
		};
	}
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setFontsize:(double)fontsize {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	// Was a copy-paste of the underline method: both branches are the same
	// string, and "underline" only resolved because an Apple header leaks an
	// enum constant by that name.
	NSString *actionName = NSLocalizedString(@"Font Size", @"Font Size");
	NSNumber *identifier;
	RptqDocumentElement *element;
	double previousFontsize = 0.0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previousFontsize = element.fontsize;
		element.fontsize = fontsize;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setFontsize:previousFontsize];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setFontname:(NSString *)fontname {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Font Name %@",
											 @"Font Name %@");
	actionName = [[NSString alloc] initWithFormat:actionName, fontname];
	NSNumber *identifier;
	RptqDocumentElement *element;
	NSString *previousFontname = nil;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		if (previousFontname == nil) previousFontname = element.fontname.copy;
		element.fontname = fontname.copy;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setFontname:previousFontname];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setVerticalAlignment:(int16_t)verticalAlignment {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Vertical Alignment",
											 @"Vertical Alignment");
	NSNumber *identifier;
	RptqDocumentElement *element;
	int16_t previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.alignment.vertical;
		element.alignment.vertical = verticalAlignment;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setVerticalAlignment:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setHorizontalAlignment:(int16_t)horizontalAlignment {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Horizontal Alignment",
											 @"Horizontal Alignment");
	NSNumber *identifier;
	RptqDocumentElement *element;
	int16_t previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.alignment.horizontal;
		element.alignment.horizontal = horizontalAlignment;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setHorizontalAlignment:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setSizeWidth:(float)width {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Size Width",
											 @"Size Width");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.rect.size.width;
		element.rect.size.width = width;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setSizeWidth:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setSizeHeight:(float)height {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Size Height",
											 @"Size Height");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.rect.size.height;
		element.rect.size.height = height;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setSizeHeight:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginBottom:(float)bottom {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Margin Bottom",
											 @"Margin Bottom");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.margin.bottom;
		element.margin.bottom = bottom;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setMarginBottom:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginTop:(float)top {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Margin Top",
											 @"Margin Top");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.margin.top;
		element.margin.top = top;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setMarginTop:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginLeft:(float)left {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Margin Left",
											 @"Margin Left");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.margin.left;
		element.margin.left = left;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setMarginLeft:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setMarginRight:(float)right {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Margin Right",
											 @"Margin Right");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.margin.right;
		element.margin.right = right;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setMarginRight:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingBottom:(float)bottom {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Padding Bottom",
											 @"Padding Bottom");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.padding.bottom;
		element.padding.bottom = bottom;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setPaddingBottom:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingTop:(float)top {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Padding Top",
											 @"Padding Top");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.padding.top;
		element.padding.top = top;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setPaddingTop:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingLeft:(float)left {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Padding Left",
											 @"Padding Left");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.padding.left;
		element.padding.left = left;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setPaddingLeft:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setPaddingRight:(float)right {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Padding Right",
											 @"Padding Right");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.padding.right;
		element.padding.right = right;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setPaddingRight:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderBottom:(float)bottom {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Border Bottom",
											 @"Border Bottom");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.border.width.bottom;
		element.border.width.bottom = bottom;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setBorderBottom:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderTop:(float)top {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Border Top",
											 @"Border Top");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.border.width.top;
		element.border.width.top = top;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setBorderTop:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderLeft:(float)left {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Border Left",
											 @"Border Left");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.border.width.left;
		element.border.width.left = left;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setBorderLeft:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

- (void)updateElements:(NSSet <NSNumber *> *)identifiers setBorderRight:(float)right {
	id <MADocumentDesignerProtocol> delegate = _delegate;
	NSString *actionName = NSLocalizedString(@"Border Right",
											 @"Border Right");
	NSNumber *identifier;
	RptqDocumentElement *element;
	float previous = 0;
	for (identifier in identifiers) {
		element = [RptqDocumentElement newDocumentElementWithIdentifier:identifier.longLongValue
													  fromObjectContext:delegate.managedObjectContext];
		previous = element.border.width.right;
		element.border.width.right = right;
	}
	void (^undoHandler)(id target);
	NSSet <NSNumber *> *elementIDs = identifiers.copy;
	undoHandler = ^(id  _Nonnull target) {
		[(typeof(self))target updateElements:elementIDs setBorderRight:previous];
	};
	[delegate.undoManager setActionName:actionName];
	[delegate.undoManager registerUndoWithTarget:self handler:undoHandler];
}

@end
