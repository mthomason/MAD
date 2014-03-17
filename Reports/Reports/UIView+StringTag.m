//
//  UIView+ObjectTag.m
//  Reports
//
//  Created by Michael Thomason on 12/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIView+StringTag.h"
#import <objc/runtime.h>

static char const * const StringTagKey = "StringTag";

@implementation UIView (StringTag)
@dynamic stringTag;

- (id)stringTag {
    return objc_getAssociatedObject(self, StringTagKey);
}

- (void)setStringTag:(id)newObjectTag {
    objc_setAssociatedObject(self, StringTagKey, newObjectTag, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (UIView *)viewWithTagString:(NSString *)object {
    if (object == nil) {
        [NSException raise:NSInternalInconsistencyException format:@"Argument must not be nil."];
    }
    if ([[self stringTag] isEqual:object]) {
        return self;
    }
    for (UIView *subview in self.subviews) {
        UIView *resultView = [subview viewWithTagString:object];
        if (resultView != nil) {
            return resultView;
        }
    }
    return nil;
}

@end