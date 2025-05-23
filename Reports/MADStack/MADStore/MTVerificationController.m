//
//  MADVerificationController.m
//  MAD
//
//  Created by Michael Thomason on 11/05/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTVerificationController.h"
#import "ReceiptAttribute.h"
#import "MADSalesReceipt.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "madlog.h"

#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADApplication.h>

#include <CommonCrypto/CommonDigest.h>
#include <Security/Security.h>
#include <AssertMacros.h>

#import <openssl/ossl_typ.h>
#import <openssl/pkcs7.h>
#import <openssl/bio.h>
#import <openssl/x509.h>
#import <openssl/x509_vfy.h>
#import <openssl/evp.h>

@interface MTVerificationController() <SKRequestDelegate>

@property (nonatomic, copy) MTVerificationControllerVerifyPurchaseCompletion verifyPurchaseCompletion;
@property (nonatomic, copy) NSDictionary *receiptData;
@property (nonatomic, strong) NSError *failureReason;
@property (nonatomic, strong, readwrite) MADSalesReceipt *receipt;

@property (nonatomic, copy) MADCompletionSuccessError completion;

@end

@implementation MTVerificationController

static MTVerificationController *sharedSingleton;

- (void)dealloc {
	NSAssert(NO, @"Don't dealloc the singleton.");
}

+ (MTVerificationController *)sharedInstance {
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedSingleton = [[self alloc] init];
	});
	return sharedSingleton;
}

+ (BOOL)charterMemberGiftLookup:(NSString *)productID {
	return ([productID isEqualToString:@"com.everydayapps.mad.designer.product.viewer"] ||
			[productID isEqualToString:@"com.everydayapps.mad.designer.product.element.barcode"]);
}

- (BOOL)freeForCharterMemembers:(NSString *)productID {
	return [MTVerificationController charterMemberGiftLookup:productID] &&
	self.receipt.charterMembership;
}

- (BOOL)purchasedProductWithID:(NSString *)productID {
	BOOL result = NO;
	if (self.receipt.isValidReceipt) {
		if ([self freeForCharterMemembers:productID]) {
			result = YES;
		} else {
			NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *evaluatedObject, NSDictionary *bindings) {
				return [evaluatedObject[@"product-id"] isEqualToString:productID];
			}];
			NSArray *inAppPurchases = self.receipt.inAppPurchases;
			NSArray *results = [inAppPurchases filteredArrayUsingPredicate:p];
			result = results.count >= 1;
		}
	}
	return result;
}

- (void)reloadReceipt {
	MADSalesReceipt *receipt = [[MADSalesReceipt alloc] initWithPath:[NSBundle mainBundle].appStoreReceiptURL.path];
	
	NSString *bundleID = [[MADApplication AppDelegate] applicationBundleIdentifier];
	NSString *globalBundleVersion = [[MADApplication AppDelegate] versionNumber];
	NSUUID *identifierForVendor = [UIDevice currentDevice].identifierForVendor.copy;
	
	self.modernReceiptIsValid = [receipt verifyReceiptWithBundleID: bundleID
													 bundleVersion: globalBundleVersion
													   andDeviceID: identifierForVendor];
	if (self.modernReceiptIsValid) {
		self.receipt = receipt;
	}
}

- (void)resetReceipt {
	
	NSURL *receiptUrl = [NSBundle mainBundle].appStoreReceiptURL;
	NSString *receiptPath = receiptUrl.path;
	
	
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: receiptPath]) {
		
		MADSalesReceipt *receipt = [[MADSalesReceipt alloc] initWithPath:receiptUrl.path];
		
		NSString *bundleID = [[MADApplication AppDelegate] applicationBundleIdentifier];
		
		NSString *globalBundleVersion = [[MADApplication AppDelegate] versionNumber];
		NSUUID *identifierForVendor = [UIDevice currentDevice].identifierForVendor.copy;
		
		BOOL isValidReceipt = [receipt verifyReceiptWithBundleID: bundleID
												   bundleVersion: globalBundleVersion
													 andDeviceID: identifierForVendor];
		
		if ((self.modernReceiptIsValid = isValidReceipt)) {
			self.receipt = receipt;
		} else {
			//Invalid receipt!!! Gerr, blast it, and download from APPL
			NSError *error = nil;
			[[NSFileManager defaultManager] removeItemAtURL:receiptUrl error:&error];
			
			MTVerificationController * __weak weakself = self;
			[self refreshReceipt:^(BOOL refreshReceiptSuccess, NSError *refreshReceiptError) {
				MTVerificationController *strongself = weakself;
				if (strongself && refreshReceiptSuccess) [strongself reloadReceipt];
			}];
		}
	} else {
		// No receipt!!! Download it from APPL!
		MTVerificationController * __weak weakself = self;
		[self refreshReceipt:^(BOOL success, NSError *error) {
			MTVerificationController *strongself = weakself;
			if (success && strongself) [strongself reloadReceipt];
		}];
	}
}

- (void)refreshReceipt {
	SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
	request.delegate = self;
	[request start];
}

- (void)refreshReceipt:(MADCompletionSuccessError)completion {
	self.completion = completion;
	[self refreshReceipt];
}

- (void)iOS7VerifyReceipt {
	
	[self resetReceipt];
	if (self.modernReceiptIsValid == NO) {
		[self refreshReceipt];
	}
	
}

#pragma mark
#pragma mark SKRequestDelegate

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	[self setModernReceiptIsValid:NO];
	[self setModernReceiptProcessExperationDate:nil];
	if (self.completion) {
		self.completion(NO, error);
		self.completion = nil;
	}
}

- (void)requestDidFinish:(SKRequest *)request {
	[self reloadReceipt];
	if (self.completion) {
		self.completion(YES, nil);
		self.completion = nil;
	}
}

- (NSDictionary *)dictionaryFromPlistData:(NSData *)data {
	NSError *error;
	NSDictionary *dictionaryParsed = [NSPropertyListSerialization propertyListWithData: data
																			   options: NSPropertyListImmutable
																				format: nil
																				 error: &error];
	if (!dictionaryParsed) {
		if (error) {
			NSAssert(error == nil, @"%@", error);
		}
		return nil;
	}
	return dictionaryParsed;
}

- (NSDictionary *)dictionaryFromJSONData:(NSData *)data {
	NSError *error;
	NSDictionary *dictionaryParsed = [NSJSONSerialization JSONObjectWithData: data
																	 options: 0
																	   error: &error];
	if (!dictionaryParsed) {
		if (error) {
			NSAssert(error == nil, @"%@", error);
		}
		return nil;
	}
	return dictionaryParsed;
}

#pragma mark NSURLConnectionDelegate (for the verifyReceipt connection)

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	
}

// NOTE: These are needed for 4.x (as willSendRequestForAuthenticationChallenge: is not supported)
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
		SecTrustRef trust = challenge.protectionSpace.serverTrust;
		NSError *error = nil;
		BOOL didUseCredential = NO;
		BOOL isTrusted = [self validateTrust:trust error:&error];
		if (isTrusted) {
			NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
			if (credential) {
				[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
				didUseCredential = YES;
			}
		}
		if (! didUseCredential) {
			[challenge.sender cancelAuthenticationChallenge:challenge];
		}
	} else {
		[challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
	}
}

#pragma mark
#pragma mark NSURLConnection - Trust validation

- (BOOL)validateTrust:(SecTrustRef)trust error:(NSError * __autoreleasing *)error {
	extern CFStringRef kSecTrustInfoExtendedValidationKey;
	extern CFDictionaryRef SecTrustCopyInfo(SecTrustRef trust);
	
	if (trust == NULL) {
		if (error) {
			*error = [NSError errorWithDomain:@"kSecTrustError" code:-203 userInfo:nil];
		}
		return NO;
	}
	
	CFErrorRef evaluationError = NULL;
	bool trusted = SecTrustEvaluateWithError(trust, &evaluationError);
	
	if (trusted) {
		NSDictionary *trust_info = (__bridge_transfer NSDictionary *)SecTrustCopyInfo(trust);
		id hasEV = trust_info[(__bridge NSString *)kSecTrustInfoExtendedValidationKey];
		trusted = [hasEV isKindOfClass:[NSValue class]] && [hasEV boolValue] ? true : false;
	}
	
	if (!trusted && error) {
		if (evaluationError) {
			*error = (__bridge_transfer NSError *)evaluationError;
		} else {
			*error = [NSError errorWithDomain:@"kSecTrustError" code:errSecTrustSettingDeny userInfo:nil];
		}
		self.failureReason = *error;
	}
	
	return trusted ? YES : NO;
}


#pragma mark
#pragma mark Check Receipt signature

unsigned int iTS_intermediate_der_len = 1039;

unsigned char iTS_intermediate_der[] = {
	0x30, 0x82, 0x04, 0x0b, 0x30, 0x82, 0x02, 0xf3, 0xa0, 0x03, 0x02, 0x01,
	0x02, 0x02, 0x01, 0x1a, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
	0xf7, 0x0d, 0x01, 0x01, 0x05, 0x05, 0x00, 0x30, 0x62, 0x31, 0x0b, 0x30,
	0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x13,
	0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x0a, 0x13, 0x0a, 0x41, 0x70, 0x70,
	0x6c, 0x65, 0x20, 0x49, 0x6e, 0x63, 0x2e, 0x31, 0x26, 0x30, 0x24, 0x06,
	0x03, 0x55, 0x04, 0x0b, 0x13, 0x1d, 0x41, 0x70, 0x70, 0x6c, 0x65, 0x20,
	0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6f,
	0x6e, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x74, 0x79, 0x31,
	0x16, 0x30, 0x14, 0x06, 0x03, 0x55, 0x04, 0x03, 0x13, 0x0d, 0x41, 0x70,
	0x70, 0x6c, 0x65, 0x20, 0x52, 0x6f, 0x6f, 0x74, 0x20, 0x43, 0x41, 0x30,
	0x1e, 0x17, 0x0d, 0x30, 0x39, 0x30, 0x35, 0x31, 0x39, 0x31, 0x38, 0x33,
	0x31, 0x33, 0x30, 0x5a, 0x17, 0x0d, 0x31, 0x36, 0x30, 0x35, 0x31, 0x38,
	0x31, 0x38, 0x33, 0x31, 0x33, 0x30, 0x5a, 0x30, 0x7f, 0x31, 0x0b, 0x30,
	0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x13,
	0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x0a, 0x0c, 0x0a, 0x41, 0x70, 0x70,
	0x6c, 0x65, 0x20, 0x49, 0x6e, 0x63, 0x2e, 0x31, 0x26, 0x30, 0x24, 0x06,
	0x03, 0x55, 0x04, 0x0b, 0x0c, 0x1d, 0x41, 0x70, 0x70, 0x6c, 0x65, 0x20,
	0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6f,
	0x6e, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x74, 0x79, 0x31,
	0x33, 0x30, 0x31, 0x06, 0x03, 0x55, 0x04, 0x03, 0x0c, 0x2a, 0x41, 0x70,
	0x70, 0x6c, 0x65, 0x20, 0x69, 0x54, 0x75, 0x6e, 0x65, 0x73, 0x20, 0x53,
	0x74, 0x6f, 0x72, 0x65, 0x20, 0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69,
	0x63, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6f,
	0x72, 0x69, 0x74, 0x79, 0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09,
	0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03,
	0x82, 0x01, 0x0f, 0x00, 0x30, 0x82, 0x01, 0x0a, 0x02, 0x82, 0x01, 0x01,
	0x00, 0xa4, 0xbc, 0xaf, 0x32, 0x94, 0x43, 0x3e, 0x0b, 0xbc, 0x37, 0x87,
	0xcd, 0x63, 0x89, 0xf2, 0xcc, 0xd9, 0xbe, 0x20, 0x4d, 0x5a, 0xb4, 0xfe,
	0x87, 0x67, 0xd2, 0x9a, 0xde, 0x1a, 0x54, 0x9d, 0xa2, 0xf3, 0xdf, 0x87,
	0xe4, 0x4c, 0xcb, 0x93, 0x11, 0x78, 0xa0, 0x30, 0x8f, 0x34, 0x41, 0xc1,
	0xd3, 0xbe, 0x66, 0x6d, 0x47, 0x6c, 0x98, 0xb8, 0xec, 0x7a, 0xd5, 0xc9,
	0xdd, 0xa5, 0xe4, 0xea, 0xc6, 0x70, 0xf4, 0x35, 0xd0, 0x91, 0xf7, 0xb3,
	0xd8, 0x0a, 0x11, 0x99, 0xab, 0x3a, 0x62, 0x3a, 0xbd, 0x7b, 0xf4, 0x56,
	0x4f, 0xdb, 0x9f, 0x24, 0x93, 0x51, 0x50, 0x7c, 0x20, 0xd5, 0x66, 0x4d,
	0x66, 0xf3, 0x18, 0xa4, 0x13, 0x96, 0x22, 0x16, 0xfd, 0x31, 0xa7, 0xf4,
	0x39, 0x66, 0x9b, 0xfb, 0x62, 0x69, 0x5c, 0x4b, 0x9f, 0x94, 0xa8, 0x4b,
	0xe8, 0xec, 0x5b, 0x64, 0x5a, 0x18, 0x79, 0x8a, 0x16, 0x75, 0x63, 0x42,
	0xa4, 0x49, 0xd9, 0x8c, 0x33, 0xde, 0xad, 0x7b, 0xd6, 0x39, 0x04, 0xf4,
	0xe2, 0x9d, 0x0a, 0x69, 0x8c, 0xeb, 0x4b, 0x12, 0x28, 0x4b, 0x34, 0x48,
	0x07, 0x9b, 0x0e, 0x59, 0xf9, 0x1f, 0x62, 0xb0, 0x03, 0x9f, 0x36, 0xb8,
	0x4e, 0xa3, 0xd3, 0x75, 0x59, 0xd4, 0xf3, 0x3a, 0x05, 0xca, 0xc5, 0x33,
	0x3b, 0xf8, 0xc0, 0x06, 0x09, 0x08, 0x93, 0xdb, 0xe7, 0x4d, 0xbf, 0x11,
	0xf3, 0x52, 0x2c, 0xa5, 0x16, 0x35, 0x15, 0xf3, 0x41, 0x02, 0xcd, 0x02,
	0xd1, 0xfc, 0xf5, 0xf8, 0xc5, 0x84, 0xbd, 0x63, 0x6a, 0x86, 0xd6, 0xb6,
	0x99, 0xf6, 0x86, 0xae, 0x5f, 0xfd, 0x03, 0xd4, 0x28, 0x8a, 0x5a, 0x5d,
	0xaf, 0xbc, 0x65, 0x74, 0xd1, 0xf7, 0x1a, 0xc3, 0x92, 0x08, 0xf4, 0x1c,
	0xad, 0x69, 0xe8, 0x02, 0x4c, 0x0e, 0x95, 0x15, 0x07, 0xbc, 0xbe, 0x6a,
	0x6f, 0xc1, 0xb3, 0xad, 0xa1, 0x02, 0x03, 0x01, 0x00, 0x01, 0xa3, 0x81,
	0xae, 0x30, 0x81, 0xab, 0x30, 0x0e, 0x06, 0x03, 0x55, 0x1d, 0x0f, 0x01,
	0x01, 0xff, 0x04, 0x04, 0x03, 0x02, 0x01, 0x86, 0x30, 0x0f, 0x06, 0x03,
	0x55, 0x1d, 0x13, 0x01, 0x01, 0xff, 0x04, 0x05, 0x30, 0x03, 0x01, 0x01,
	0xff, 0x30, 0x1d, 0x06, 0x03, 0x55, 0x1d, 0x0e, 0x04, 0x16, 0x04, 0x14,
	0x36, 0x1d, 0xe8, 0xe2, 0x9d, 0x82, 0xd2, 0x01, 0x18, 0xb5, 0x32, 0x6b,
	0x0e, 0xd7, 0x43, 0x0b, 0x91, 0x58, 0x43, 0x3a, 0x30, 0x1f, 0x06, 0x03,
	0x55, 0x1d, 0x23, 0x04, 0x18, 0x30, 0x16, 0x80, 0x14, 0x2b, 0xd0, 0x69,
	0x47, 0x94, 0x76, 0x09, 0xfe, 0xf4, 0x6b, 0x8d, 0x2e, 0x40, 0xa6, 0xf7,
	0x47, 0x4d, 0x7f, 0x08, 0x5e, 0x30, 0x36, 0x06, 0x03, 0x55, 0x1d, 0x1f,
	0x04, 0x2f, 0x30, 0x2d, 0x30, 0x2b, 0xa0, 0x29, 0xa0, 0x27, 0x86, 0x25,
	0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x61,
	0x70, 0x70, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x61, 0x70, 0x70,
	0x6c, 0x65, 0x63, 0x61, 0x2f, 0x72, 0x6f, 0x6f, 0x74, 0x2e, 0x63, 0x72,
	0x6c, 0x30, 0x10, 0x06, 0x0a, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x63, 0x64,
	0x06, 0x02, 0x02, 0x04, 0x02, 0x05, 0x00, 0x30, 0x0d, 0x06, 0x09, 0x2a,
	0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x05, 0x05, 0x00, 0x03, 0x82,
	0x01, 0x01, 0x00, 0x75, 0xa6, 0x90, 0xe6, 0x9a, 0xa7, 0xdb, 0x65, 0x70,
	0xa6, 0x09, 0x93, 0x6f, 0x08, 0xdf, 0x2c, 0xdb, 0xe9, 0x28, 0x8d, 0x40,
	0x1b, 0x57, 0x5e, 0xa0, 0xea, 0xf4, 0xec, 0x13, 0x65, 0x1b, 0x71, 0x4a,
	0x4d, 0xdc, 0x80, 0x48, 0x4f, 0xf2, 0xe5, 0xa9, 0xfb, 0x85, 0x6c, 0xb7,
	0x1e, 0x9d, 0xdb, 0xf4, 0x18, 0x48, 0x10, 0x79, 0x17, 0xea, 0xc3, 0x3d,
	0x87, 0xd8, 0xb4, 0x79, 0x6d, 0x14, 0x50, 0xad, 0xd2, 0xbf, 0x3d, 0x4e,
	0xfc, 0x0d, 0xe2, 0xc5, 0x03, 0x94, 0x75, 0x80, 0x73, 0x4d, 0xa5, 0xa1,
	0x91, 0xfe, 0x1c, 0xde, 0x15, 0x17, 0xac, 0x89, 0x71, 0x2a, 0x6f, 0x0f,
	0x67, 0x0a, 0xd3, 0x9c, 0x30, 0xa1, 0x68, 0xfb, 0xcf, 0x70, 0x17, 0xca,
	0xd9, 0x40, 0xfc, 0xf8, 0x1b, 0xbf, 0xce, 0xb0, 0xc4, 0xae, 0xf4, 0x4a,
	0x2d, 0xa9, 0x99, 0x87, 0x06, 0x42, 0x09, 0x86, 0x22, 0x6a, 0x84, 0x40,
	0x39, 0xf4, 0xbb, 0xac, 0x56, 0x18, 0xf7, 0x9a, 0x1c, 0x01, 0x81, 0x5c,
	0x8c, 0x6e, 0x41, 0xf2, 0x5d, 0x19, 0x2c, 0x17, 0x1c, 0x49, 0x46, 0xd9,
	0x1c, 0x7e, 0x93, 0x12, 0x13, 0xc8, 0x67, 0x99, 0xc2, 0xea, 0x83, 0xe3,
	0xa2, 0x8c, 0x0e, 0xb8, 0x3b, 0x2a, 0xdf, 0x1c, 0xbf, 0x4b, 0x8b, 0x6f,
	0x1a, 0xb8, 0xee, 0x97, 0x67, 0x4a, 0xd8, 0xab, 0xaf, 0x8b, 0xa4, 0xda,
	0x5c, 0x87, 0x1e, 0x20, 0xb8, 0xc5, 0xf3, 0xb1, 0xc4, 0x98, 0xa2, 0x37,
	0xf8, 0x9e, 0xc6, 0x9a, 0x6b, 0xa5, 0xad, 0xf6, 0x78, 0x96, 0x0e, 0x82,
	0x8f, 0x04, 0x46, 0x1c, 0xb2, 0xa5, 0xfd, 0x9a, 0x30, 0x51, 0x28, 0xfd,
	0x52, 0x04, 0x15, 0x03, 0xd5, 0x3c, 0xad, 0xfe, 0xf6, 0x78, 0xe0, 0xea,
	0x35, 0xef, 0x65, 0xb5, 0x21, 0x76, 0xdb, 0xa4, 0xef, 0xcb, 0x72, 0xef,
	0x54, 0x6b, 0x01, 0x0d, 0xc7, 0xdd, 0x1a
};

BOOL checkReceiptSecurity(NSString *purchase_info_string, NSString *signature_string, CFDateRef purchaseDate);
BOOL checkReceiptSecurity(NSString *purchase_info_string, NSString *signature_string, CFDateRef purchaseDate) {
	BOOL valid = NO;
	SecCertificateRef leaf = NULL, intermediate = NULL;
	SecTrustRef trust = NULL;
	SecPolicyRef policy = SecPolicyCreateBasicX509();
	CFErrorRef cfError = NULL;
	NSData *certificate_data;
	NSArray *anchors;
	
	/*
	 Parse inputs:
	 purchase_info_string and signature_string are base64 encoded JSON blobs that need to
	 be decoded.
	 */
	NSData *purchaseInfoData = [NSData dataFromBase64String:purchase_info_string];
	NSData *signatureData = [NSData dataFromBase64String:signature_string];
	
	//Why test after conversion?  Because with ARC, I can't test before it!!!
	__Require([purchase_info_string canBeConvertedToEncoding:NSASCIIStringEncoding] &&
			  [signature_string canBeConvertedToEncoding:NSASCIIStringEncoding], outLabel);
	
	CC_LONG purchase_info_length;
	purchase_info_length = (unsigned int)purchaseInfoData.length;
	const uint8_t *purchase_info_bytes = purchaseInfoData.bytes;
	
	
	size_t signature_length;
	signature_length = signatureData.length;
	const uint8_t *signature_bytes = signatureData.bytes;
	
	__Require(purchase_info_bytes && signature_bytes, outLabel);
	
	/*
	 Binary format looks as follows:
	 
	 RECEIPTVERSION | SIGNATURE | CERTIFICATE SIZE | CERTIFICATE
	 1 byte           128         4 bytes
	 big endian
	 
	 Extract version, signature and certificate(s).
	 Check receipt version == 2.
	 Sanity check that signature is 128 bytes.
	 Sanity check certificate size <= remaining payload data.
	 */
	
#pragma pack(push, 1)
	struct signature_blob {
		uint8_t version;
		uint8_t signature[128];
		uint32_t cert_len;
		uint8_t certificate[];
	} *signature_blob_ptr = (struct signature_blob *)signature_bytes;
#pragma pack(pop)
	uint32_t certificate_len;
	
	/*
	 Make sure the signature blob is long enough to safely extract the version and
	 cert_len fields, then perform a sanity check on the fields.
	 */
	__Require(signature_length > offsetof(struct signature_blob, certificate), outLabel);
	__Require(signature_blob_ptr->version == 2, outLabel);
	certificate_len = ntohl(signature_blob_ptr->cert_len);
	
	__Require(signature_length - offsetof(struct signature_blob, certificate) >= certificate_len, outLabel);
	
	/*
	 Validate certificate chains back to valid receipt signer; policy approximation for now
	 set intermediate as a trust anchor; current intermediate lapses in 2016.
	 */
	
	certificate_data = [NSData dataWithBytes:signature_blob_ptr->certificate length:certificate_len];
	__Require(leaf = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) certificate_data), outLabel);
	
	certificate_data = [NSData dataWithBytes:iTS_intermediate_der length:iTS_intermediate_der_len];
	__Require(intermediate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) certificate_data), outLabel);
	
	anchors = @[(__bridge id)intermediate];
	__Require(anchors, outLabel);
	
	__Require_noErr(SecTrustCreateWithCertificates(leaf, policy, &trust), outLabel);
	__Require_noErr(SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef) anchors), outLabel);
	
	if (purchaseDate) {
		__Require_noErr(SecTrustSetVerifyDate(trust, purchaseDate), outLabel);
	}
	
	cfError = NULL;
	__Require(SecTrustEvaluateWithError(trust, &cfError), outLabel);
	__Require(2 == SecTrustGetCertificateCount(trust), outLabel);
	
	/*
	 Chain is valid, use leaf key to verify signature on receipt by
	 calculating SHA1(version|purchaseInfo)
	 */
	
	CC_SHA1_CTX sha1_ctx;
	uint8_t to_be_verified_data[CC_SHA1_DIGEST_LENGTH];
	
	CC_SHA1_Init(&sha1_ctx);
	CC_SHA1_Update(&sha1_ctx, &signature_blob_ptr->version, sizeof(signature_blob_ptr->version));
	CC_SHA1_Update(&sha1_ctx, purchase_info_bytes, purchase_info_length);
	CC_SHA1_Final(to_be_verified_data, &sha1_ctx);
	
	SecKeyRef receipt_signing_key = SecTrustCopyPublicKey(trust);
	__Require(receipt_signing_key, outLabel);
	__Require_noErr(SecKeyRawVerify(receipt_signing_key, kSecPaddingPKCS1SHA1,
									to_be_verified_data, sizeof(to_be_verified_data),
									signature_blob_ptr->signature, sizeof(signature_blob_ptr->signature)),
					outLabel);
	
	if (receipt_signing_key) CFRelease(receipt_signing_key);
	/*
	 Optional:  Verify that the receipt certificate has the 1.2.840.113635.100.6.5.1 Null OID
	 
	 The signature is a 1024-bit RSA signature.
	 */
	
	valid = YES;
	
outLabel:
	if (leaf) CFRelease(leaf);
	if (intermediate) CFRelease(intermediate);
	if (trust) CFRelease(trust);
	if (policy) CFRelease(policy);
	if (cfError) CFRelease(cfError);
	
	return valid;
}

#pragma mark
#pragma mark Base 64 encoding

- (NSString *)encodeBase64:(const uint8_t *)input length:(NSUInteger)length {
	NSData *dataToEncode = [NSData dataWithBytes:input length:length];
	return [dataToEncode base64EncodedString];
}


- (NSString *)decodeBase64:(NSString *)input length:(NSInteger *)length {
	NSData *decodedData = [NSData dataFromBase64String:input];
	NSString *decodedString = [[NSString alloc] initWithData:decodedData
													encoding:NSUTF8StringEncoding];
	return decodedString;
}

- (id)debugQuickLookObject {
	NSMutableString *result = [[NSMutableString alloc] initWithString:self.description];
	[result appendString:@"\n"];
	NSString *a = [NSString stringWithFormat:@"Valid\t%@\n", self.modernReceiptIsValid ? @"YES" : @"NO"];
	NSString *b = [NSString stringWithFormat:@"Process\t%@\n", self.modernReceiptProcess ? @"YES" : @"NO"];
	NSString *d = [NSString stringWithFormat:@"Expires\t%@\n", self.modernReceiptProcessExperationDate];
	[result appendString:a];
	[result appendString:b];
	[result appendString:d];
	[self.receiptData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		
		NSString *debuggingString = [NSString stringWithFormat:@"%@\t\t\t%@", key, obj];
		[result appendString:debuggingString];
		if ([obj isKindOfClass:[NSDictionary class]]) {
			
			[obj enumerateKeysAndObjectsUsingBlock:^(id key1, id obj1, BOOL *stop1) {
				NSString *debuggingString1 = [[NSString alloc] initWithFormat:@"\t%@\t\t%@", key1, obj1];
				[result appendString:debuggingString1];
			}];
			
		}
	}];
	return result;
}

// FIXME: Instead of returning BOOL, maybe return a enum type (yes, no, charter, future-entitlment-class)

- (BOOL)entitledToProduct:(NSString *)productID {
	return [self purchasedProductWithID:productID] || [self freeForCharterMemembers:productID];
}

@end
