//
//  NSObject+DebugDescription.m
//  MAD
//
//  Created by Michael Thomason on 7/7/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "NSObject+DebugDescription.h"
#import <objc/runtime.h>

@implementation NSObject (DebugDescription)

- (NSString *)debugDescriptionDetailed {
    NSMutableString *result = [[NSMutableString alloc] init];
    unsigned int numberOfProperties = 0;
    objc_property_t *propertyArray = class_copyPropertyList([self class], &numberOfProperties);
    [result appendString:@"********\n"];
    for (NSUInteger i = 0; i < numberOfProperties; i++) {
        objc_property_t property = propertyArray[i];
        NSString *key = [[NSString alloc] initWithUTF8String:property_getName(property)];
        //NSString *attributesString = [[NSString alloc] initWithUTF8String:property_getAttributes(property)];
        [result appendFormat:@"%@:\t\t\t\t%@\n", key, [self valueForKey:key]];
    }
    [result appendString:@"********\n"];
    free(propertyArray);
    return result;
}

@end
