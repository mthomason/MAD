//
//  MTTableViewControllerStaticSelectTag.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MTTableViewControllerStaticSelectRowDelegate
- (NSInteger)initalRow;
- (void)didSelectTag:(NSInteger)tag;
@end

@interface MTTableViewControllerStaticSelectRow : UITableViewController
    <UITableViewDelegate>

@property (nonatomic, assign) id <MTTableViewControllerStaticSelectRowDelegate> delegate;

@end
