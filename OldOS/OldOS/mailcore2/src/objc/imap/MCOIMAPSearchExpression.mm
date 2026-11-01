//
//  MCOIMAPSearchExpression.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/25/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCOIMAPSearchExpression.h"

#include "MCIMAP.h"

#import "MCOUtils.h"

@implementation MCOIMAPSearchExpression {
    mailcore::IMAPSearchExpression * _nativeExpr;
}

#define nativeType mailcore::IMAPSearchExpression

+ (void) load
{
    MCORegisterClass(self, &typeid(nativeType));
}

- (id) copyWithZone:(NSZone *)zone
{
    nativeType * nativeObject = (nativeType *) [self mco_mcObject]->copy();
    id result = [[self class] mco_objectWithMCObject:nativeObject];
    MC_SAFE_RELEASE(nativeObject);
    return [result retain];
}

+ (NSObject *) mco_objectWithMCObject:(mailcore::Object *)object
{
    mailcore::IMAPSearchExpression * expr = (mailcore::IMAPSearchExpression *) object;
    return [[[self alloc] initWithMCExpression:expr] autorelease];
}

- (mailcore::Object *) mco_mcObject
{
    return _nativeExpr;
}

- (instancetype) initWithMCExpression:(mailcore::IMAPSearchExpression *)expr
{
    self = [super init];
    
    _nativeExpr = (mailcore::IMAPSearchExpression *) expr->copy();
    
    return self;
}

- (void) dealloc
{
    MC_SAFE_RELEASE(_nativeExpr);
    [super dealloc];
}

+ (MCOIMAPSearchExpression *) searchAll
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchAll());
}

+ (MCOIMAPSearchExpression *) searchFrom:(NSString *)value
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchFrom([value mco_mcString]));
}

+ (MCOIMAPSearchExpression *) searchTo:(NSString *)value
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchTo([value mco_mcString]));
}

+ (MCOIMAPSearchExpression *) searchCc:(NSString *)value
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchCc([value mco_mcString]));
}

+ (MCOIMAPSearchExpression *) searchBcc:(NSString *)value
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchBcc([value mco_mcString]));
}
+ (MCOIMAPSearchExpression *) searchRecipient:(NSString *)value
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchRecipient([value mco_mcString]));
}

+ (MCOIMAPSearchExpression *) searchSubject:(NSString *)value
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchSubject([value mco_mcString]));
}

+ (MCOIMAPSearchExpression *) searchContent:(NSString *)value
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchContent([value mco_mcString]));
}

+ (MCOIMAPSearchExpression *) searchBody:(NSString *)value
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchBody([value mco_mcString]));
}

+ (MCOIMAPSearchExpression *) searchUIDs:(MCOIndexSet *) uids
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchUIDs(MCO_FROM_OBJC(mailcore::IndexSet, uids)));
}

+ (MCOIMAPSearchExpression *) searchNumbers:(MCOIndexSet *) numbers
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchNumbers(MCO_FROM_OBJC(mailcore::IndexSet, numbers)));
}

+ (MCOIMAPSearchExpression *) searchHeader:(NSString *)header value:(NSString *)value
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchHeader([header mco_mcString], [value mco_mcString]));
}

+ (MCOIMAPSearchExpression *) searchRead
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchRead());
}

+ (MCOIMAPSearchExpression *) searchUnread
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchUnread());
}

+ (MCOIMAPSearchExpression *) searchFlagged
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchFlagged());
}

+ (MCOIMAPSearchExpression *) searchUnflagged
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchUnflagged());
}

+ (MCOIMAPSearchExpression *) searchAnswered
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchAnswered());
}

+ (MCOIMAPSearchExpression *) searchUnanswered
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchUnanswered());
}

+ (MCOIMAPSearchExpression *) searchDraft
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchDraft());
}

+ (MCOIMAPSearchExpression *) searchUndraft
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchUndraft());
}

+ (MCOIMAPSearchExpression *) searchDeleted
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchDeleted());
}

+ (MCOIMAPSearchExpression *) searchSpam
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchSpam());
}

+ (MCOIMAPSearchExpression *) searchBeforeDate:(NSDate *)date
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchBeforeDate((time_t) [date timeIntervalSince1970]));
}

+ (MCOIMAPSearchExpression *) searchOnDate:(NSDate *)date
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchOnDate((time_t) [date timeIntervalSince1970]));
}

+ (MCOIMAPSearchExpression *) searchSinceDate:(NSDate *)date
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchSinceDate((time_t) [date timeIntervalSince1970]));
}

+ (MCOIMAPSearchExpression *) searchBeforeReceivedDate:(NSDate *)date
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchBeforeReceivedDate((time_t) [date timeIntervalSince1970]));
}

+ (MCOIMAPSearchExpression *) searchOnReceivedDate:(NSDate *)date
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchOnReceivedDate((time_t) [date timeIntervalSince1970]));
}

+ (MCOIMAPSearchExpression *) searchSinceReceivedDate:(NSDate *)date
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchSinceReceivedDate((time_t) [date timeIntervalSince1970]));
}

+ (MCOIMAPSearchExpression *) searchSizeLargerThan:(uint32_t)size
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchSizeLarger(size));
}

+ (MCOIMAPSearchExpression *) searchSizeSmallerThan:(uint32_t)size
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchSizeSmaller(size));
}

+ (MCOIMAPSearchExpression *) searchGmailThreadID:(uint64_t)number
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchGmailThreadID(number));
}

+ (MCOIMAPSearchExpression *) searchGmailMessageID:(uint64_t)number
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchGmailMessageID(number));
}

+ (MCOIMAPSearchExpression *) searchGmailRaw:(NSString *)expr
{
    return MCO_TO_OBJC(mailcore::IMAPSearchExpression::searchGmailRaw([expr mco_mcString]));
}

+ (MCOIMAPSearchExpression *) searchAnd:(MCOIMAPSearchExpression *)expression other:(MCOIMAPSearchExpression *)other
{
    mailcore::IMAPSearchExpression * result = mailcore::IMAPSearchExpression::searchAnd(expression->_nativeExpr, other->_nativeExpr);
    return MCO_TO_OBJC(result);
}

+ (MCOIMAPSearchExpression *) searchOr:(MCOIMAPSearchExpression *)expression other:(MCOIMAPSearchExpression *)other
{
    mailcore::IMAPSearchExpression * result = mailcore::IMAPSearchExpression::searchOr(expression->_nativeExpr, other->_nativeExpr);
    return MCO_TO_OBJC(result);
}

+ (MCOIMAPSearchExpression *) searchNot:(MCOIMAPSearchExpression *)expression
{
    mailcore::IMAPSearchExpression * result = mailcore::IMAPSearchExpression::searchNot(expression->_nativeExpr);
    return MCO_TO_OBJC(result);
}

@end
