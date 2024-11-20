//
//  MADDatabaseResultsProtocol.h
//  MAD
//
//  Created by Michael on 8/28/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADDatabaseResultsProtocol_h
#define MADDatabaseResultsProtocol_h

#import <Foundation/NSObject.h>

@class MADCredential, MADDataTable, NSString, MADQuery;

@protocol MADDatabaseResultsProtocol <NSObject>
  @required
  @optional
    - (MADCredential *)getCredentialsForKey:(NSString *)key;
    - (MADDataTable *)dataTableForQuery:(MADQuery *)query;
@end

#endif /* MADDatabaseResultsProtocol_h */
