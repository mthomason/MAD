#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "NSData+Base64.h"
#import "MTLog.h"
#import "NSError+UserInterface.h"

#define IS_IOS6_AWARE (__IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1)

#define ITMS_PROD_VERIFY_RECEIPT_URL        @"https://buy.itunes.apple.com/verifyReceipt"
#define ITMS_SANDBOX_VERIFY_RECEIPT_URL     @"https://sandbox.itunes.apple.com/verifyReceipt";

#define KNOWN_TRANSACTIONS_KEY              @"knownIAPTransactions"
#define ITC_CONTENT_PROVIDER_SHARED_SECRET  @"your secret here"

typedef void (^MTVerificationControllerVerifyPurchaseCompletion)(BOOL success, NSError *error, NSInteger status, NSDictionary *receiptData, NSDate *purcahseDate);

@interface MTVerificationController : NSObject {
    NSMutableDictionary *transactionsReceiptStorageDictionary;
}

+ (MTVerificationController *) sharedInstance;

// Checking the results of this is not enough.
// The final verification happens in the connection:didReceiveData: callback within
// this class.  So ensure IAP feaures are unlocked from there.
- (void)verifyPurchase:(SKPaymentTransaction *)transaction
       onSandboxServer:(BOOL)onSandboxServer
            completion:(MTVerificationControllerVerifyPurchaseCompletion)completion;

- (void)receiptVerificationOS7;

@end
