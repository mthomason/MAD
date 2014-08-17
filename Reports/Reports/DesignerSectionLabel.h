//
//  DesignerSectionLabel.h
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_DesignerSectionLabel_h
#define Reports_DesignerSectionLabel_h

#import <UIKit/UIKit.h>
#import "Constants.h"

@interface DesignerSectionLabel : UIView

@property (nonatomic, strong) UILabel *labelSectionIdentifer;
@property (nonatomic, assign, readonly) BOOL selected;

- (instancetype)initWithDisplayText:(NSString *)displayText NS_DESIGNATED_INITIALIZER;
- (void)dimView;
- (void)normalView;

@end

#endif
