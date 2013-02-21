//
//  ViewController.h
//  MTSplitViewController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTViewControllerQueryBuilder.h"
#import "MTQueryBuilderAdvancedSchemaViewController.h"

@protocol MTSplitViewControllerDelegate <NSObject>
- (void)displayContentController:(UIViewController *)contentController;
@end

@interface MTSplitViewController : MTViewController

@property (nonatomic, assign) id <MTSplitViewControllerDelegate> delegateContentController;
@property (nonatomic, retain) NSURL *documentToOpen;

- (MTViewControllerQueryBuilder *)queryBuilderController;
- (MTQueryBuilderAdvancedSchemaViewController *)queryBuilderControllerAdvanced;

@end
