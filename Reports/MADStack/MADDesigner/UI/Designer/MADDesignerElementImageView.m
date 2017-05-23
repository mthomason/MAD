//
//  MADDesignerElementImageView.m
//  MAD Designer
//
//  Created by Michael on 5/22/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerElementImageView.h"
#import <UIKit/UIImage.h>
#import <MAD/RptqDocumentElementImage.h>

@implementation MADDesignerElementImageView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [(UIImage *)self.displayObject drawInRect:rect];
}

- (void)updateWithElement:(RptqDocumentElement *)element {
    [super updateWithElement:element];
    self.displayObject = ((RptqDocumentElementImage *)element).image;
}

@end
