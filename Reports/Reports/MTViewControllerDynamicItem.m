//
//  MTViewControllerDynamicItem.m
//  MAD
//
//  Created by Michael Thomason on 11/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerDynamicItem.h"

@interface MTViewControllerDynamicItem ()

@end

@implementation MTViewControllerDynamicItem

- (void)setCenter:(CGPoint)center {
    [[self view] setCenter:center];
}

- (void)setBounds:(CGRect)bounds {
    [[self view] setBounds:bounds];
}

- (void)setTransform:(CGAffineTransform)transform {
    [[self view] setTransform:transform];
}

- (CGPoint)center {
    return [[self view] center];
}

- (CGRect)bounds {
    return [[self view] bounds];
}

- (CGAffineTransform)transform {
    return [[self view] transform];
}

@end
