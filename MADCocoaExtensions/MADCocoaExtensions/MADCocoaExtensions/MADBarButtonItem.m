//
//  UIBarButtonItem+Constructors.m
//  CocoaExtensions
//
//  Created by Michael Thomason on 5/29/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADBarButtonItem.h"
#import <UIKit/UIImage.h>
#import <UIKit/UIActivityIndicatorView.h>

@implementation MADBarButtonItem

+ (instancetype)newBarButtonItemDuplicate:(id)target action:(SEL)action {
	id barButtonItemDuplicate = [[self alloc] initWithImage: [UIImage imageNamed: @"MADImageToolbarDuplicate"]
													  style: UIBarButtonItemStylePlain
													 target: target
													 action: action];
	[barButtonItemDuplicate setEnabled: NO];
	return barButtonItemDuplicate;
}

@end
