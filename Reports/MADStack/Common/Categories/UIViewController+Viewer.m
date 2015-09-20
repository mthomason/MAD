//
//  UIViewController+Viewer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "UIViewController+Viewer.h"
#import "UIStoryboard+Viewer.h"

@implementation UIViewController (Viewer)

+ (instancetype)initalViewController {
    UIStoryboard *designer = [UIStoryboard viewer];
    return [designer instantiateInitialViewController];
}

@end
