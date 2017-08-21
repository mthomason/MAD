//
//  MADOperationRefreshReloadProtocol.h
//  MAD Designer
//
//  Created by Michael on 8/21/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADOperationRefreshReloadProtocol_h
#define MADOperationRefreshReloadProtocol_h

@protocol MADOperationRefreshReloadProtocol <NSObject>

    - (void)operation:(MADOperation *)operation updatePages:(NSUInteger)numberOfPages;
    - (void)operation:(MADOperation *)operation updateRecordsRead:(NSUInteger)records;
    - (void)operation:(MADOperation *)operation setDisplayActive:(BOOL)active;
    - (void)operation:(MADOperation *)operation setLastCacheDate:(NSDate *)date;
    - (void)operation:(MADOperation *)operation finishReload:(MADocument *)document;

@end

#endif /* MADOperationRefreshReloadProtocol_h */
