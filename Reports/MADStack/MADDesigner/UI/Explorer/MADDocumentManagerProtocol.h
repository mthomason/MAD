//
//  MADDocumentManagerProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDocumentManagerProtocol_h
#define MADDocumentManagerProtocol_h

@protocol MADDocumentManagerProtocol <NSObject>

    - (void)documentManagerDidChangeContent:(NSArray *)inserts
                                    removes:(NSArray *)removes
                                    updates:(NSArray *)updates
                                 completion:(void (^)(BOOL, NSError *))completion;

    - (void)handleDidDisconnectFromClound:(id)sender;
    - (void)handleDidStartLongRunningActivity;
    - (void)handleDidCompletedLongRunningActivity;

@end

#endif /* MADDocumentManagerProtocol_h */
