//
//  MADOperationInstallSampleDocument.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADInstallOperationSampleDocument_h
#define MAD_Designer_MADInstallOperationSampleDocument_h

#import <MADFoundation/MADOperation.h>

@interface MADOperationInstallSampleDocument : MADOperation

@property (nonatomic, assign) bool sampleDocumentInstalled;

- (instancetype)initWithFilename:(NSString *)filename
				   fileExtension:(NSString *)fileExtension
				 groupIdentifier:(NSString *)groupIdentifier
					 installFlag:(NSString *)installFlag;

@end

#endif
