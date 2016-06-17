//
//  UITableViewCellDocument.m
//  Reports
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewCellDocument.h"
#import "MTDocumentCellProtocol.h"

#import <UIKit/UIImageView.h>
#import <UIKit/UINibLoading.h>

@implementation MTTableViewCellDocument

@synthesize labelH1, imageThumbnail;

- (void)awakeFromNib {
    self.imageThumbnail.contentMode = UIViewContentModeScaleAspectFit;
    [super awakeFromNib];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    if (action == @selector(actionEmail:) || action == @selector(actionRename:)) {
        result = YES;
    }
    return result;
}

- (void)actionEmail:(id)sender {
    [self.delegate actionEmail:self];
}

- (void)actionRename:(id)sender {
    [self.delegate actionRename:self];
}

@end
