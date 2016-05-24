//
//  MADSettingsManager.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/17/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADPreferencesManager.h"

@interface MADPreferencesManager ()

@property (nonatomic, strong) NSMutableArray *preferences;

@end

@implementation MADPreferencesManager

+ (instancetype)sharedManager {
    static id *_sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] initPrivate];
    });
    return _sharedManager;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSUbiquityIdentityDidChangeNotification
                                                  object: nil];
}

- (instancetype)init {
    return [[self class] sharedManager];
}


- (instancetype)initPrivate {
    if (self = [super init]) {
        
        NSMutableArray *preferences = [NSMutableArray new];
        self.preferences = preferences;
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleNotificationKeyValueStoreDidChange:)
                                                     name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                   object: nil];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleNotificationUbiquityIdentityDidChange:)
                                                     name: NSUbiquityIdentityDidChangeNotification
                                                   object: nil];
        
        
        [[NSUbiquitousKeyValueStore defaultStore] synchronize];
        
    }
    return self;
}

- (void)addPreference:(MADPreference *)preference {
    if ([self.preferences indexOfObject:preference] != NSNotFound) {
        [self.preferences addObject:preference];
    }
}

#pragma mark - Notification Handlers

- (void)handleNotificationKeyValueStoreDidChange:(NSNotification *)notification {
    // One or more keys changed.
    
}

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    // Identity changed, so assume all keys changed.    
    
}

@end
