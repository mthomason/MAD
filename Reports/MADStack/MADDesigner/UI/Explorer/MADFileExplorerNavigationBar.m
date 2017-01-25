//
//  MADFileExplorerNavigationBar.m
//  MAD Designer
//
//  Created by Michael on 1/8/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADFileExplorerNavigationBar.h"
#import <UIKit/UINavigationController.h>
#import <UIKit/UIViewController.h>
#import <UIKit/NSAttributedString.h>

@class UINavigationController;
@class UIViewController;

@implementation MADFileExplorerNavigationBar

+ (void)initialize {
    if (self == [MADFileExplorerNavigationBar class]) {
        @autoreleasepool {
            
            NSArray <Class <UIAppearanceContainer>> *classes;
            UINavigationBar *navigationBar;
            NSMutableDictionary *titleTextAttributes;
            
            classes = [[NSArray alloc] initWithObjects: [UINavigationController class],
                                                         [UIViewController class], nil];
            
            navigationBar = [UINavigationBar appearanceWhenContainedInInstancesOfClasses: classes];
            navigationBar.tintColor = [UIColor whiteColor];
            
            titleTextAttributes = navigationBar.titleTextAttributes.mutableCopy;
            if (!titleTextAttributes) {
                titleTextAttributes = [[NSMutableDictionary <NSString *,id> alloc] initWithCapacity: 1];
            }
           
            titleTextAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
            [navigationBar setTitleTextAttributes:titleTextAttributes];
        }
    }
}

@end
