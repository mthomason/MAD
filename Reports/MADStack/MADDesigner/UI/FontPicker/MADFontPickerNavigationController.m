//
//  MADFontPickerNavigationController.m
//  MAD
//
//  Created by Michael Thomason on 10/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADFontPickerNavigationController.h"
#import "MADFontSelectorViewController.h"
#import "MADToolboxStoryboard.h"

static NSString * const FontPicker      = @"MADIdentifierStoryboardFontPicker";

@implementation MADFontPickerNavigationController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self.visibleViewController isKindOfClass:[MADFontSelectorViewController class]]) {
        [self setNavigationBarHidden:NO animated:NO];
    } else {
        [self setNavigationBarHidden:YES animated:NO];
    }
    [self.visibleViewController.view setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.visibleViewController.view setNeedsLayout];
}

+ (instancetype)FontPickerNavigationController {
    UIStoryboard *storyboard = [MADToolboxStoryboard ToolboxStoryboard];
    return [storyboard instantiateViewControllerWithIdentifier:FontPicker];
}


/*
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    self.preferredContentSize = viewController.preferredContentSize;
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *result = [super popViewControllerAnimated:animated];
    self.preferredContentSize = result.preferredContentSize;
    return result;
}
*/
@end
