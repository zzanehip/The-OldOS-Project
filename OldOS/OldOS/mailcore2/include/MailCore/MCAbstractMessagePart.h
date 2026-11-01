#ifndef MAILCORE_MCABSTRACTMESSAGEPART_H

#define MAILCORE_MCABSTRACTMESSAGEPART_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCAbstractPart.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MessageHeader;
    
    class MAILCORE_EXPORT AbstractMessagePart : public AbstractPart {
    public:
        AbstractMessagePart();
        virtual ~AbstractMessagePart();
        
        virtual MessageHeader * header();
        virtual void setHeader(MessageHeader * header);
        
        virtual AbstractPart * mainPart();
        virtual void setMainPart(AbstractPart * mainPart);
        
    public: //subclass behavior
        AbstractMessagePart(AbstractMessagePart * other);
        virtual String * description();
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        
        virtual AbstractPart * partForContentID(String * contentID);
        virtual AbstractPart * partForUniqueID(String * uniqueID);
        
    private:
        AbstractPart * mMainPart;
        MessageHeader * mHeader;
        void init();
    };
    
}

#endif

#endif
