//
//  UITableViewCellDocument.m
//  Reports
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewCellDocument.h"
#import "Constants.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"

@implementation MTTableViewCellDocument

@synthesize labelH1, imageThumbnail;

+ (UIImage *)defaultThumbnail {
    UIImage *result = [[UIImage imageNamed:UIIMAGEDOCUMENTBLANK] retain];
    return [result autorelease];
}

+ (CGFloat)defaultHeight {
    return MNSDocumentHeight;
}

- (void)awakeFromNib {
    [[self imageThumbnail] setContentMode:UIViewContentModeScaleAspectFit];
    [super awakeFromNib];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(email:) || action == @selector(rename:)) {
        result = YES;
    }
    return result;
}

- (void)delete:(id)sender {
    [[self delegate] deleteDocumentRepresentedByCell:self];
}

- (void)email:(id)sender {
    [[self delegate] email:self];
}

- (void)rename:(id)sender {
    [[self delegate] rename:self];
}

@end
