//
//  MADDocumentScroller.m
//  MAD Designer
//
//  Created by Michael Thomason on 2/23/16.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADDocumentScroller.h"
#import <MADCocoaExtensions/MADViewHelpers.h>

@interface MADDocumentScroller ()

@end

@implementation MADDocumentScroller

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = MADViewAutoresizingFlexable();
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.showsHorizontalScrollIndicator = YES;
        self.showsVerticalScrollIndicator = YES;
        self.indicatorStyle = UIScrollViewIndicatorStyleBlack;
        self.bounces = YES;
        self.alwaysBounceVertical = YES;
    }
    return self;
}

@end
