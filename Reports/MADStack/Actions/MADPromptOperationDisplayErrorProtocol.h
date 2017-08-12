//
//  MADPromptOperationDisplayErrorProtocol.h
//  MAD Designer
//
//  Created by Michael on 8/11/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADPromptOperationDisplayErrorProtocol_h
#define MADPromptOperationDisplayErrorProtocol_h

@protocol MADPromptOperationDisplayErrorProtocol <NSObject>

    - (NSError *)error;
    - (BOOL)displayError;
    - (NSUInteger)tag;

@end

#endif /* MADPromptOperationDisplayErrorProtocol_h */
