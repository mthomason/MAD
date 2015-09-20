//
//  MTViewControllerBarcode+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerBarcode+Designer.h"
#import "UIStoryboard+Designer.h"

static NSString * const MainIdentifier = @"MTDocumentObjectNewBarcodeViewControllerIdentifier";

@implementation MTViewControllerBarcode (Designer)

+ (instancetype)main {
    UIStoryboard *storyboard = [UIStoryboard ObjectSelector];
    return [storyboard instantiateViewControllerWithIdentifier: MainIdentifier];
}

@end
