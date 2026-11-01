#ifndef MAILCORE_MCVALUE_H

#define MAILCORE_MCVALUE_H

#include <MailCore/MCObject.h>

#ifdef __cplusplus

namespace mailcore {
    
    class String;
    
    enum {
        ValueTypeNone,
        ValueTypeBool,
        ValueTypeChar,
        ValueTypeUnsignedChar,
        ValueTypeShort,
        ValueTypeUnsignedShort,
        ValueTypeInt,
        ValueTypeUnsignedInt,
        ValueTypeLong,
        ValueTypeUnsignedLong,
        ValueTypeLongLong,
        ValueTypeUnsignedLongLong,
        ValueTypeFloat,
        ValueTypeDouble,
        ValueTypePointer,
        ValueTypeData,
    };
    
    class MAILCORE_EXPORT Value : public Object {
    public:
        virtual ~Value();
        
        static Value * valueWithBoolValue(bool value);
        static Value * valueWithCharValue(char value);
        static Value * valueWithUnsignedCharValue(unsigned char value);
        static Value * valueWithShortValue(short value);
        static Value * valueWithUnsignedShortValue(unsigned short value);
        static Value * valueWithIntValue(int value);
        static Value * valueWithUnsignedIntValue(unsigned int value);
        static Value * valueWithLongValue(long value);
        static Value * valueWithUnsignedLongValue(unsigned long value);
        static Value * valueWithLongLongValue(long long value);
        static Value * valueWithUnsignedLongLongValue(unsigned long long value);
        static Value * valueWithFloatValue(float value);
        static Value * valueWithDoubleValue(double value);
        static Value * valueWithPointerValue(void * value);
        static Value * valueWithData(const char * value, int length);
        
        virtual bool boolValue();
        virtual char charValue();
        virtual unsigned char unsignedCharValue();
        virtual short shortValue();
        virtual unsigned short unsignedShortValue();
        virtual int intValue();
        virtual unsigned int unsignedIntValue();
        virtual long longValue();
        virtual unsigned long unsignedLongValue();
        virtual long long longLongValue();
        virtual unsigned long long unsignedLongLongValue();
        virtual float floatValue();
        virtual double doubleValue();
        virtual void * pointerValue();
        virtual void dataValue(const char ** p_value, int * p_length);
        
    public: // subclass behavior
        Value(Value * other);
        virtual String * description();
        virtual bool isEqual(Object * otherObject);
        virtual unsigned int hash();
        Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        
    public: // private
        static void * createObject();
        
    private:
        int mType;
        union {
            bool boolValue;
            char charValue;
            unsigned char unsignedCharValue;
            short shortValue;
            unsigned short unsignedShortValue;
            int intValue;
            unsigned int unsignedIntValue;
            long longValue;
            unsigned long unsignedLongValue;
            long long longLongValue;
            unsigned long long unsignedLongLongValue;
            float floatValue;
            double doubleValue;
            void * pointerValue;
            struct {
                char * data;
                int length;
            } dataValue;
        } mValue;
        Value();
        
    public: // private
        virtual int type();
        
    };
    
}

#endif

#endif
