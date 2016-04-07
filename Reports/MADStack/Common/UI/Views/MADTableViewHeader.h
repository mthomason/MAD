//
//  MADViewTableHeader.h
//  Reports
//
//  Created by Michael Thomason on 1/27/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADViewTableHeader_h
#define Reports_MADViewTableHeader_h

#import <UIKit/UIKit.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>

@interface MADTableViewHeader : UIView

    @property (nonatomic, weak) IBOutlet UIButton *buttonAdd;
    @property (nonatomic, weak) IBOutlet UILabel *labelTitle;

@end

#endif
