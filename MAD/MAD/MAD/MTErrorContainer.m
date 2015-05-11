//
//  MTErrorContainer.m
//  MAD
//
//  Created by Michael Thomason on 8/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTErrorContainer.h"
#import "NSError+Constructors.h"

@interface MTErrorContainer ()

@property (nonatomic, strong) NSMutableArray *errors;

@end

@implementation MTErrorContainer

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
    NSDictionary *errorHolder = @{
                                  @"e" : error,
                                  @"d" : [NSDate date]
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
        NSString *dateString = [NSDateFormatter localizedStringFromDate:errorHolder[@"d"] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        NSError *error = errorHolder[@"e"];
        NSString *errorString = [NSString stringWithFormat:formatString, dateString, error.localizedFailureReason, error.localizedDescription];
        [result appendString:errorString];
    }
    return result;
}

- (void)presentAllErrorsWithCompletion:(void (^)(BOOL success))completion {
    if (self.errors.count > 0) {
        NSError *errorToShow = self.errors.lastObject;
        [self.errors removeObject:errorToShow];
        [NSError presentError: errorToShow
             onViewController: nil
                   completion: ^(BOOL success) {
                       if (success) {
                           [self presentAllErrors];
                       }
                   }];
    } else {
        completion(YES);
    }
}

@end
