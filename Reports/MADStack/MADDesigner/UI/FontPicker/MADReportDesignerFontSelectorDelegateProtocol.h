//
//  MADReportDesignerFontSelectorDelegateProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/5/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADReportDesignerFontSelectorDelegateProtocol_h
#define MADReportDesignerFontSelectorDelegateProtocol_h

@protocol MADReportDesignerFontSelectorDelegate
  - (void)tableViewControllerDidUpdateFontToFontWithName:(NSString *)fontName;
@end

#endif /* MADReportDesignerFontSelectorDelegateProtocol_h */
