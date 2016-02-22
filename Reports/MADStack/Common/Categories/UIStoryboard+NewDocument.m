//
//  UIStoryboard+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIStoryboard+NewDocument.h"

static NSString * const NewDocument             = @"MADStoryboardNewDocument";

@implementation UIStoryboard (Designer)

+ (instancetype)NewDocument {
    return [self storyboardWithName: NewDocument bundle:[NSBundle mainBundle]];
}

@end
