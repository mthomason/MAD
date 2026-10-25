//
//  MADQueryViewDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADQueryViewDelegate_h
#define MAD_Designer_MADQueryViewDelegate_h

#import "MADIdentifierQueryViewSections.h"
#import <UIKit/UITableView.h>

@class MADQueryViewDelegate, MADQueryViewSectionDelegate;
@protocol MADQueryViewControllerLayoutSectionSelectorProtocol;

@protocol MADQueryViewDelegateProtocol <NSObject>

- (MADIdentifierQueryViewSections)sectionIdentifierForDisplayIndex:(short)displayIndex;
- (MADQueryViewSectionDelegate *)sectionLayoutForDisplayIndex:(short)displayIndex;
- (CGFloat)headerHeight;
- (void)queryViewDelegate:(MADQueryViewDelegate *)delegate handleUserRequestedSampleDataForTableAtIndex:(NSInteger)index;

@end

@interface MADQueryViewDelegate : NSObject <UITableViewDelegate>

@property (nonatomic, weak) id <MADQueryViewDelegateProtocol, MADQueryViewControllerLayoutSectionSelectorProtocol> delegate;

@end

#endif
