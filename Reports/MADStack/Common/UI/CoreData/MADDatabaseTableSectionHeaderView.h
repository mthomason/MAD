//
//  MADDatabaseTableSectionHeaderView.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseTableSectionHeaderView_h
#define Reports_MADDatabaseTableSectionHeaderView_h

#import <UIKit/UIView.h>
#import "MADSectionHeaderViewDelegate.h"

@interface MADDatabaseTableSectionHeaderView : UIView

- (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title
                      section:(NSInteger)sectionNumber delegate:(id <MADSectionHeaderViewDelegate>)delegate;
- (void)toggleOpenWithUserAction:(bool)userAction;

@end

#endif
