#ifndef MAILCORE_MCDATA_H

#define MAILCORE_MCDATA_H

#include <stdlib.h>

#include <MailCore/MCObject.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __APPLE__
#import <CoreFoundation/CoreFoundation.h>
#endif

#ifdef __cplusplus

namespace mailcore {
    
    class String;

    typedef void (*BytesDeallocator)(char * bytes, unsigned int length);

    class MAILCORE_EXPORT Data : public Object {
    public:
        Data();
        Data(int capacity);
        Data(const char * bytes, unsigned int length);
        virtual ~Data();
        
        static Data * data();
        static Data * dataWithCapacity(int capacity);
        static Data * dataWithContentsOfFile(String * filename);
        static Data * dataWithBytes(const char * bytes, unsigned int length);
        
        virtual char * bytes();
        virtual unsigned int length();

        virtual void increaseCapacity(unsigned int length);
        
        virtual void appendData(Data * otherData);
        virtual void appendBytes(const char * bytes, unsigned int length);
        virtual void setBytes(const char * bytes, unsigned int length);
        virtual void setData(Data * otherData);
        
        // Helpers
        virtual String * stringWithDetectedCharset();
        virtual String * stringWithDetectedCharset(String * charset, bool isHTML);
        virtual String * stringWithCharset(const char * charset);
        virtual Data * decodedDataUsingEncoding(Encoding encoding);

        virtual String * base64String();

        virtual ErrorCode writeToFile(String * filename);

    public: // private
        virtual String * charsetWithFilteredHTML(bool filterHTML, String * hintCharset = NULL);

        /* Replace contents of Data instance with contents of a given bytes without extra copying.
         Memory ownership transferred from client code to the Data instance.
         Data destructor will call bytesDeallocator function for memory releasing.
         */
        void takeBytesOwnership(char * bytes, unsigned int length, BytesDeallocator bytesDeallocator);

#ifdef __APPLE__
        virtual CFDataRef destructiveNSData();
#endif
        
    public: // subclass behavior
        Data(Data * otherData);
        virtual String * description();
        virtual Object * copy();
        virtual bool isEqual(Object * otherObject);
        virtual unsigned int hash();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        
    private:
        char * mBytes;
        unsigned int mLength;
        unsigned int mAllocated;
        bool mExternallyAllocatedMemory;
        BytesDeallocator mBytesDeallocator;
        void allocate(unsigned int length, bool force = false);
        void init();
        void reset();
        String * charsetWithFilteredHTMLWithoutHint(bool filterHTML);
        
    };

}

#endif

#endif
