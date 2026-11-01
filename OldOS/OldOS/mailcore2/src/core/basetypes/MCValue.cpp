#include "MCValue.h"
#include "MCValuePrivate.h"

#include <string.h>
#include <stdlib.h>

#include "MCDefines.h"
#include "MCString.h"
#include "MCHash.h"
#include "MCUtils.h"
#include "MCHashMap.h"
#include "MCAssert.h"
#include "MCData.h"

using namespace mailcore;

Value::Value()
{
    mType = VALUE_TYPE_NONE;
    memset(&mValue, 0, sizeof(mValue));
}

Value::Value(Value * other)
{
    memcpy(&mValue, &other->mValue, sizeof(mValue));
    mType = other->mType;
    if (mType == VALUE_TYPE_DATA_VALUE) {
        mValue.dataValue.data = (char *) malloc(mValue.dataValue.length);
        memcpy(mValue.dataValue.data, other->mValue.dataValue.data, mValue.dataValue.length);
    }
}

Value::~Value()
{
    if (mType == VALUE_TYPE_DATA_VALUE) {
        free(mValue.dataValue.data);
    }
}

String * Value::description()
{
    switch (mType) {
        case VALUE_TYPE_BOOL_VALUE:
            if (mValue.boolValue) {
                return MCSTR("true");
            }
            else {
                return MCSTR("false");
            }
        case VALUE_TYPE_CHAR_VALUE:
            return String::stringWithUTF8Format("%i", (int) mValue.charValue);
        case VALUE_TYPE_UNSIGNED_CHAR_VALUE:
            return String::stringWithUTF8Format("%u", (unsigned int) mValue.unsignedCharValue);
        case VALUE_TYPE_SHORT_VALUE:
            return String::stringWithUTF8Format("%i", (int) mValue.shortValue);
        case VALUE_TYPE_UNSIGNED_SHORT_VALUE:
            return String::stringWithUTF8Format("%u", (unsigned int) mValue.unsignedShortValue);
        case VALUE_TYPE_INT_VALUE:
            return String::stringWithUTF8Format("%i", mValue.intValue);
        case VALUE_TYPE_UNSIGNED_INT_VALUE:
            return String::stringWithUTF8Format("%u", mValue.unsignedIntValue);
        case VALUE_TYPE_LONG_VALUE:
            return String::stringWithUTF8Format("%li", mValue.longValue);
        case VALUE_TYPE_UNSIGNED_LONG_VALUE:
            return String::stringWithUTF8Format("%lu", mValue.unsignedLongValue);
        case VALUE_TYPE_LONG_LONG_VALUE:
            return String::stringWithUTF8Format("%lli", mValue.longLongValue);
        case VALUE_TYPE_UNSIGNED_LONG_LONG_VALUE:
            return String::stringWithUTF8Format("%llu", mValue.unsignedLongLongValue);
        case VALUE_TYPE_FLOAT_VALUE:
            return String::stringWithUTF8Format("%f", (double) mValue.floatValue);
        case VALUE_TYPE_DOUBLE_VALUE:
            return String::stringWithUTF8Format("%f", mValue.doubleValue);
        case VALUE_TYPE_POINTER_VALUE:
            return String::stringWithUTF8Format("%p", mValue.pointerValue);
        case VALUE_TYPE_DATA_VALUE:
            return String::stringWithUTF8Format("<Value:%p:data>", this);
        default:
            MCAssert(0);
            return NULL;
    }
}

bool Value::isEqual(Object * otherObject)
{
    Value * otherValue = (Value *) otherObject;
    if (otherValue->mType != mType)
        return false;
    if (mType == VALUE_TYPE_DATA_VALUE) {
        if (mValue.dataValue.length != otherValue->mValue.dataValue.length)
            return false;
        if (memcmp(&otherValue->mValue.dataValue.data, &mValue.dataValue.data, mValue.dataValue.length) != 0)
            return false;
    }
    else {
        if (memcmp(&otherValue->mValue, &mValue, sizeof(mValue)) != 0)
            return false;
    }
    return true;
}

unsigned int Value::hash()
{
    return hashCompute((const char *) &mValue, sizeof(mValue));
}

Object * Value::copy()
{
    return new Value(this);
}

Value * Value::valueWithBoolValue(bool value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_BOOL_VALUE;
    result->mValue.boolValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithCharValue(char value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_CHAR_VALUE;
    result->mValue.charValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithUnsignedCharValue(unsigned char value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_UNSIGNED_CHAR_VALUE;
    result->mValue.unsignedCharValue = value;
    return (Value *) result->autorelease();
}

///////////////////////

Value * Value::valueWithShortValue(short value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_SHORT_VALUE;
    result->mValue.shortValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithUnsignedShortValue(unsigned short value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_UNSIGNED_SHORT_VALUE;
    result->mValue.unsignedShortValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithIntValue(int value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_INT_VALUE;
    result->mValue.intValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithUnsignedIntValue(unsigned int value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_UNSIGNED_INT_VALUE;
    result->mValue.unsignedIntValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithLongValue(long value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_LONG_VALUE;
    result->mValue.longValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithUnsignedLongValue(unsigned long value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_UNSIGNED_LONG_VALUE;
    result->mValue.unsignedLongValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithLongLongValue(long long value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_LONG_LONG_VALUE;
    result->mValue.longLongValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithUnsignedLongLongValue(unsigned long long value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_UNSIGNED_LONG_LONG_VALUE;
    result->mValue.unsignedLongLongValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithFloatValue(float value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_FLOAT_VALUE;
    result->mValue.floatValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithDoubleValue(double value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_DOUBLE_VALUE;
    result->mValue.doubleValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithPointerValue(void * value)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_POINTER_VALUE;
    result->mValue.pointerValue = value;
    return (Value *) result->autorelease();
}

Value * Value::valueWithData(const char * value, int length)
{
    Value * result = new Value();
    result->mType = VALUE_TYPE_DATA_VALUE;
    result->mValue.dataValue.data = (char *) malloc(length);
    memcpy(result->mValue.dataValue.data, value, length);
    result->mValue.dataValue.length = length;
    return (Value *) result->autorelease();
}

bool Value::boolValue()
{
    return mValue.boolValue;
}

char Value::charValue()
{
    return mValue.charValue;
}

unsigned char Value::unsignedCharValue()
{
    return mValue.unsignedCharValue;
}

short Value::shortValue()
{
    return mValue.shortValue;
}

unsigned short Value::unsignedShortValue()
{
    return mValue.unsignedShortValue;
}

int Value::intValue()
{
    return mValue.intValue;
}

unsigned int Value::unsignedIntValue()
{
    return mValue.unsignedIntValue;
}

long Value::longValue()
{
    return mValue.longValue;
}

unsigned long Value::unsignedLongValue()
{
    return mValue.unsignedLongValue;
}

long long Value::longLongValue()
{
    return mValue.longLongValue;
}

unsigned long long Value::unsignedLongLongValue()
{
    return mValue.unsignedLongLongValue;
}

float Value::floatValue()
{
    return mValue.floatValue;
}

double Value::doubleValue()
{
    return mValue.doubleValue;
}

void * Value::pointerValue()
{
    return mValue.pointerValue;
}

void Value::dataValue(const char ** p_value, int * p_length)
{
    * p_value = mValue.dataValue.data;
    * p_length = mValue.dataValue.length;
}

int Value::type()
{
    return mType;
}

HashMap * Value::serializable()
{
    HashMap * result = Object::serializable();
    String * type = NULL;
    String * value = NULL;
    switch (mType) {
        case VALUE_TYPE_BOOL_VALUE:
            type = MCSTR("b");
            if (mValue.boolValue) {
                value = MCSTR("1");
            }
            else {
                value = MCSTR("0");
            }
            break;
        case VALUE_TYPE_CHAR_VALUE:
            type = MCSTR("c");
            value = String::stringWithUTF8Format("%i", (int) mValue.charValue);
            break;
        case VALUE_TYPE_UNSIGNED_CHAR_VALUE:
            type = MCSTR("uc");
            value = String::stringWithUTF8Format("%u", (unsigned int) mValue.unsignedCharValue);
            break;
        case VALUE_TYPE_SHORT_VALUE:
            type = MCSTR("s");
            value = String::stringWithUTF8Format("%i", (int) mValue.shortValue);
            break;
        case VALUE_TYPE_UNSIGNED_SHORT_VALUE:
            type = MCSTR("us");
            value = String::stringWithUTF8Format("%u", (unsigned int) mValue.unsignedShortValue);
            break;
        case VALUE_TYPE_INT_VALUE:
            type = MCSTR("i");
            value = String::stringWithUTF8Format("%i", mValue.intValue);
            break;
        case VALUE_TYPE_UNSIGNED_INT_VALUE:
            type = MCSTR("ui");
            value = String::stringWithUTF8Format("%u", mValue.unsignedIntValue);
            break;
        case VALUE_TYPE_LONG_VALUE:
            type = MCSTR("l");
            value = String::stringWithUTF8Format("%li", mValue.longValue);
            break;
        case VALUE_TYPE_UNSIGNED_LONG_VALUE:
            type = MCSTR("ul");
            value = String::stringWithUTF8Format("%lu", mValue.unsignedLongValue);
            break;
        case VALUE_TYPE_LONG_LONG_VALUE:
            type = MCSTR("ll");
            value = String::stringWithUTF8Format("%lli", mValue.longLongValue);
            break;
        case VALUE_TYPE_UNSIGNED_LONG_LONG_VALUE:
            type = MCSTR("ull");
            value = String::stringWithUTF8Format("%llu", mValue.unsignedLongLongValue);
            break;
        case VALUE_TYPE_FLOAT_VALUE:
            type = MCSTR("f");
            value = String::stringWithUTF8Format("%f", (double) mValue.floatValue);
            break;
        case VALUE_TYPE_DOUBLE_VALUE:
            type = MCSTR("lf");
            value = String::stringWithUTF8Format("%f", mValue.doubleValue);
            break;
        case VALUE_TYPE_POINTER_VALUE:
            MCAssert(0);
            break;
        case VALUE_TYPE_DATA_VALUE:
            type = MCSTR("data");
            value = Data::dataWithBytes(mValue.dataValue.data, mValue.dataValue.length)->base64String();
            break;
        default:
            MCAssert(0);
            break;
    }
    result->setObjectForKey(MCSTR("type"), type);
    result->setObjectForKey(MCSTR("value"), value);
    return result;
}

void Value::importSerializable(HashMap * serializable)
{
    String * type = (String *) serializable->objectForKey(MCSTR("type"));
    String * value = (String *) serializable->objectForKey(MCSTR("value"));
    if (type->isEqual(MCSTR("b"))) {
        mType = VALUE_TYPE_BOOL_VALUE;
        mValue.boolValue = (bool) value->intValue();
    }
    else if (type->isEqual(MCSTR("c"))) {
        mType = VALUE_TYPE_CHAR_VALUE;
        mValue.charValue = value->intValue();
    }
    else if (type->isEqual(MCSTR("uc"))) {
        mType = VALUE_TYPE_UNSIGNED_CHAR_VALUE;;
        mValue.unsignedCharValue = value->unsignedIntValue();
    }
    else if (type->isEqual(MCSTR("s"))) {
        mType = VALUE_TYPE_SHORT_VALUE;
        mValue.shortValue = value->intValue();
    }
    else if (type->isEqual(MCSTR("us"))) {
        mType = VALUE_TYPE_UNSIGNED_SHORT_VALUE;
        mValue.unsignedShortValue = value->unsignedIntValue();
    }
    else if (type->isEqual(MCSTR("i"))) {
        mType = VALUE_TYPE_INT_VALUE;
        mValue.intValue = value->intValue();
    }
    else if (type->isEqual(MCSTR("ui"))) {
        mType = VALUE_TYPE_UNSIGNED_INT_VALUE;
        mValue.unsignedIntValue = value->unsignedIntValue();
    }
    else if (type->isEqual(MCSTR("l"))) {
        mType = VALUE_TYPE_LONG_VALUE;
        mValue.longValue = value->unsignedIntValue();
    }
    else if (type->isEqual(MCSTR("ul"))) {
        mType = VALUE_TYPE_UNSIGNED_INT_VALUE;
        mValue.unsignedLongValue = value->unsignedIntValue();
    }
    else if (type->isEqual(MCSTR("ll"))) {
        mType = VALUE_TYPE_LONG_LONG_VALUE;
        mValue.longLongValue = value->longLongValue();
    }
    else if (type->isEqual(MCSTR("ull"))) {
        mType = VALUE_TYPE_UNSIGNED_LONG_LONG_VALUE;
        mValue.unsignedLongLongValue = value->unsignedLongLongValue();
    }
    else if (type->isEqual(MCSTR("f"))) {
        mType = VALUE_TYPE_FLOAT_VALUE;
        mValue.floatValue = value->doubleValue();
    }
    else if (type->isEqual(MCSTR("lf"))) {
        mType = VALUE_TYPE_DOUBLE_VALUE;
        mValue.doubleValue = value->doubleValue();
    }
    else if (type->isEqual(MCSTR("p"))) {
        MCAssert(0);
    }
    else if (type->isEqual(MCSTR("data"))) {
        mType = VALUE_TYPE_DATA_VALUE;
        Data * data = value->decodedBase64Data();
        mValue.dataValue.data = (char *) malloc(data->length());
        memcpy(mValue.dataValue.data, data->bytes(), data->length());
        mValue.dataValue.length = data->length();
    }
    else {
        MCAssert(0);
    }
}

void * Value::createObject()
{
    return new Value();
}

INITIALIZE(Value)
{
    Object::registerObjectConstructor("mailcore::Value", &Value::createObject);
}
