//
//  MADTabBarItemProtocol.h
//  MAD Designer
//
//  Created by Michael on 1/4/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADTabBarItemProtocol_h
#define MADTabBarItemProtocol_h

@protocol MADTabBarImageProtocol <NSObject>

  @required
    + (UIImage *)newTabBarImage;
  @optional
    + (NSString *)Title;

@end

#endif /* MADTabBarItemProtocol_h */
