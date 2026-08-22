#ifndef MAILCORE_MCABSTRACTMESSAGE_H

#define MAILCORE_MCABSTRACTMESSAGE_H

#include <MailCore/MCBaseTypes.h>

#ifdef __cplusplus

namespace mailcore {
    
    class AbstractPart;
    class MessageHeader;
    
    class MAILCORE_EXPORT AbstractMessage : public Object {
    public:
        AbstractMessage();
        virtual ~AbstractMessage();
        
        /** Header of the message. */
        virtual MessageHeader * header();
        /** Set a header of the message. */
        virtual void setHeader(MessageHeader * header);
        
        /** Returns a part matching the given contentID. */
        virtual AbstractPart * partForContentID(String * contentID);
        /** Returns a part matching the given uniqueID */
        virtual AbstractPart * partForUniqueID(String * uniqueID);
        
        /** Returns the list of attachments, not part of the content of the message. */
        virtual Array * /* AbstractPart */ attachments();
        /** Returns the list of attachments that are shown inline in the content of the message. */
        virtual Array * /* AbstractPart */ htmlInlineAttachments();
        /** Returns the list of the text parts required to render the message properly. */
        virtual Array * /* AbstractPart */ requiredPartsForRendering();
        
    public: //subclass behavior
        AbstractMessage(AbstractMessage * other);
        virtual String * description();
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * hashmap);
        
    private:
        MessageHeader * mHeader;
        void init();
        
    };
    
}

#endif

#endif
