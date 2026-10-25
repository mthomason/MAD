//
//  MADReportPageView.h
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADReportPageView_h
#define Reports_MADReportPageView_h

#import <UIKit/UIView.h>

#import "MADReportPageViewProtocol.h"

@interface MADReportPageView : UIView

@property (nonatomic, weak) id <MADReportPageViewProtocol> _Nullable delegatePage;
@property (nonatomic, assign) BOOL drawBlankPage;

@end

#endif
