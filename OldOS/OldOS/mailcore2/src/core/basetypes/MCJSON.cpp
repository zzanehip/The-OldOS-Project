//
//  MCJSON.cpp
//  hermes
//
//  Created by DINH Viêt Hoà on 4/8/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCJSON.h"

#include <string.h>

#include "MCJSONParser.h"

using namespace mailcore;

String * JSON::objectToJSONString(Object * object)
{
    return JSONParser::stringFromObject(object);
}

Data * JSON::objectToJSONData(Object * object)
{
    return JSONParser::dataFromObject(object);
}

Object * JSON::objectFromJSONString(String * json)
{
    return JSONParser::objectFromString(json);
}

Object * JSON::objectFromJSONData(Data * json)
{
    return JSONParser::objectFromData(json);
}
