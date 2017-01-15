//
//  MADInstallOperationSampleDocument.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADInstallOperationSampleDocument_h
#define MAD_Designer_MADInstallOperationSampleDocument_h

#import "MADOperation.h"

@interface MADOperationInstallSampleDocument : MADOperation

    - (instancetype)initWithFilename:(NSString *)filename
                       fileExtension:(NSString *)fileExtension
                     groupIdentifier:(NSString *)groupIdentifier
                         installFlag:(NSString *)installFlag;

@end

#endif
