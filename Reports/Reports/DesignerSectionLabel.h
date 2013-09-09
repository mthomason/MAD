//
//  DesignerSectionLabel.h
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DesignerSectionLabel : UIView

- (id)initWithDisplayText:(NSString *)displayText;
- (void)dimView;
- (void)normalView;

@property (nonatomic, retain) UILabel *labelSectionIdentifer;
@property (nonatomic, assign, readonly) BOOL selected;
@end
