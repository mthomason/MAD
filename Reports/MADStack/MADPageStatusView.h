//
//  MADPageStatusView.h
//  MAD Designer
//
//  Created by Michael on 3/1/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADPageStatusView_h
#define Reports_MADPageStatusView_h

#import <UIKit/UIView.h>

@interface MADPageStatusView : UIView

- (void)setPage:(NSUInteger)page ofTotal:(NSUInteger)total;

@end

#endif
