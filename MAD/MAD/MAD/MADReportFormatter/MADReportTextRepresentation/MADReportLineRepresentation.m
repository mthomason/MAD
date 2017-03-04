//
//  MADReportLineRepresentation.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADReportLineRepresentation.h"
#import "MADDocumentObjectTypeDescriptor.h"

@interface MADReportLineRepresentation ()

    @property (nonatomic, strong) NSObject *object;

@end

@implementation MADReportLineRepresentation {
    MTDocumentObjectType _type;
}

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;
@synthesize frame = _frame;

- (void)dealloc { }

- (instancetype)init {
    return [self initWithObject:@"" type:MTDocumentObjectTypeLabelStatic frame:CGRectZero];
}

- (instancetype)initWithObject:(id)object type:(MTDocumentObjectType)type frame:(CGRect)frame {
    if (self = [super init]) {
        self.object = object;
        _frame = frame;
        _type = type;
    }
    return self;
}

- (NSString *)label {
    if ([self.object isKindOfClass:[NSString class]]) {
        return (NSString *)self.object;
    } else {
        return [MADDocumentObjectTypeDescriptor localizedStringForType:_type];
    }
}

#pragma mark - MADTextRepresentationProtocol

- (NSUInteger)characterCount {
    return self.label.length;
}

- (NSUInteger)elementCount {
    return 1;
}

@end
