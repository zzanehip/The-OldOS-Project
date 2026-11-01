//
//  JSONParser.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 4/17/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_MCJSONPARSER_H

#define MAILCORE_MCJSONPARSER_H

#include <MailCore/MCObject.h>
#include <MailCore/MCICUTypes.h>
#include <MailCore/MCUtils.h>

namespace mailcore {
    
    class Data;
    class String;
    
    class MAILCORE_EXPORT JSONParser : public Object {
    public:
        JSONParser();
        virtual ~JSONParser();
        
        virtual String * content();
        virtual void setContent(String * content);
        
        virtual unsigned int position();
        virtual void setPosition(unsigned int position);
        
        virtual Object * result();
        
        virtual bool parse();
        
        virtual bool isEndOfExpression();
        
        static Object * objectFromData(Data * data);
        static Object * objectFromString(String * str);
        
        static Data * dataFromObject(Object * object);
        static String * stringFromObject(Object * object);
        
    private:
        Object * mResult;
        unsigned int mPosition;
        String * mContent;
        void init();
        
        void skipBlank();
        unsigned int skipBlank(unsigned int position);
        bool parseDictionary();
        bool scanCharacter(UChar ch, unsigned int position);
        bool scanKeyword(String * str, unsigned int position);
        bool parseArray();
        bool parseString();
        bool parseBoolean();
        bool parseNull();
        bool parseFloat();
        static String * JSStringFromString(String * str);
        static void appendStringFromObject(Object * object, String * string);
    };

}

#endif