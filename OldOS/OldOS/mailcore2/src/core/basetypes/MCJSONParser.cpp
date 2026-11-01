//
//  JSONParser.cpp
//  mailcore2
//
//  Created by DINH Viêt Hoà on 4/17/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCJSONParser.h"

#include <stdlib.h>

#include "MCUtils.h"
#include "MCString.h"
#include "MCData.h"
#include "MCHashMap.h"
#include "MCArray.h"
#include "MCValue.h"
#include "MCNull.h"
#include "MCAutoreleasePool.h"
#include "MCAssert.h"

using namespace mailcore;

void JSONParser::init()
{
    mContent = NULL;
    mResult = NULL;
    mPosition = 0;
}

JSONParser::JSONParser()
{
    init();
}

JSONParser::~JSONParser()
{
    MC_SAFE_RELEASE(mResult);
    MC_SAFE_RELEASE(mContent);
}

String * JSONParser::content()
{
    return mContent;
}

void JSONParser::setContent(String * content)
{
    MC_SAFE_REPLACE_RETAIN(String, mContent, content);
}

unsigned int JSONParser::position()
{
    return mPosition;
}

void JSONParser::setPosition(unsigned int position)
{
    mPosition = position;
}

Object * JSONParser::result()
{
    return mResult;
}

bool JSONParser::parse()
{
    skipBlank();
    if (parseDictionary())
        return true;
    if (parseArray())
        return true;
    if (parseBoolean())
        return true;
    if (parseNull())
        return true;
    if (parseFloat())
        return true;
    if (parseString())
        return true;
    
    return false;
}

bool JSONParser::isEndOfExpression()
{
    if (mPosition == mContent->length())
        return true;
    
    if (mContent->characterAtIndex(mPosition) == ';')
        return true;
    
    return false;
}

void JSONParser::skipBlank()
{
    mPosition = skipBlank(mPosition);
}

unsigned int JSONParser::skipBlank(unsigned int position)
{
    while (1) {
        UChar ch;
        
        if (position >= mContent->length())
            break;
        
        ch = mContent->characterAtIndex(position);
        if ((ch == ' ') || (ch == '\t') || (ch == '\r') || (ch == '\n'))
            position ++;
        else
            break;
    }
    
    return position;
}

bool JSONParser::parseDictionary()
{
    int position;
    HashMap * dict;
    
    position = mPosition;
    
    if (!scanCharacter('{', position)) {
        return false;
    }
    position ++;
    position = skipBlank(position);
    
    dict = HashMap::hashMap();
    
    if (scanCharacter('}', position)) {
        position ++;
    }
    else {
        while (1) {
            JSONParser * keyParser;
            JSONParser * valueParser;
            String * key;
            Object * value;
            
            if (position >= mContent->length())
                return false;
            
            key = NULL;
            keyParser = new JSONParser();
            keyParser->autorelease();
            keyParser->setContent(mContent);
            keyParser->setPosition(position);
            if (!keyParser->parse())
                return false;
            
            if (!keyParser->result()->className()->isEqual(MCSTR("mailcore::String")))
                return false;
            
            key = (String *) keyParser->result();
            position = keyParser->position();
            
            position = skipBlank(position);
            
            if (!scanCharacter(':', position))
                return false;
            position ++;
            
            position = skipBlank(position);
            
            value = NULL;
            valueParser = new JSONParser();
            valueParser->autorelease();
            valueParser->setContent(mContent);
            valueParser->setPosition(position);
            if (!valueParser->parse())
                return false;
            
            value = valueParser->result();
            position = valueParser->position();
            
            dict->setObjectForKey(key, value);
            
            position = skipBlank(position);
            
            if (scanCharacter(',', position)) {
                position ++;
                position = skipBlank(position);
            }
            else if (scanCharacter('}', position)) {
                position ++;
                break;
            }
            else {
                return false;
            }
        }
    }
    
    mResult = dict->retain();
    mPosition = position;
    
    return true;
}

bool JSONParser::scanCharacter(UChar ch, unsigned int position)
{
    if (position >= mContent->length())
        return false;
    
    if (mContent->characterAtIndex(position) != ch)
        return false;
    
    return true;
}

bool JSONParser::scanKeyword(String * str, unsigned int position)
{
    bool result;
    AutoreleasePool * pool;
    
    if (position + str->length() >= mContent->length())
        return false;
    
    pool = new AutoreleasePool();
    
    result = false;
    if (mContent->substringWithRange(RangeMake(position, str->length()))->isEqual(str))
        result = true;
    pool->release();
    
    return result;
}

bool JSONParser::parseArray()
{
    int position;
    Array * array;
    
    position = mPosition;
    
    if (!scanCharacter('[', position)) {
        return false;
    }
    position ++;
    position = skipBlank(position);
    
    array = Array::array();
    
    if (scanCharacter(']', position)) {
        position ++;
    }
    else {
        while (1) {
            JSONParser * valueParser;
            Object * value;
            
            if (position >= mContent->length())
                return false;
            
            value = NULL;
            valueParser = new JSONParser();
            valueParser->setContent(mContent);
            valueParser->setPosition(position);
            valueParser->autorelease();
            if (!valueParser->parse())
                return false;
            
            value = valueParser->result();
            
            position = valueParser->position();
            array->addObject(value);
            
            position = skipBlank(position);
            
            if (scanCharacter(',', position)) {
                position ++;
                position = skipBlank(position);
            }
            else if (scanCharacter(']', position)) {
                position ++;
                break;
            }
            else {
                return false;
            }
        }
    }
    
    mResult = array->retain();
    mPosition = position;
    
    return true;
}

static inline int hexToInt(UChar inCharacter)
{
    if (inCharacter >= '0' && inCharacter <= '9') {
        return inCharacter - '0';
    }
    else if (inCharacter >= 'a' && inCharacter <= 'f') {
        return inCharacter - 'a' + 10;
    }
    else if (inCharacter >= 'A' && inCharacter <= 'F') {
        return inCharacter - 'A' + 10;
    }
    else {
        return -1;
    }
}

bool JSONParser::parseString()
{
    unsigned int position;
    String * str;
    bool doubleQuote = false;
    bool startString;
    bool endOfString;
    
    position = mPosition;
    
    startString = false;
    if (scanCharacter('\"', position)) {
        doubleQuote = true;
        startString = true;
    }
    else if (scanCharacter('\'', position)) {
        startString = true;
    }
    
    if (!startString)
        return false;
    
    position ++;
    
    str = String::string();
    
    endOfString = false;
    while (1) {
        UChar ch;
        
        if (position >= mContent->length())
            return false;
        
        ch = mContent->characterAtIndex(position);
        switch (ch) {
            case '\\':
            {
                position ++;
                
                if (position >= mContent->length())
                    return false;
                
                ch = mContent->characterAtIndex(position);
                switch (ch) {
                    case '0':
                    case '1':
                    case '2':
                    case '3':
                    case '4':
                    case '5':
                    case '6':
                    case '7': {
                        UChar char_value;
                        unsigned int count;
                        
                        count = 0;
                        char_value = 0;
                        while ((ch >= '0') && (ch <= '7')) {
                            int value;
                            
                            value = hexToInt(ch);
                            if (value == -1)
                                break;
                            
                            char_value = char_value * 8 + value;
                            count ++;
                            position ++;
                            if (count >= 3)
                                break;
                            if (position >= mContent->length())
                                break;
                            ch = mContent->characterAtIndex(position);
                        }
                        UChar characters[2];
                        characters[0] = char_value;
                        characters[1] = 0;
                        str->appendCharactersLength(characters, 1);
                        break;
                    }
                    case 'b':
                        str->appendString(MCSTR("\b"));
                        position ++;
                        break;
                    case 't':
                        str->appendString(MCSTR("\t"));
                        position ++;
                        break;
                    case 'n':
                        str->appendString(MCSTR("\n"));
                        position ++;
                        break;
                    case 'r':
                        str->appendString(MCSTR("\r"));
                        position ++;
                        break;
                    case 'f':
                        str->appendString(MCSTR("\f"));
                        position ++;
                        break;
                    case 'v':
                        str->appendString(MCSTR("\v"));
                        position ++;
                        break;
                    case '\"':
                        str->appendString(MCSTR("\""));
                        position ++;
                        break;
                    case '\'':
                        str->appendString(MCSTR("\'"));
                        position ++;
                        break;
                    case '\\':
                        str->appendString(MCSTR("\\"));
                        position ++;
                        break;
                    case '/':
                        str->appendString(MCSTR("/"));
                        position ++;
                        break;
                    case 'u': {
                        unsigned int i;
                        UChar char_value;
                        
                        position ++;
                        char_value = 0;
                        for(i = 0 ; i < 4 ; i ++) {
                            int value;
                            
                            if (position >= mContent->length())
                                return false;
                            ch = mContent->characterAtIndex(position);
                            value = hexToInt(ch);
                            if (value == -1)
                                break;
                            
                            char_value = char_value * 16 + value;
                            position ++;
                        }
                        
                        UChar characters[2];
                        characters[0] = char_value;
                        characters[1] = 0;
                        str->appendCharactersLength(characters, 1);
                        
                        break;
                    }
                    case 'x': {
                        unsigned int i;
                        UChar char_value;
                        
                        position ++;
                        char_value = 0;
                        for(i = 0 ; i < 2 ; i ++) {
                            int value;
                            
                            if (position >= mContent->length())
                                return false;
                            ch = mContent->characterAtIndex(position);
                            value = hexToInt(ch);
                            if (value == -1)
                                break;
                            
                            char_value = char_value * 16 + value;
                            position ++;
                        }
                        
                        UChar characters[2];
                        characters[0] = char_value;
                        characters[1] = 0;
                        str->appendCharactersLength(characters, 1);
                        
                        break;
                    }
                    default: {
                        UChar characters[3];
                        characters[0] = '\\';
                        characters[1] = ch;
                        characters[2] = 0;
                        str->appendCharactersLength(characters, 2);
                        
                        position ++;
                        break;
                    }
                }
                break;
            }
                
            case '\'':
                position ++;
                if (!doubleQuote)
                    endOfString = true;
                else
                    str->appendString(MCSTR("\'"));
                break;
            case '\"':
                position ++;
                if (doubleQuote)
                    endOfString = true;
                else
                    str->appendString(MCSTR("\""));
                break;
            default: {
                position ++;
                UChar characters[2];
                characters[0] = ch;
                characters[1] = 0;
                str->appendCharactersLength(characters, 1);
                break;
            }
        }
        
        if (endOfString)
            break;
    }
    
    mResult = str->retain();
    mPosition = position;
    
    return true;
}

bool JSONParser::parseBoolean()
{
    if (scanKeyword(MCSTR("true"), mPosition)) {
        mPosition += MCSTR("true")->length();
        mResult = Value::valueWithBoolValue(true)->retain();;
        return true;
    }
    
    if (scanKeyword(MCSTR("false"), mPosition)) {
        mPosition += MCSTR("false")->length();
        mResult = Value::valueWithBoolValue(false)->retain();;
        return true;
    }
    
    return false;
}

bool JSONParser::parseNull()
{
    if (scanKeyword(MCSTR("null"), mPosition)) {
        mPosition += MCSTR("null")->length();
        mResult = Null::null()->retain();
        return true;
    }
    
    return false;
}

bool JSONParser::parseFloat()
{
    const char * str;
    char * endptr;
    double value;
    char * endptrInt;
    long long valueInt;
    
    AutoreleasePool * pool;
    
    pool = new AutoreleasePool();
    if (mContent->length() > mPosition + 50) {
        str = mContent->substringWithRange(RangeMake(mPosition, 50))->UTF8Characters();
    }
    else {
        str = mContent->substringFromIndex(mPosition)->UTF8Characters();
    }
    value = strtod(str, &endptr);
    if (endptr == str) {
        pool->release();
        return false;
    }
    valueInt = strtoll(str, &endptrInt, 0);
    if (endptr == endptrInt) {
        mPosition += endptrInt - str;
        mResult = Value::valueWithLongLongValue(valueInt)->retain();
    }
    else {
        mPosition += endptr - str;
        mResult = Value::valueWithDoubleValue(value)->retain();
    }
    pool->release();
    
    return true;
}

Object * JSONParser::objectFromData(Data * data)
{
    String * str = NULL;
    Object * result;
    
    str = String::stringWithData(data, "utf-8");
    if (str == NULL)
        return NULL;
    
    result = objectFromString(str);
    
    return result;
}

Object * JSONParser::objectFromString(String * str)
{
    Object * result;
    JSONParser * parser;
    
    parser = new JSONParser();
    parser->setContent(str);
    parser->parse();
    result = parser->result();
    if (result != NULL) {
        result->retain()->autorelease();
    }
    parser->release();
    
    return result;
}

Data * JSONParser::dataFromObject(Object * object)
{
    return stringFromObject(object)->dataUsingEncoding("utf-8");
}

String * JSONParser::stringFromObject(Object * object)
{
    String * result;
    
    result = String::string();
    appendStringFromObject(object, result);
    
    return result;
}


String * JSONParser::JSStringFromString(String * str)
{
    unsigned int i;
    String * result;
    
    result = String::string();
    for(i = 0 ; i < str->length() ; i ++) {
        UChar ch;
        
        ch = str->characterAtIndex(i);
        if ((ch >= '0') && (ch <= '9')) {
            UChar characters[2];
            characters[0] = ch;
            characters[1] = 0;
            result->appendCharactersLength(characters, 1);
        }
        else if ((ch >= 'a') && (ch <= 'z')) {
            UChar characters[2];
            characters[0] = ch;
            characters[1] = 0;
            result->appendCharactersLength(characters, 1);
        }
        else if ((ch >= 'A') && (ch <= 'Z')) {
            UChar characters[2];
            characters[0] = ch;
            characters[1] = 0;
            result->appendCharactersLength(characters, 1);
        }
        else {
            switch (ch) {
                case ' ':
                case '.':
                case ',':
                case '<':
                case '>':
                case '(':
                case ')':
                case '!':
                case '@':
                case '#':
                case '$':
                case '%':
                case '^':
                case '&':
                case '*':
                case '-':
                case '_':
                case '+':
                case '=':
                case '?':
                case '{':
                case '}':
                case '[':
                case ']':
                case ':':
                case ';':
                case '|':
                case '~':
                case '\'': {
                    UChar characters[2];
                    characters[0] = ch;
                    characters[1] = 0;
                    result->appendCharactersLength(characters, 1);
                    break;
                }
                case '"':
                case '/':
                case '\\': {
                    UChar characters[3];
                    characters[0] = '\\';
                    characters[1] = ch;
                    characters[2] = 0;
                    result->appendCharactersLength(characters, 2);
                    break;
                }
                default: {
                    result->appendUTF8Format("\\u%04x", (unsigned int) ch);
                    break;
                }
            }
        }
    }
    
    return result;
}

void JSONParser::appendStringFromObject(Object * object, String * string)
{
    if (object->className()->isEqual(MCSTR("mailcore::String"))) {
        string->appendString(MCSTR("\""));
        string->appendString(JSStringFromString((String *) object));
        string->appendString(MCSTR("\""));
    }
    else if (object->className()->isEqual(MCSTR("mailcore::Value"))) {
        Value * value = (Value *) object;
        switch (value->type()) {
            case ValueTypeBool:
                string->appendString(value->boolValue() ? MCSTR("true") : MCSTR("false"));
                break;
            case ValueTypeChar:
                string->appendUTF8Format("%i", (int) value->charValue());
                break;
            case ValueTypeUnsignedChar:
                string->appendUTF8Format("%i", (int) value->unsignedCharValue());
                break;
            case ValueTypeShort:
                string->appendUTF8Format("%i", (int) value->shortValue());
                break;
            case ValueTypeUnsignedShort:
                string->appendUTF8Format("%i", (int) value->unsignedShortValue());
                break;
            case ValueTypeInt:
                string->appendUTF8Format("%i", (int) value->intValue());
                break;
            case ValueTypeUnsignedInt:
                string->appendUTF8Format("%u", (int) value->unsignedIntValue());
                break;
            case ValueTypeLong:
                string->appendUTF8Format("%ld", value->longValue());
                break;
            case ValueTypeUnsignedLong:
                string->appendUTF8Format("%lu", value->unsignedLongValue());
                break;
            case ValueTypeLongLong:
                string->appendUTF8Format("%lld", value->longLongValue());
                break;
            case ValueTypeUnsignedLongLong:
                string->appendUTF8Format("%llu", value->unsignedLongLongValue());
                break;
            case ValueTypeFloat:
                string->appendUTF8Format("%g", value->floatValue());
                break;
            case ValueTypeDouble:
                string->appendUTF8Format("%lg", value->doubleValue());
                break;
            default:
                MCAssert(0);
                break;
        }
    }
    else if (object->className()->isEqual(MCSTR("mailcore::Null"))) {
        string->appendString(MCSTR("null"));
    }
    else if (object->className()->isEqual(MCSTR("mailcore::Array"))) {
        Array * array;
        bool first;
        
        first = true;
        array = (Array *) object;
        string->appendString(MCSTR("["));
        for(unsigned int i = 0 ; i < array->count() ; i ++) {
            Object * arrayElement = array->objectAtIndex(i);
            if (first) {
                first = false;
            }
            else {
                string->appendString(MCSTR(","));
            }
            appendStringFromObject(arrayElement, string);
        }
        string->appendString(MCSTR("]"));
    }
    else if (object->className()->isEqual(MCSTR("mailcore::HashMap"))) {
        HashMap * dict;
        bool first;
        
        first = true;
        dict = (HashMap *) object;
        string->appendString(MCSTR("{"));
        Array * keys = dict->allKeys();
        for(unsigned int i = 0 ; i < keys->count() ; i ++) {
            String * key = (String *) keys->objectAtIndex(i);
            
            if (first) {
                first = false;
            }
            else {
                string->appendString(MCSTR(","));
            }
            appendStringFromObject(key, string);
            string->appendString(MCSTR(":"));
            appendStringFromObject(dict->objectForKey(key), string);
        }
        string->appendString(MCSTR("}"));
    }
}
