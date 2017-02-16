//
//  MADImageTransformer.m
//  MAD Designer
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADImageTransformer.h"
#import <UIKit/UIImage.h>

@implementation MADImageTransformer

+ (Class)transformedValueClass {
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (nullable id)transformedValue:(nullable id)value {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
    id result = value != nil ? UIImageJPEGRepresentation(value, 1.0) : nil;
#pragma clang diagnostic pop
    return result;
}

- (nullable id)reverseTransformedValue:(nullable id)value {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
    id result = value != nil ? [[UIImage alloc] initWithData:value] : nil;
#pragma clang diagnostic pop
    return result;
}

@end
