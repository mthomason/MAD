//
//  MADDesignerElementImageView.m
//  MAD Designer
//
//  Created by Michael on 5/22/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDesignerElementImageView.h"
#import <MAD/RptqDocumentElement+Extras.h>
#import <UIKit/UIImage.h>
#import <MAD/RptqDocumentElementImage.h>

@implementation MADDesignerElementImageView

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	RptqDocumentElement *element = (RptqDocumentElement *)[self.managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentElement class]) identifier:self.objectID];
	[(UIImage *)self.displayObject drawInRect:[element innerRect]];
}

- (void)updateWithElement:(RptqDocumentElement *)element {
	[super updateWithElement:element];
	self.displayObject = ((RptqDocumentElementImage *)element).image;
}

@end
