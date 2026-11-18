//
//  pthread.h — minimal Windows shim for MADOperation.m's recursive mutex.
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  MADOperation.m uses a pthread_mutex_t (initialized PTHREAD_MUTEX_RECURSIVE)
//  as its state lock.  The MSVC-target Clang has no pthread.h; this shim maps
//  the handful of pthread_mutex* symbols MADFoundation reaches for onto a
//  Windows CRITICAL_SECTION, which is recursive by default — matching the one
//  mutex type the code actually uses.
//

#ifndef MAD_WINDOWS_PTHREAD_H
#define MAD_WINDOWS_PTHREAD_H

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct { CRITICAL_SECTION cs; } pthread_mutex_t;
typedef struct { int type; } pthread_mutexattr_t;

#define PTHREAD_MUTEX_RECURSIVE 1

static inline int pthread_mutexattr_init(pthread_mutexattr_t *a) {
	a->type = 0;
	return 0;
}
static inline int pthread_mutexattr_settype(pthread_mutexattr_t *a, int type) {
	a->type = type;
	return 0;
}
static inline int pthread_mutexattr_destroy(pthread_mutexattr_t *a) {
	(void)a;
	return 0;
}
static inline int pthread_mutex_init(pthread_mutex_t *m, const pthread_mutexattr_t *a) {
	(void)a;	/* CRITICAL_SECTION is always recursive, matching PTHREAD_MUTEX_RECURSIVE */
	InitializeCriticalSection(&m->cs);
	return 0;
}
static inline int pthread_mutex_destroy(pthread_mutex_t *m) {
	DeleteCriticalSection(&m->cs);
	return 0;
}
static inline int pthread_mutex_lock(pthread_mutex_t *m) {
	EnterCriticalSection(&m->cs);
	return 0;
}
static inline int pthread_mutex_unlock(pthread_mutex_t *m) {
	LeaveCriticalSection(&m->cs);
	return 0;
}

#ifdef __cplusplus
}
#endif

#endif /* MAD_WINDOWS_PTHREAD_H */
