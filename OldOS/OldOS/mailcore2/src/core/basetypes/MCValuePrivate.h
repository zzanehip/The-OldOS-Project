//
//  MCValuePrivate.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 3/21/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCVALUEPRIVATE_H

#define MAILCORE_MCVALUEPRIVATE_H

enum {
    VALUE_TYPE_NONE = mailcore::ValueTypeNone,
    VALUE_TYPE_BOOL_VALUE = mailcore::ValueTypeBool,
    VALUE_TYPE_CHAR_VALUE = mailcore::ValueTypeChar,
    VALUE_TYPE_UNSIGNED_CHAR_VALUE = mailcore::ValueTypeUnsignedChar,
    VALUE_TYPE_SHORT_VALUE = mailcore::ValueTypeShort,
    VALUE_TYPE_UNSIGNED_SHORT_VALUE = mailcore::ValueTypeUnsignedShort,
    VALUE_TYPE_INT_VALUE = mailcore::ValueTypeInt,
    VALUE_TYPE_UNSIGNED_INT_VALUE = mailcore::ValueTypeUnsignedInt,
    VALUE_TYPE_LONG_VALUE = mailcore::ValueTypeLong,
    VALUE_TYPE_UNSIGNED_LONG_VALUE = mailcore::ValueTypeUnsignedLong,
    VALUE_TYPE_LONG_LONG_VALUE = mailcore::ValueTypeLongLong,
    VALUE_TYPE_UNSIGNED_LONG_LONG_VALUE = mailcore::ValueTypeUnsignedLongLong,
    VALUE_TYPE_FLOAT_VALUE = mailcore::ValueTypeFloat,
    VALUE_TYPE_DOUBLE_VALUE = mailcore::ValueTypeDouble,
    VALUE_TYPE_POINTER_VALUE = mailcore::ValueTypePointer,
    VALUE_TYPE_DATA_VALUE = mailcore::ValueTypeData,
};

#endif
