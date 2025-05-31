//
//  MADOperationRefreshReloadProtocol.h
//  MAD Designer
//
//  Created by Michael on 8/21/17.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MADOperationRefreshReloadProtocol_h
#define MADOperationRefreshReloadProtocol_h

@class NSNotification;

@protocol MADOperationRefreshReloadProtocol <NSObject>

@required
- (void)operation:(MADOperation *)operation updatePages:(NSUInteger)numberOfPages;
- (void)operation:(MADOperation *)operation updateRecordsRead:(NSUInteger)records;
- (void)operation:(MADOperation *)operation setDisplayActive:(BOOL)active;
- (void)operation:(MADOperation *)operation finishReload:(MADocument *)document;
- (void)operation:(MADOperation *)operation didReadRows:(NSNotification *)sender;
- (void)operation:(MADOperation *)operation didFormatPage:(NSNotification *)sender;

@end

#endif /* MADOperationRefreshReloadProtocol_h */
