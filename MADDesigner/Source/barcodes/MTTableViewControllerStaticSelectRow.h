//
//  MTTableViewControllerStaticSelectTag.h
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Barcodes_MTTableViewControllerStaticSelectRow_h
#define Barcodes_MTTableViewControllerStaticSelectRow_h

#import <UIKit/UITableViewController.h>

@protocol MTTableViewControllerStaticSelectRowDelegate
    - (NSInteger)initalRow;
    - (void)didSelectTag:(NSInteger)tag;
@end

@interface MTTableViewControllerStaticSelectRow : UITableViewController
    <UITableViewDelegate>

    @property (nonatomic, weak) id <MTTableViewControllerStaticSelectRowDelegate> delegate;

@end

#endif
