//
//  MADErrorContainer.m
//  MAD
//
//  Created by Michael Thomason on 8/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADErrorContainer.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSDateFormatter.h>

#import <MADCocoaExtensions/NSError+Constructors.h>

static NSString * const MADErrorContainerError  = @"e";
static NSString * const MADErrorContainerDate   = @"d";

@interface MADErrorContainer ()

    @property (nonatomic, strong) NSMutableArray <__kindof NSDictionary *> *errors;

@end

@implementation MADErrorContainer

- (instancetype)init {
    self = [super init];
    if (self) {
        NSMutableArray *errors = [NSMutableArray new];
        self.errors = errors;
    }
    return self;
}

- (NSUInteger)count {
    return self.errors.count;
}

- (void)addError:(NSError *)error {
    NSError *errorCopy = error.copy;
    NSDate *date = [NSDate date];
    NSDictionary *errorHolder = @{
                                  MADErrorContainerError    : errorCopy,
                                  MADErrorContainerDate     : date
                                  };
    [self.errors addObject:errorHolder];
}

- (NSString *)errorLog {
    return [self errorLogWithFormatString:@"%@ - \t\t%@\n\t\t\t\t%@\n"];
}

- (NSString *)errorLogCompact {
    return [self errorLogWithFormatString:@"%@ - %@ - %@\n"];
}

- (NSString *)errorLogWithFormatString:(NSString *)formatString {
    NSMutableString *result = [NSMutableString new];
    for (NSDictionary *errorHolder in self.errors) {
        NSString *dateString = [NSDateFormatter localizedStringFromDate: errorHolder[MADErrorContainerDate]
                                                              dateStyle: NSDateFormatterShortStyle
                                                              timeStyle: NSDateFormatterShortStyle];
        NSError *error = errorHolder[MADErrorContainerError];
        NSString *errorString = [NSString stringWithFormat:formatString, dateString, error.localizedFailureReason, error.localizedDescription];
        [result appendString:errorString];
    }
    return result;
}

- (void)presentAllErrorsWithCompletion:(void (^)(BOOL success))completion {
    if (self.errors.count > 0) {
        NSDictionary *errorHolder = self.errors.lastObject;
        NSError *errorToShow = errorHolder[MADErrorContainerError];
        [self.errors removeLastObject];
        [NSError presentError: errorToShow
             onViewController: nil
                   completion: ^(BOOL success) {
                       if (success) {
                           [self presentAllErrorsWithCompletion:nil];
                       }
                   }];
    } else {
        if (completion) {
            completion(YES);
        }
    }
}

- (NSArray <__kindof NSError *> *)allObjects {
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:self.errors.count];
    for (NSDictionary *containers in self.errors) {
        NSError *error = ((NSError *)containers[@"e"]).copy;
        [results addObject:error];
    }
    return results;
}

- (void)addErrorsFromContainer:(MADErrorContainer *)additionalErrorContainer {
    NSArray *adderrs = [additionalErrorContainer allObjects];
    for (NSError *err in adderrs) {
        @autoreleasepool {
            [self addError:err];
        }
    }

}

@end
