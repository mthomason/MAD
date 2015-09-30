//
//  MTTableViewControllerStaticSelectTag.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Barcodes_MTTableViewControllerStaticSelectRow_h
#define Barcodes_MTTableViewControllerStaticSelectRow_h

#import <UIKit/UIKit.h>

@protocol MTTableViewControllerStaticSelectRowDelegate
- (NSInteger)initalRow;
- (void)didSelectTag:(NSInteger)tag;
@end

@interface MTTableViewControllerStaticSelectRow : UITableViewController
    <UITableViewDelegate>

@property (nonatomic, weak) id <MTTableViewControllerStaticSelectRowDelegate> delegate;

@end

#endif
