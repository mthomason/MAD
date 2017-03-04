//
//  MADDatabaseTableSectionHeaderView.h
//  Reports
//
//  Created by Michael Thomason on 2/8/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDatabaseTableSectionHeaderView_h
#define Reports_MADDatabaseTableSectionHeaderView_h

#import <UIKit/UIView.h>

@protocol MADSectionHeaderViewDelegate;

@interface MADDatabaseTableSectionHeaderView : UIView

    - (instancetype)initWithFrame:(CGRect)frame title:(NSString*)title
                          section:(NSInteger)sectionNumber
                         delegate:(id <MADSectionHeaderViewDelegate>)delegate;
    - (void)toggleOpenWithUserAction:(BOOL)userAction;

@end

#endif
