//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADReportLineStyle.m
//  MAD
//
//  See MADReportLineStyle.h.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportLineStyle.h"

#import "RptqAlignment.h"
#import "RptqDocumentElement.h"
#import "RptqTextStyle.h"

@implementation MADReportLineStyle

+ (instancetype)styleForElement:(RptqDocumentElement *)element {
	MADReportLineStyle *style = [[self alloc] init];
	if (style == nil) return nil;	// ! nil returned from a method that is expected to return a non-null value

	style->_fontName = [element.fontname copy];
	style->_fontSize = element.fontsize;

	RptqTextStyle *textStyle = element.textStyle;
	style->_bold = textStyle.bold;
	style->_italic = textStyle.italic;
	style->_underline = textStyle.underline;
	style->_strikethrough = textStyle.strikethrough;

	RptqAlignment *alignment = element.alignment;
	style->_horizontalAlignment = (MADHorizontalAlignment)alignment.horizontal;

	return style;
}

@end
