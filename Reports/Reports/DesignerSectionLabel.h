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

@interface DesignerSectionLabel : UIView

- (id)initWithDisplayText:(NSString *)displayText;
- (void)dimView;
- (void)normalView;

@property (nonatomic, retain) UILabel *labelSectionIdentifer;
@property (nonatomic, assign, readonly) BOOL selected;
@end

#endif
