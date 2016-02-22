//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+Query.h"

static NSString * const Query                   = @"MADQuery";

@implementation UIStoryboard (Query)

+ (instancetype)Query {
    return [self storyboardWithName:Query bundle:NULL];
}

@end
