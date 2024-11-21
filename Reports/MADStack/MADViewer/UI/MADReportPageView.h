//
//  MADReportPageView.h
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADReportPageView_h
#define Reports_MADReportPageView_h

#import <UIKit/UIView.h>

@protocol MADReportPageViewProtocol;

@interface MADReportPageView : UIView

	@property (nonatomic, weak) id <MADReportPageViewProtocol> _Nullable delegatePage;
	@property (nonatomic, assign) BOOL drawBlankPage;

@end

#endif
