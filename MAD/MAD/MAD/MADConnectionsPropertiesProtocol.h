//
//  MADConnectionsPropertiesProtocol.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADConnectionsPropertiesProtocol_h
#define MADConnectionsPropertiesProtocol_h

#import <MADDatabase/MADDatabaseType.h>

@protocol MADConnectionsPropertiesProtocol <NSObject>
  @optional
    @property (readonly, nonatomic, copy)      NSString  *domain;
    @property (readonly, nonatomic, copy)      NSString  *host;
    @property (readonly, nonatomic, copy)      NSString  *server;
    @property (readonly, nonatomic, copy)      NSString  *database;
    @property (readonly, nonatomic, copy)      NSURL     *url;
    @property (readonly, nonatomic, assign)    NSInteger port;
    @property (readonly, nonatomic, assign)    MADDatabaseType databaseType;
@end

#endif /* MADConnectionsPropertiesProtocol_h */
