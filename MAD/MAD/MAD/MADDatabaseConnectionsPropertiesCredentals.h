//
//  MADDatabaseConnectionsPropertiesCredentals.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDatabaseConnectionsPropertiesCredentals_h
#define MADDatabaseConnectionsPropertiesCredentals_h

#import <MAD/MADDatabaseType.h>

@protocol MADDatabaseConnectionsPropertiesCredentals <NSObject>
  @optional
    @property (readonly, nonatomic, copy)      NSString  *domain;
    @property (readonly, nonatomic, copy)      NSString  *host;
    @property (readonly, nonatomic, copy)      NSString  *server;
    @property (readonly, nonatomic, copy)      NSString  *database;
    @property (readonly, nonatomic, copy)      NSURL     *url;
    @property (readonly, nonatomic, assign)    NSInteger port;
    @property (readonly, nonatomic, assign)    MADDatabaseType databaseType;
@end

#endif /* MADDatabaseConnectionsPropertiesCredentals_h */
