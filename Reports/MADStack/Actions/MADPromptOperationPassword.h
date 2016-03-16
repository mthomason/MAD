//
//  MADPromptPasswordOperation.h
//  MAD Designer
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADOperation.h"
#import <UIKit/UIViewController.h>

@interface MADPromptOperationPassword : MADOperation

    - (instancetype)initWithViewController:(UIViewController *)viewController;
    @property (nonatomic, copy, readonly) NSString *password;

@end
