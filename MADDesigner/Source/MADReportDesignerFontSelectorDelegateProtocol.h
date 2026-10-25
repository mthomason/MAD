//
//  MADReportDesignerFontSelectorDelegateProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADReportDesignerFontSelectorDelegateProtocol_h
#define MADReportDesignerFontSelectorDelegateProtocol_h

@class NSString;

@protocol MADReportDesignerFontSelectorDelegate
  - (void)tableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName;
@end

#endif /* MADReportDesignerFontSelectorDelegateProtocol_h */
