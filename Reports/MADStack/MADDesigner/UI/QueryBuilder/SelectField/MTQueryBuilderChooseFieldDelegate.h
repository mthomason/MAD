//
//  MTQueryBuilderChooseFieldDelegate.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTQueryBuilderChooseFieldDelegate_h
#define MAD_MTQueryBuilderChooseFieldDelegate_h

@class MTQueryBuilderChooseFieldViewController;
@class RptqQueryField;

@protocol MTQueryBuilderChooseFieldDelegate
    - (void)tableViewControllerChooseFieldDidFinish: (MTQueryBuilderChooseFieldViewController *)controller
                                          withField: (RptqQueryField *)field;
@end

#endif
