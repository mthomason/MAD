//
//  MADAlertControllerPromptStorage.m
//  MADExplorer
//
//  Created by Michael on 2/14/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADAlertControllerPromptStorage.h"

@implementation MADAlertControllerPromptStorage

+ (instancetype)newAlertControllerPromptStorage:(void (^)(void))handlerLocal
										  cloud:(void (^)(void))handlerCloud {

	NSString *MADMessageChooseStorageOptions = @"Do you want to store documents "
													@"in iCloud or "
													@"only on this device?";
	
	id storageController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Choose Storage Option", @"Choose Storage Option")
															   message: NSLocalizedString(MADMessageChooseStorageOptions, MADMessageChooseStorageOptions)
														preferredStyle: UIAlertControllerStyleAlert];

	UIAlertAction *actionLocal = [UIAlertAction actionWithTitle: NSLocalizedString(@"Local Only", @"Local Only")
														  style: UIAlertActionStyleDefault
														handler:^(UIAlertAction * _Nonnull action) {
		handlerLocal();
	}];
	[storageController addAction:actionLocal];

	UIAlertAction *actionCloud = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cloud", @"Cloud")
														  style: UIAlertActionStyleDefault
														handler:^(UIAlertAction * _Nonnull action) {
		handlerCloud();
	}];
	[storageController addAction:actionCloud];

	return storageController;
}

@end
