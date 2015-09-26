//
//  UIView+NSObjectIdTag.m
//  Reports
//
//  Created by Michael Thomason on 12/24/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UIView+NSObjectIdTag.h"
#import <objc/runtime.h>
#import <CoreData/CoreData.h>

static char const * const StringTagKey = "ObjectIdTag";

@implementation UIView (NSObjectIdTag)
@dynamic objectIdTag;

- (id)objectIdTag {
    return objc_getAssociatedObject(self, StringTagKey);
}

- (void)setObjectIdTag:(id)newObjectTag {
    objc_setAssociatedObject(self, StringTagKey, newObjectTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
