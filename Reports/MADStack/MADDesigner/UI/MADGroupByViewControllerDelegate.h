//
//  MADGroupByViewControllerDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/1/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADGroupByViewControllerDelegate_h
#define MADGroupByViewControllerDelegate_h

@protocol MADGroupByViewControllerDelegate

    - (void)didSelectGroupByPage;
    - (void)didSelectGroupByReport;
    - (void)didSelectGroupBySectionNumber:(int32_t)groupNumber;

@end

#endif /* MADGroupByViewControllerDelegate_h */
