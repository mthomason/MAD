//
//  UIView+NSObjectIdTag.m
//  Reports
//
//  Created by Michael Thomason on 12/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIView+NSObjectIdTag.h"
#import <objc/runtime.h>

static char const * const StringTagKey = "ObjectIdTag";

@implementation UIView (NSObjectIdTag)
@dynamic objectIdTag;

- (id)objectIdTag {
    return objc_getAssociatedObject(self, StringTagKey);
}

- (void)setObjectIdTag:(id)newObjectTag {
    objc_setAssociatedObject(self, StringTagKey, newObjectTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
/*
- (UIView *)viewWithTagObjectId:(NSManagedObjectID *)object {
    
    if (object == nil) {
        [NSException raise:NSInternalInconsistencyException format:@"Argument must not be nil."];
    }
    
    if ([[self objectIdTag] isEqual:object]) {
        return self;
    }

    for (UIView *subview in self.subviews) {
        UIView *resultView = [subview viewWithTagObjectId:object];
        if (resultView != nil) {
            return resultView;
        }
    }
    return nil;
}
*/

@end