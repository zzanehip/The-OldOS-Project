//
//  NSNumber+MCO.m
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/21/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "NSValue+MCO.h"

#include "MCAssert.h"
#include "MCValue.h"
#include "MCValuePrivate.h"

@implementation NSValue (MCO)

+ (id) mco_objectWithMCObject:(mailcore::Object *)object
{
    return [self mco_valueWithMCValue:(mailcore::Value *) object];
}

+ (NSNumber *) mco_valueWithMCValue:(mailcore::Value *)value
{
    switch (value->type()) {
        case VALUE_TYPE_BOOL_VALUE:
            return [NSNumber numberWithBool:value->boolValue()];
        case VALUE_TYPE_CHAR_VALUE:
            return [NSNumber numberWithChar:value->charValue()];
        case VALUE_TYPE_UNSIGNED_CHAR_VALUE:
            return [NSNumber numberWithUnsignedChar:value->unsignedCharValue()];
        case VALUE_TYPE_SHORT_VALUE:
            return [NSNumber numberWithShort:value->shortValue()];
        case VALUE_TYPE_UNSIGNED_SHORT_VALUE:
            return [NSNumber numberWithUnsignedChar:value->unsignedShortValue()];
        case VALUE_TYPE_INT_VALUE:
            return [NSNumber numberWithInt:value->intValue()];
        case VALUE_TYPE_UNSIGNED_INT_VALUE:
            return [NSNumber numberWithUnsignedInt:value->unsignedIntValue()];
        case VALUE_TYPE_LONG_VALUE:
            return [NSNumber numberWithLong:value->longValue()];
        case VALUE_TYPE_UNSIGNED_LONG_VALUE:
            return [NSNumber numberWithUnsignedLong:value->unsignedLongValue()];
        case VALUE_TYPE_LONG_LONG_VALUE:
            return [NSNumber numberWithLongLong:value->longLongValue()];
        case VALUE_TYPE_UNSIGNED_LONG_LONG_VALUE:
            return [NSNumber numberWithUnsignedLongLong:value->unsignedLongLongValue()];
        case VALUE_TYPE_FLOAT_VALUE:
            return [NSNumber numberWithFloat:value->floatValue()];
        case VALUE_TYPE_DOUBLE_VALUE:
            return [NSNumber numberWithDouble:value->doubleValue()];
        case VALUE_TYPE_POINTER_VALUE:
            MCAssert(0);
            return nil;
        case VALUE_TYPE_DATA_VALUE:
            MCAssert(0);
            return nil;
        default:
            MCAssert(0);
            return nil;
    }
}

- (mailcore::Value *) mco_mcValue;
{
    NSNumber * nb = (NSNumber *) self;
    if (strcmp([self objCType], @encode(BOOL)) == 0) {
        return mailcore::Value::valueWithBoolValue([nb boolValue]);
    }
    else if (strcmp([self objCType], @encode(char)) == 0) {
        return mailcore::Value::valueWithCharValue([nb charValue]);
    }
    else if (strcmp([self objCType], @encode(unsigned char)) == 0) {
        return mailcore::Value::valueWithUnsignedCharValue([nb unsignedCharValue]);
    }
    else if (strcmp([self objCType], @encode(short)) == 0) {
        return mailcore::Value::valueWithShortValue([nb shortValue]);
    }
    else if (strcmp([self objCType], @encode(unsigned short)) == 0) {
        return mailcore::Value::valueWithUnsignedShortValue([nb unsignedShortValue]);
    }
    else if (strcmp([self objCType], @encode(int)) == 0) {
        return mailcore::Value::valueWithIntValue([nb intValue]);
    }
    else if (strcmp([self objCType], @encode(unsigned int)) == 0) {
        return mailcore::Value::valueWithUnsignedIntValue([nb unsignedIntValue]);
    }
    else if (strcmp([self objCType], @encode(long)) == 0) {
        return mailcore::Value::valueWithLongValue([nb longValue]);
    }
    else if (strcmp([self objCType], @encode(unsigned long)) == 0) {
        return mailcore::Value::valueWithUnsignedLongValue([nb unsignedLongValue]);
    }
    else if (strcmp([self objCType], @encode(long long)) == 0) {
        return mailcore::Value::valueWithLongLongValue([nb longLongValue]);
    }
    else if (strcmp([self objCType], @encode(unsigned long long)) == 0) {
        return mailcore::Value::valueWithUnsignedLongLongValue([nb unsignedLongLongValue]);
    }
    else if (strcmp([self objCType], @encode(float)) == 0) {
        return mailcore::Value::valueWithFloatValue([nb floatValue]);
    }
    else if (strcmp([self objCType], @encode(double)) == 0) {
        return mailcore::Value::valueWithDoubleValue([nb doubleValue]);
    }
    else {
        MCAssert(0);
        return NULL;
    }
}

@end
