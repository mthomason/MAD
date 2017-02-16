//
//  MADDatabaseConnectionsPropertiesCredentals.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDatabaseConnectionsPropertiesCredentals_h
#define MADDatabaseConnectionsPropertiesCredentals_h

@protocol MADDatabaseConnectionsPropertiesCredentals <NSObject>
    @property (readonly, nonatomic, copy)      NSString  *host;
    @property (readonly, nonatomic, copy)      NSString  *server;
    @property (readonly, nonatomic, copy)      NSString  *database;
    @property (readonly, nonatomic, assign)    NSInteger port;
@end

#endif /* MADDatabaseConnectionsPropertiesCredentals_h */
