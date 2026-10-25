//
//  MADReportLineRepresentation.h
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADReportLineRepresentation_h
#define MAD_MADReportLineRepresentation_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MADDocumentTextRepresentationProtocol.h>

#import <MAD/MADReportLineStyle.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADReportLineRepresentation : NSObject
	<MADTextRepresentationProtocol>

	- (instancetype)initWithObject:(id)object type:(MADPrintPageElementType)type
							 frame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

	/// Where the line sits *on its page*: the element's own frame, offset by the
	/// section it lives in, which is where the drawing would put it.
	@property (nonatomic, assign, readonly) CGRect frame;

	/// What kind of element the line drew.
	@property (nonatomic, assign, readonly) MADPrintPageElementType elementType;

	/// How the line's text is styled -- the font, its traits and the alignment.  Read
	/// off the element by the walk, inside its read transaction; a format that is not
	/// Core Graphics reads it here rather than asking the store again.
	@property (nullable, nonatomic, strong) MADReportLineStyle *style;

	- (NSString *)label;

	/// The element's resolved text -- a label's string, an aggregate's value -- or nil
	/// for an element that has none (an image).  -label answers the *type*'s name
	/// instead, which is what the representation's own text is made of; this is the
	/// content the json-report member serializes.
	- (nullable NSString *)text;

@end

NS_ASSUME_NONNULL_END

#endif
