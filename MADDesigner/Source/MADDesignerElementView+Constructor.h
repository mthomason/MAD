//
//  MADDesignerElementView+Constructor.h
//  MAD Designer
//
//  Created by Michael on 9/2/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADElementView_Constructor_h
#define Reports_MADElementView_Constructor_h

#import "MADDesignerElementView.h"

@interface MADDesignerElementView (Constructor)

	+ (instancetype)newDesignerElementView:(RptqDocumentElement *)documentObject
						tapGestureDelegate:(id <UIGestureRecognizerDelegate>)tapGestureDelegate
							   tapSelector:(SEL)selector;

@end

#endif
