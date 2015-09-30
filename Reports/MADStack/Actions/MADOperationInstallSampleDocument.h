//
//  MADOperationInstallSampleDocument.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADOperationInstallSampleDocument_h
#define MAD_Designer_MADOperationInstallSampleDocument_h

#import <Foundation/NSOperation.h>
#import <MADFileManager/MADFileManager.h>
#import <MADCocoaExtensions/MADCocoaExtensions.h>

@interface MADOperationInstallSampleDocument : NSOperation

- (instancetype)initWithFilename:(NSString *)filename fileExtension:(NSString *)fileExtension groupIdentifier:(NSString *)groupIdentifier installFlag:(NSString *)installFlag;

@end

#endif
