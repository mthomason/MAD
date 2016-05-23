//
//  MADAccessibilityLine.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADAccessibilityLine.h"
#import <UIKit/UIGeometry.h>

@interface MADAccessibilityLine ()

    @property (nonatomic, strong) NSValue *rect;
    @property (nonatomic, strong) id value;
    @property (nonatomic, assign, readwrite) MTDocumentObjectType type;

@end

@implementation MADAccessibilityLine

- (instancetype)init {
    return [self initWithValue:@"" type:MTDocumentObjectTypeLabelStatic andFrame:CGRectZero];
}

- (instancetype)initWithValue:(id)value type:(MTDocumentObjectType)type andFrame:(CGRect)frame {
    if (self = [super init]) {

        NSValue *r = [NSValue valueWithCGRect:frame];
        self.rect = r;
        self.value = value;
        self.type = type;
    }
    return self;
}

- (NSString *)label { return [self.value debugDescription]; }

- (CGRect)frame { return self.rect.CGRectValue; }

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"Text:\t%@\n", self.label];
    [debug appendFormat:@"Rect:\t%@", NSStringFromCGRect(self.frame)];
    return debug;
}

@end
