//
//  MADViewDebugging.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/8/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADViewDebugging.h"

@implementation MADViewDebugging

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setFrame:(CGRect)frame {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, NSStringFromCGRect(frame));
    [super setFrame:frame];
}

@end
