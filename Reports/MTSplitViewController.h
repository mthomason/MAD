//
//  ViewController.h
//  MTSplitViewController
//
//  Created by Michael Thomason on 2/13/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTQueryBuilderViewController.h"
#import "MTQueryBuilderAdvancedSchemaViewController.h"
#import "MTTitleView.h"

@protocol MTSplitViewControllerDelegate <NSObject>
- (void)displayContentController:(UIViewController *)contentController;
@end

@interface MTSplitViewController : MTViewController
    <MUIViewControllerDelegate>

@property (nonatomic, assign) id <MTSplitViewControllerDelegate> delegateContentController;
@property (nonatomic, retain) NSURL *documentToOpen;

- (MTQueryBuilderViewController *)queryBuilderController;
- (MTQueryBuilderAdvancedSchemaViewController *)queryBuilderControllerAdvanced;

@end
