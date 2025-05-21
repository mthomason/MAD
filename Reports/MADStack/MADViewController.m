//
//  MADViewController.m
//  MAD Designer
//
//  Created by Michael on 8/25/17.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#import "MADViewController.h"
#import <UIKit/UIStoryboard.h>

@implementation MADViewController

+ (instancetype)newViewControllerQueryVisulization {
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName: @"MADQuery"
														 bundle: [NSBundle mainBundle]];
	return [storyboard instantiateViewControllerWithIdentifier: @"MADStoryboardIDQueryVisulization"];
}

@end
