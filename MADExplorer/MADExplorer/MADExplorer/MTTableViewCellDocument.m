//
//  UITableViewCellDocument.m
//  Reports
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewCellDocument.h"

#import <UIKit/UIImageView.h>
#import <UIKit/UINibLoading.h>

@implementation MTTableViewCellDocument

@synthesize labelH1, imageThumbnail;

- (void)awakeFromNib {
    self.imageThumbnail.contentMode = UIViewContentModeScaleAspectFit;
    [super awakeFromNib];
}

@end
