//
//  MADLabelFileExplorerDocumentCellSubtitle.m
//  MADExplorer
//
//  Created by Michael Thomason on 6/21/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADLabelFileExplorerDocumentCellSubtitle.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADLabelFileExplorerDocumentCellSubtitle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		[MADLabelFileExplorerDocumentCellSubtitle commonInitalization:self];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[MADLabelFileExplorerDocumentCellSubtitle commonInitalization:self];
	}
	return self;
}

+ (void)commonInitalization:(MADLabelFileExplorerDocumentCellSubtitle *)this {

	UIColor *clearColor = [UIColor clearColor];
	UIColor *lightGrayColor = [UIColor lightGrayColor];
	this.textColor = lightGrayColor;
	this.clipsToBounds = NO;
	this.numberOfLines = 0;
	this.backgroundColor = clearColor;
	this.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	
}

- (UIColor *)highlightedTextColor {
	return _selected ? [UIColor whiteColor] : [MADColorEverydayApps newColorRed];
}

- (void)setSelected:(BOOL)selected {
	if (_selected != selected) {
		_selected = selected;
		[self setNeedsDisplay];
	}
}

@end
