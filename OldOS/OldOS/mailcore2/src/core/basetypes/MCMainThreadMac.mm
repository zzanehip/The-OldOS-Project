#include "MCMainThread.h"

#import <Foundation/Foundation.h>

#include "MCAutoreleasePool.h"

using namespace mailcore;

static void destroyDelayedCall(void * caller);

@interface LEPPPMainThreadCaller : NSObject {
    void (* _function)(void *);
    void * _context;
    NSTimer * _timer;
}

@property (nonatomic, assign) void (* function)(void *);
@property (nonatomic, assign) void * context;
@property (nonatomic, retain) NSTimer * timer;

- (void) call;
- (void) cancel;

@end

@implementation LEPPPMainThreadCaller

@synthesize function = _function;
@synthesize context = _context;
@synthesize timer = _timer;

- (instancetype) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [_timer release];
    [super dealloc];
}

- (void) call
{
    AutoreleasePool * pool = new AutoreleasePool();
    _function(_context);
    pool->release();
    
    [self setTimer:nil];
    
    destroyDelayedCall((void *) self);
}

- (void) cancel
{
    [_timer invalidate];
    [self setTimer:nil];
    destroyDelayedCall((void *) self);
}

@end

void mailcore::callOnMainThread(void (* function)(void *), void * context)
{
    LEPPPMainThreadCaller * caller;
    caller = [[LEPPPMainThreadCaller alloc] init];
    [caller setFunction:function];
    [caller setContext:context];
    [caller performSelectorOnMainThread:@selector(call) withObject:nil waitUntilDone:NO];
}

void mailcore::callOnMainThreadAndWait(void (* function)(void *), void * context)
{
    LEPPPMainThreadCaller * caller;
    caller = [[LEPPPMainThreadCaller alloc] init];
    [caller setFunction:function];
    [caller setContext:context];
    [caller performSelectorOnMainThread:@selector(call) withObject:nil waitUntilDone:YES];
}

void * mailcore::callAfterDelay(void (* function)(void *), void * context, double time)
{
    LEPPPMainThreadCaller * caller;
    caller = [[LEPPPMainThreadCaller alloc] init];
    [caller setFunction:function];
    [caller setContext:context];
    
    NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval) time
                                                       target:caller
                                                     selector:@selector(call)
                                                     userInfo:nil
                                                      repeats:NO];
    [caller setTimer:timer];
    
    return caller;
}

static void destroyDelayedCall(void * caller)
{
    [(LEPPPMainThreadCaller *) caller release];
}

void mailcore::cancelDelayedCall(void * delayedCall)
{
    LEPPPMainThreadCaller * caller = (LEPPPMainThreadCaller *) delayedCall;
    [caller cancel];
}
