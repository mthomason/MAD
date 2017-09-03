//
//  MADPluginProtocol.h
//  MADAPI
//
//  Created by Michael on 9/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADPluginProtocol_h
#define MADPluginProtocol_h

#import <Foundation/NSObject.h>

@protocol MADPluginProtocol <NSObject>

    + (NSString *)imageIconName;
    + (NSString *)driverName;

@end

#endif /* MADPluginProtocol_h */
