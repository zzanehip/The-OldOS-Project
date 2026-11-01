//
//  MCOOperation.h
//  mailcore2
//
//  Created by Matt Ronge on 01/31/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#ifndef MAILCORE_MCOOPERATION_H

#define MAILCORE_MCOOPERATION_H

#import <Foundation/Foundation.h>

@interface MCOOperation : NSObject

/** Returns whether the operation is cancelled.*/
@property (readonly) BOOL isCancelled;

/** Returns whether the operation should run even if it's cancelled.*/
@property (nonatomic, assign) BOOL shouldRunWhenCancelled;

/** The queue this operation dispatches the callback on.  Defaults to the main queue.
 This property should be used only if there's performance issue creating or calling the callback
 in the main thread. */
#if OS_OBJECT_USE_OBJC
@property (nonatomic, retain) dispatch_queue_t callbackDispatchQueue;
#else
@property (nonatomic, assign) dispatch_queue_t callbackDispatchQueue;
#endif

/** This methods is called on the main thread when the asynchronous operation is finished.
 Needs to be overriden by subclasses.*/
- (void) operationCompleted;

/** Cancel the operation.*/
- (void) cancel;

#pragma mark - Unavailable initializers
/** Do not invoke this directly. */
- (instancetype) init NS_UNAVAILABLE;
/** Do not invoke this directly. */
+ (instancetype) new NS_UNAVAILABLE;

@end

#endif
