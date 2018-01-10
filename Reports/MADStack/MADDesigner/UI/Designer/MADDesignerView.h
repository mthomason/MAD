//
//  MADDesignerView.h
//  MAD Designer
//
//  Created by Michael on 5/26/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADDesignerView_h
#define Reports_MADDesignerView_h

#import <UIKit/UIView.h>

@class MADDesignerScrollView, MADDesignerSectionView, MADDesignerSectionLabel;

@interface MADDesignerView : UIView

    @property (nonatomic, weak) IBOutlet MADDesignerScrollView *scroller;

@end

#endif
