//
//  MADDatabaseConnectionsPropertiesURLProtocol.h
//  MAD
//
//  Created by Michael on 2/16/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDatabaseConnectionsPropertiesURLProtocol_h
#define MADDatabaseConnectionsPropertiesURLProtocol_h

@protocol MADDatabaseConnectionsPropertiesURL <NSObject>
    @property (readonly, nonatomic, copy) NSURL *databaseUrl;
@end

#endif /* MADDatabaseConnectionsPropertiesURLProtocol_h */
