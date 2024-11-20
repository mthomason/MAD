//
//  MADCloudManagerProtocol.h
//  MADFileManager
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADCloudManagerProtocol_h
#define MADCloudManagerProtocol_h

@protocol MADCloudManagerDelegate <NSObject>
    - (void)promptUserForCloudPreference:(void (^)(MADAppStorage preference))result;
@end

#endif /* MADCloudManagerProtocol_h */
