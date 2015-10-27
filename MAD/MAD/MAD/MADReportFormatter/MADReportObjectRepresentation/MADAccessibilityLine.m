//
//  MADAccessibilityLine.m
//  MAD
//
//  Created by Michael Thomason on 10/25/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADAccessibilityLine.h"

@interface MADAccessibilityLine ()

@property (nonatomic, strong) NSValue *rect;
@property (nonatomic, copy) NSString *text;

@end

@implementation MADAccessibilityLine

- (instancetype)init {
    return [self initWithlabel:@"" andFrame:CGRectZero];
}

- (instancetype)initWithlabel:(NSString *)label andFrame:(CGRect)frame {
    if (self = [super init]) {
        NSValue *r = [NSValue valueWithCGRect:frame];
        self.rect = r;
        
        NSString *t = label.copy;
        self.text = t;
        
    }
    return self;
}

- (NSString *)label { return self.text; }

- (CGRect)frame { return self.rect.CGRectValue; }

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"Text:\t%@\n", self.label];
    [debug appendFormat:@"Rect:\t%@", NSStringFromCGRect(self.frame)];
    return debug;
}

@end
