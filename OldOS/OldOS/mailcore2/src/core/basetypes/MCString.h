#ifndef MAILCORE_MCSTR_H

#define MAILCORE_MCSTR_H

#include <MailCore/MCObject.h>
#include <MailCore/MCRange.h>
#include <MailCore/MCICUTypes.h>

#include <stdlib.h>
#include <stdarg.h>

#ifdef __cplusplus

namespace mailcore {
    
    class Data;
    class Array;
    
    class MAILCORE_EXPORT String : public Object {
    public:
        String(const UChar * unicodeChars = NULL);
        String(const UChar * unicodeChars, unsigned int length);
        String(const char * UTF8Characters);
        String(Data * data, const char * charset);
        String(const char * bytes, unsigned int length, const char * charset = NULL);
        virtual ~String();
        
        static String * string();
        static String * stringWithUTF8Format(const char * format, ...);
        static String * stringWithVUTF8Format(const char * format, va_list ap);
        static String * stringWithUTF8Characters(const char * UTF8Characters);
        static String * stringWithCharacters(const UChar * characters);
        static String * stringWithCharacters(const UChar * characters, unsigned int length);
        static String * stringWithData(Data * data, const char * charset = NULL);
        
        virtual const UChar * unicodeCharacters();
        virtual const char * UTF8Characters();
        virtual unsigned int length();
        
        virtual void appendString(String * otherString);
        virtual void appendUTF8Format(const char * format, ...);
        virtual void appendCharacters(const UChar * unicodeCharacters);
        virtual void appendCharactersLength(const UChar * unicodeCharacters, unsigned int length);
        virtual void appendUTF8Characters(const char * UTF8Characters);
        virtual void setString(String * otherString);
        virtual void setUTF8Characters(const char * UTF8Characters);
        virtual void setCharacters(const UChar * unicodeCharacters);
        
        virtual String * stringByAppendingString(String * otherString);
        virtual String * stringByAppendingUTF8Format(const char * format, ...);
        virtual String * stringByAppendingUTF8Characters(const char * UTF8Characters);
        virtual String * stringByAppendingCharacters(const UChar * unicodeCharacters);
        virtual String * stringByAppendingPathComponent(String * component);
        virtual String * stringByDeletingLastPathComponent();
        virtual String * stringByDeletingPathExtension();

        virtual int compare(String * otherString);
        virtual int caseInsensitiveCompare(String * otherString);
        virtual String * lowercaseString();
        virtual String * uppercaseString();
        
        virtual UChar characterAtIndex(unsigned int idx);
        virtual void deleteCharactersInRange(Range range);
        virtual unsigned int replaceOccurrencesOfString(String * occurrence, String * replacement);
        virtual int locationOfString(String * occurrence);
        virtual int lastLocationOfString(String * occurrence);

        virtual Array * componentsSeparatedByString(String * separator);
        
        virtual bool isEqualCaseInsensitive(String * otherString);
        
        // Additions
        static String * stringByDecodingMIMEHeaderValue(const char * phrase);
        virtual Data * encodedAddressDisplayNameValue();
        virtual Data * encodedMIMEHeaderValue();
        virtual Data * encodedMIMEHeaderValueForSubject();
        virtual String * extractedSubject();
        virtual String * extractedSubjectAndKeepBracket(bool keepBracket);
        static String * uuidString();
        
        virtual bool hasSuffix(String * suffix);
        virtual bool hasPrefix(String * prefix);
        
        virtual String * substringFromIndex(unsigned int idx);
        virtual String * substringToIndex(unsigned int idx);
        virtual String * substringWithRange(Range range);
        
        virtual String * flattenHTML();
        virtual String * flattenHTMLAndShowBlockquote(bool showBlockquote);
        virtual String * flattenHTMLAndShowBlockquoteAndLink(bool showBlockquote, bool showLink);
        
        virtual String * stripWhitespace();
        
        virtual String * lastPathComponent();
        virtual String * pathExtension();
        virtual Data * dataUsingEncoding(const char * charset = NULL);
        
        virtual const char * fileSystemRepresentation();
        static String * stringWithFileSystemRepresentation(const char * filename);
        
        int intValue();
        unsigned int unsignedIntValue();
        long longValue();
        unsigned long unsignedLongValue();
        long long longLongValue();
        unsigned long long unsignedLongLongValue();
        double doubleValue();
        
        virtual Data * mUTF7EncodedData();
        static String * stringWithMUTF7Data(Data * data);
        virtual String * mUTF7EncodedString();
        virtual String * mUTF7DecodedString();
        
        virtual String * htmlEncodedString();
        virtual String * cleanedHTMLString();
        virtual String * htmlMessageContent();
        
        virtual Data * decodedBase64Data();
        
        virtual String * urlDecodedString();
        virtual String * urlEncodedString();

    public: // private
        static String * uniquedStringWithUTF8Characters(const char * UTF8Characters);
        
    public: // subclass behavior
        String(String * otherString);
        virtual String * description();
        virtual Object * copy();
        virtual bool isEqual(Object * otherObject);
        virtual unsigned int hash();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        
    private:
        UChar * mUnicodeChars;
        unsigned int mLength;
        unsigned int mAllocated;
        void allocate(unsigned int length, bool force = false);
        void reset();
        int compareWithCaseSensitive(String * otherString, bool caseSensitive);
        void appendBytes(const char * bytes, unsigned int length, const char * charset);
        void appendUTF8CharactersLength(const char * UTF8Characters, unsigned int length);
    };
    
    MAILCORE_EXPORT
    void setICUDataDirectory(String * directory);
}

#endif

#endif
