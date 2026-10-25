//
//  MADLabelPageSlider.h
//  MAD Designer
//
//  Created by Michael on 8/21/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADLabelPageSlider_h
#define MAD_Designer_MADLabelPageSlider_h

#import <UIKit/UILabel.h>

@interface MADLabelPageSlider : UILabel

    @property (nonatomic, assign) NSUInteger pageNumber;

    - (void)translateToPoint:(CGPoint)drawingPoint;

@end

#endif
