//
//  MADReportLineRepresentation.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADReportLineRepresentation.h"
#import "MADDocumentObjectTypeDescriptor.h"

// The text-carrying drawing object's one property, declared here rather than imported:
// MADPrintPageElementText is an Apple-only class (MADSources.cmake), and this file
// compiles on both platforms.
@protocol MADReportLineTextElement <NSObject>
@property (nonatomic, readonly, copy) NSString *text;
@end

@interface MADReportLineRepresentation ()

	@property (nonatomic, strong) NSObject *object;

@end

@implementation MADReportLineRepresentation {
	MADPrintPageElementType _type;
}

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;
@synthesize frame = _frame;

- (void)dealloc {
	_object = nil;
}

- (instancetype)init {
	return [self initWithObject:@"" type:MADPrintPageElementTypeLabelStatic frame:CGRectZero];
}

- (instancetype)initWithObject:(id)object type:(MADPrintPageElementType)type frame:(CGRect)frame {
	if (self = [super init]) {
		self.object = object;
		_frame = frame;
		_type = type;
	}
	return self;
}

- (MADPrintPageElementType)elementType {
	return _type;
}

- (NSString *)label {
	if ([self.object isKindOfClass:[NSString class]]) {
		return (NSString *)self.object;
	} else {
		return [MADDocumentObjectTypeDescriptor localizedStringForType:_type];
	}
}

- (NSString *)text {
	id object = self.object;
	if ([object respondsToSelector: @selector(text)]) {
		return [(id <MADReportLineTextElement>)object text];
	}
	return nil;
}

#pragma mark - MADTextRepresentationProtocol

- (NSUInteger)characterCount { return self.label.length; }

- (NSUInteger)elementCount { return 1; }

@end
