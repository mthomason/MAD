//
//  MADReportSectionDelegateProtocol.h
//  MAD Designer
//
//  Created by Michael on 5/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADReportSectionDelegateProtocol_h
#define MADReportSectionDelegateProtocol_h

@protocol MADDesignerDesignViewDelegate <NSObject>

  @optional
	- (void)designView:(MADDesignerLayoutDesignView *)designView
		handleTapLabel:(UITapGestureRecognizer *)sender;
	- (void)designView:(MADDesignerLayoutDesignView *)designView
		handleTapStray:(UITapGestureRecognizer *)sender;

@end

#endif /* MADReportSectionDelegateProtocol_h */
