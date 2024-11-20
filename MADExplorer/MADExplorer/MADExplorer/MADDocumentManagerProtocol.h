//
//  MADDocumentManagerProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDocumentManagerProtocol_h
#define MAD_MADDocumentManagerProtocol_h

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
