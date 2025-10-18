//
//  MADTextStyle.m
//  MADCocoaExtensions
//
//  Created by Michael on 2/1/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADTextStyle.h"
#import <Foundation/NSCoder.h>
#import <string.h>

struct MADTextStyle_t {
	BOOL bold;
	BOOL italic;
	BOOL underline;
	BOOL strikethrough;
};
typedef struct MADTextStyle_t MADTextStyle_t;

static inline MADTextStyle_t MADLayoutTextStyleMake(BOOL, BOOL, BOOL, BOOL);
static inline MADTextStyle_t MADLayoutTextStyleMake(BOOL b, BOOL i, BOOL u, BOOL s) {
	MADTextStyle_t style;
	style.bold = b;
	style.italic = i;
	style.underline = u;
	style.strikethrough = s;
	return style;
}

@implementation MADTextStyle {
	MADTextStyle_t _style;
}

@dynamic bold;
@dynamic italic;
@dynamic underline;
@dynamic strikethrough;

- (instancetype)initWithBold:(BOOL)bold italic:(BOOL)italic
				   underline:(BOOL)underline strikethrough:(BOOL)strikethrough {
	if (self = [super init]) {
		_style = MADLayoutTextStyleMake(bold, strikethrough, italic, underline);

	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		NSUInteger lenght;
		memcpy(&_style,
			   [aDecoder decodeBytesForKey:@"s" returnedLength:&lenght],
			   sizeof(MADTextStyle_t));
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeBytes:(uint8_t *)&_style length:sizeof(MADTextStyle_t) forKey:@"s"];
}

- (BOOL)bold {
	return _style.bold;
}

- (BOOL)italic {
	return _style.italic;
}

- (BOOL)underline {
	return _style.underline;
}

- (BOOL)strikethrough {
	return _style.strikethrough;
}

- (void)setBold:(BOOL)bold {
	_style.bold = bold;
}

- (void)setItalic:(BOOL)italic {
	_style.italic = italic;
}

- (void)setUnderline:(BOOL)underline {
	_style.underline = underline;
}

- (void)setStrikethrough:(BOOL)strikethrough {
	_style.strikethrough = strikethrough;
}

@end
