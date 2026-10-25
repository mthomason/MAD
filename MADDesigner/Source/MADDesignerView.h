//
//  MADDesignerView.h
//  MAD Designer
//
//  Created by Michael on 5/26/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDesignerView_h
#define Reports_MADDesignerView_h

#import <UIKit/UIView.h>

@class MADDesignerScrollView, MADDesignerSectionView, MADDesignerSectionLabel;

@interface MADDesignerView : UIView

    @property (nonatomic, weak) IBOutlet MADDesignerScrollView *scroller;

@end

#endif
