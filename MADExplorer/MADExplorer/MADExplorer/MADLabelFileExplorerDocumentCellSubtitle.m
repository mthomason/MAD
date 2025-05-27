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
		self.textColor = [UIColor lightGrayColor];
		self.clipsToBounds = NO;
		self.numberOfLines = 0;
		self.backgroundColor = [UIColor clearColor];
		self.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.textColor = [UIColor lightGrayColor];
		self.clipsToBounds = NO;
		self.numberOfLines = 0;
		self.backgroundColor = [UIColor clearColor];
		self.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	}
	return self;
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
