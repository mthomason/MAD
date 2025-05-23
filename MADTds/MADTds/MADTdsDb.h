//
//  MADTdsDb.h
//  MADTds
//
//  Created by Michael Thomason on 11/22/24.
//

#ifndef MADTdsDb_h
#define MADTdsDb_h

#import <Foundation/NSObject.h>

NS_ASSUME_NONNULL_BEGIN

@interface MADTdsDb : NSObject

@property (nonatomic, assign) int port;
@property (nonatomic, copy, nullable) NSString *hostname;
@property (nonatomic, copy, nullable) NSString *username;
@property (nonatomic, copy, nullable) NSString *password;
@property (nonatomic, copy, nullable) NSString *database;

- (instancetype)initWithHost:(NSString *)hostname
						port:(int)port
					username:(NSString *)username
					password:(NSString *)password
					database:(NSString *)database;

- (BOOL)connect;
- (NSArray<NSDictionary *> *)executeQuery:(NSString *)query;
- (void)disconnect;

@end

NS_ASSUME_NONNULL_END

#endif /* MADTdsDb_h */
