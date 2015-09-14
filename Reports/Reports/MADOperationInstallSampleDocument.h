//
//  MADOperationInstallSampleDocument.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/11/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MADFileManager/MADFileManager.h>

@interface MADOperationInstallSampleDocument : NSOperation

- (instancetype)initWithFilename:(NSString *)filename fileExtension:(NSString *)fileExtension groupIdentifier:(NSString *)groupIdentifier installFlag:(NSString *)installFlag;

@end
