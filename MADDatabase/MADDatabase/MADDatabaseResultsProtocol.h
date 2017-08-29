//
//  MADDatabaseResultsProtocol.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDatabaseResultsProtocol_h
#define MADDatabaseResultsProtocol_h

#import <Foundation/NSObject.h>

@class MADCredential, MADDataTable, NSString, MTQuery;

@protocol MADDatabaseResultsProtocol <NSObject>
  @required
  @optional
    - (MADCredential *)getCredentialsForKey:(NSString *)key;
    - (MADDataTable *)dataTableForQuery:(MTQuery *)query;
@end

#endif /* MADDatabaseResultsProtocol_h */
