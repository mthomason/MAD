//
//  MTViewTableHeader.h
//  Reports
//
//  Created by Michael Thomason on 1/27/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTViewTableHeader_h
#define Reports_MTViewTableHeader_h

#import <UIKit/UIKit.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>

@interface MTViewTableHeader : UIView

    @property (nonatomic, strong) IBOutlet UIButton *buttonAdd;
    @property (nonatomic, strong) IBOutlet UILabel *labelTitle;

@end

#endif
