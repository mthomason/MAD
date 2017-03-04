//
//  MADLabelTimer.h
//  MAD Designer
//
//  Created by Michael on 3/2/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADLabelTimer_h
#define Reports_MADLabelTimer_h

#import <UIKit/UIView.h>

@interface MADLabelTimer : UIView

    - (void)updateWithDate:(NSDate *)lastCacheDate;

@end

#endif
