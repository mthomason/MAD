//
//  MADPageSliderProtocol.h
//  MAD Designer
//
//  Created by Michael on 2/9/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADPageSliderProtocol_h
#define MADPageSliderProtocol_h

@protocol MADPageSliderProtocol <NSObject>
    - (void)sliderDidChangeToPage:(NSUInteger)page;
@end

#endif /* MADPageSliderProtocol_h */
