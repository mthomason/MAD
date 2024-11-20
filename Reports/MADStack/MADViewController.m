//
//  MADViewController.m
//  MAD Designer
//
//  Created by Michael on 8/25/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADViewController.h"
#import "MADStoryboard.h"

@interface MADViewController ()

@end

@implementation MADViewController

+ (instancetype)newViewControllerQueryVisulization {
	UIStoryboard *storyboard = [MADStoryboard newStoryboardQuery];
	id controller = [storyboard instantiateViewControllerWithIdentifier: @"MADStoryboardIDQueryVisulization"];
	return controller;
}

@end
