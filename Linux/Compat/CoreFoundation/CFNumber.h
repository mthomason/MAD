//
//  CFNumber.h
//  Linux/Compat/CoreFoundation
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  GNUstep ships no CFNumber, and no toll-free bridge to reach one.  The code
//  that imports this header uses exactly one call -- CFNumberGetValue over an
//  NSNumber -- so the shim is that call, answered with the NSNumber accessor
//  each CFNumberType means.  CFNumberRef is the identity bridge, so the
//  (__bridge CFNumberRef) casts at the call sites still compile.
//
//  Non-Apple only; nothing on Apple sees it.
//

#ifndef MADCompat_CoreFoundation_CFNumber_h
#define MADCompat_CoreFoundation_CFNumber_h

#if !__APPLE__
#import <Foundation/NSValue.h>

// Boolean comes from the compat prelude (MacTypes' scalars).
typedef NSInteger CFIndex;
typedef NSInteger CFNumberType;
// Opaque, and deliberately not NSNumber *: the call sites write
// (__bridge CFNumberRef)number, and an ARC bridged cast to the same ObjC type
// is an error.  The value travels as the bridged NSNumber either way.
typedef struct MADCompatCFNumber *CFNumberRef;

enum {
	kCFNumberSInt8Type = 1,
	kCFNumberSInt16Type = 2,
	kCFNumberSInt32Type = 3,
	kCFNumberSInt64Type = 4,
	kCFNumberFloat32Type = 5,
	kCFNumberFloat64Type = 6,
	kCFNumberCharType = 7,
	kCFNumberShortType = 8,
	kCFNumberIntType = 9,
	kCFNumberLongType = 10,
	kCFNumberLongLongType = 11,
	kCFNumberFloatType = 12,
	kCFNumberDoubleType = 13,
	kCFNumberCFIndexType = 14,
	kCFNumberNSIntegerType = 15,
	kCFNumberCGFloatType = 16,
	kCFNumberMaxType = 16
};

static inline Boolean CFNumberGetValue(CFNumberRef numberRef, CFNumberType type, void *valuePtr) {
	NSNumber *number = (__bridge NSNumber *)numberRef;
	if (number == nil || valuePtr == NULL) {
		return 0;
	}
	switch (type) {
		case kCFNumberSInt8Type: case kCFNumberCharType:
			*(int8_t *)valuePtr = (int8_t)number.charValue; break;
		case kCFNumberSInt16Type: case kCFNumberShortType:
			*(int16_t *)valuePtr = (int16_t)number.shortValue; break;
		case kCFNumberSInt32Type: case kCFNumberIntType:
			*(int32_t *)valuePtr = (int32_t)number.intValue; break;
		case kCFNumberSInt64Type: case kCFNumberLongLongType:
			*(int64_t *)valuePtr = (int64_t)number.longLongValue; break;
		case kCFNumberLongType:
			*(long *)valuePtr = number.longValue; break;
		case kCFNumberCFIndexType: case kCFNumberNSIntegerType:
			*(CFIndex *)valuePtr = number.integerValue; break;
		case kCFNumberFloat32Type: case kCFNumberFloatType:
			*(float *)valuePtr = number.floatValue; break;
		case kCFNumberFloat64Type: case kCFNumberDoubleType: case kCFNumberCGFloatType:
			*(double *)valuePtr = number.doubleValue; break;
		default:
			return 0;
	}
	return 1;
}

#endif /* !__APPLE__ */

#endif /* MADCompat_CoreFoundation_CFNumber_h */
