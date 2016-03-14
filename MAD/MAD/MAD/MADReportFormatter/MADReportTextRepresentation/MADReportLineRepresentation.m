//
//  MADReportLineRepresentation.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADReportLineRepresentation.h"

@interface MADReportLineRepresentation ()

    @property (nonatomic, assign) MTDocumentObjectType type;
    @property (nonatomic, strong) NSObject *object;
    @property (nonatomic, assign, readwrite) CGRect frame;

    @property (nonatomic, readonly) NSString *label;

@end

@implementation MADReportLineRepresentation

@synthesize elementOffset = _elementOffset, characterOffset = _characterOffset;

- (instancetype)init {
    return [self initWithObject:@"" type:MTDocumentObjectTypeLabelStatic frame:CGRectZero];
}

- (instancetype)initWithObject:(id)object type:(MTDocumentObjectType)type frame:(CGRect)frame {
    if (self = [super init]) {
        self.object = object;
        self.frame = frame;
        self.type = type;
    }
    return self;
}

- (NSString *)label {
    if ([self.object isKindOfClass:[NSString class]]) {
        return (NSString *)self.object;
    } else {
        return [MADDocumentObjectType localizedStringForType:self.type];
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
