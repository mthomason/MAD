//
//  MADTabBarItemProtocol.h
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADTabBarItemProtocol_h
#define MAD_MADTabBarItemProtocol_h

@protocol MADTabBarImageProtocol <NSObject>

  @required
    + (UIImage *)newTabBarImage;
  @optional
    + (NSString *)Title;

@end

#endif /* MADTabBarItemProtocol_h */
