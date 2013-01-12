//
//  MTViewVaporTouch.m
//  Reports
//
//  Created by Michael Thomason on 1/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewVaporTouch.h"

@implementation MTViewVaporTouch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (id view in [self subviews]) {
        [view touchesBegan:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (id view in [self subviews]) {
        [view touchesCancelled:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (id view in [self subviews]) {
        [view touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (id view in [self subviews]) {
        [view touchesEnded:touches withEvent:event];
    }
}

@end
