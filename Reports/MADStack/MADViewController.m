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
	return [[UIStoryboard storyboardWithName: @"MADQuery" bundle: [NSBundle mainBundle]] instantiateViewControllerWithIdentifier: @"MADStoryboardIDQueryVisulization"];
}

@end
