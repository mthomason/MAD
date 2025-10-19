//
//  MADDesignerElementTextView.m
//  MAD Designer
//
//  Created by Michael on 5/22/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDesignerElementTextView.h"
#import <CoreData/NSManagedObjectContext.h>
#import <UIKit/NSStringDrawing.h>
#import <UIKit/NSParagraphStyle.h>
#import <MAD/UIFontDescriptor+MADAdditions.h>
#import <MAD/MADElementStylizedText.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqTextStyle.h>

@implementation MADDesignerElementTextView {
	double _fontsize;
	BOOL _bold;
	BOOL _italic;
	BOOL _underline;
	BOOL _strikethrough;
	int16_t _horizontal;
	NSString *_fontname;
}

@dynamic displayObject;

- (void)dealloc { }

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	RptqDocumentElement *element = (RptqDocumentElement *)[self.managedObjectContext objectWithID:self.objectID];
	[self.displayObject drawWithRect: [element innerRect]
							 options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
							 context: nil];
}

- (void)updateWithElement:(RptqDocumentElement *)element {
	[super updateWithElement:element];
	
	_fontname = element.fontname.copy;
	_fontsize = element.fontsize;
	_bold = element.textStyle.bold;
	_italic = element.textStyle.italic;
	_strikethrough = element.textStyle.strikethrough;
	_underline = element.textStyle.underline;
	_horizontal = element.alignment.horizontal;
	
	NSString *string = [element designerRepresentationText];
	
	MADElementStylizedText *attributesText;
	attributesText = [[MADElementStylizedText alloc] initWithFontName:element.fontname
															 fontSize:element.fontsize
															textStyle:element.textStyle
												  horizontalAlignment:element.alignment.horizontal];
	
	NSMutableAttributedString *attributtedString = [[NSMutableAttributedString alloc] initWithString: string
																						  attributes: attributesText.fontAttributes];
	self.displayObject = attributtedString;
}

- (void)updateFontName:(NSString *)fontname
			  fontSize:(double)fontsize
				  bold:(BOOL)bold
				italic:(BOOL)italic {
	if (_bold != bold || _italic != italic || _fontsize != fontsize || ![_fontname isEqualToString:fontname]) {
		UIFontDescriptor *fontDescriptor = [UIFontDescriptor newFontDescriptorForFontName: fontname
																				 fontSize: fontsize
																					 bold: bold
																				   italic: italic];

		UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:0.0];
		NSDictionary *newAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, nil];
		[self.displayObject addAttributes:newAttributes
									range:NSMakeRange(0, self.displayObject.length)];
		_fontname = fontname.copy;
		_fontsize = fontsize;
		_bold = bold;
		_italic = italic;
	}
}


- (void)updateHorizontalAlignment:(MADHorizontalAlignment)horizontal {
	if (_horizontal != horizontal) {
		NSMutableParagraphStyle *paragraphStyle = [self.displayObject attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:nil];
		switch (horizontal) {
			case MADHorizontalAlignmentLeft:
				paragraphStyle.alignment = NSTextAlignmentLeft;
				break;
			case MADHorizontalAlignmentRight:
				paragraphStyle.alignment = NSTextAlignmentRight;
				break;
			case MADHorizontalAlignmentCenter:
				paragraphStyle.alignment = NSTextAlignmentCenter;
				break;
			case MADHorizontalAlignmentJustified:
				paragraphStyle.alignment = NSTextAlignmentJustified;
				break;
			case MADHorizontalAlignmentNatrual:
				paragraphStyle.alignment = NSTextAlignmentNatural;
				break;
			default:
				paragraphStyle.alignment = NSTextAlignmentLeft;
				break;
		}
		[self.displayObject addAttribute:NSParagraphStyleAttributeName
								   value:paragraphStyle
								   range:NSMakeRange(0, self.displayObject.length)];
		_horizontal = horizontal;
	}
	
}

- (void)updateVerticalAlignment:(MADVerticalAlignment)vertical {
	
}

- (void)updateFontSize:(double)fontsize {
	if (_fontsize != fontsize) {
		UIFontDescriptor *fontDescriptor = [UIFontDescriptor newFontDescriptorForFontName: _fontname
																				 fontSize: fontsize
																					 bold: _bold
																				   italic: _italic];

		UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:0.0];
		NSDictionary *newAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, nil];
		[self.displayObject addAttributes:newAttributes
									range:NSMakeRange(0, self.displayObject.length)];
		_fontsize = fontsize;
	}
}

- (void)updateFontName:(NSString *)fontname {
	if (![_fontname isEqualToString:fontname]) {
		UIFontDescriptor *fontDescriptor = [UIFontDescriptor newFontDescriptorForFontName: fontname
																				 fontSize: _fontsize
																					 bold: _bold
																				   italic: _italic];
		UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:0.0];
		NSDictionary *newAttributes;
		newAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, nil];
		[self.displayObject addAttributes:newAttributes
									range:NSMakeRange(0, self.displayObject.length)];
		_fontname = fontname.copy;
	}
}

- (void)updateSetStrikethrough:(BOOL)strikethrough {
	if (_strikethrough != strikethrough) {
		NSNumber *strikethroughStyle = [[NSNumber alloc] initWithInteger: strikethrough ? NSUnderlineStyleSingle : NSUnderlineStyleNone];
		[self.displayObject addAttribute:NSStrikethroughStyleAttributeName
								   value:strikethroughStyle
								   range:NSMakeRange(0, self.displayObject.length)];
		_strikethrough = strikethrough;
	}
}

- (void)updateSetUnderline:(BOOL)underline {
	if (_underline != underline) {
		NSNumber *underlineStyle;
		underlineStyle = [[NSNumber alloc] initWithInteger: underline ? NSUnderlineStyleSingle : NSUnderlineStyleNone];
		[self.displayObject addAttribute:NSUnderlineStyleAttributeName
								   value:underlineStyle
								   range:NSMakeRange(0, self.displayObject.length)];
		_underline = underline;
	}
}

- (void)removeFromSuperview {
	[super removeFromSuperview];
}

@end
