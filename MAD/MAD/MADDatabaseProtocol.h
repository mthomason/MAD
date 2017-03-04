//
//  MADDatabaseProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDatabaseProtocol_h
#define MADDatabaseProtocol_h

@class MADCredential, MADDataTable, NSString, MTQuery;

@protocol MADDatabaseProtocol <NSObject>
  @required
  @optional
    - (MADCredential *)getCredentialsForKey:(NSString *)key;
    - (MADDataTable *)dataTableForQuery:(MTQuery *)query;
@end

#endif /* MADDatabaseProtocol_h */
