//
//  MADDatabaseProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDatabaseProtocol_h
#define MADDatabaseProtocol_h

@class MADCredential;
@class MTDataTable;
@class NSString;
@class MTQuery;

@protocol MADDatabaseProtocol <NSObject>
  @required
  @optional
    - (MADCredential *)getCredentialsForKey:(NSString *)key;
    - (MTDataTable *)dataTableForQuery:(MTQuery *)query;
@end

#endif /* MADDatabaseProtocol_h */
