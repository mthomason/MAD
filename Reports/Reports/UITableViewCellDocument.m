//
//  UITableViewCellDocument.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellDocument.h"
#import "Constants.h"

@implementation UITableViewCellDocument

@synthesize labelH1, labelH2, imageThumbnail;

+ (UIImage *)defaultThumbnail {
    return [UIImage imageNamed:UIIMAGEDOCUMENTBLANK];
}

+ (CGFloat)defaultHeight {
    return TVC_DOCUMENT_HEIGHT;
}

@end