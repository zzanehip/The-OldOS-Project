#ifndef MAILCORE_MCATTACHMENT_H

#define MAILCORE_MCATTACHMENT_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCAbstractPart.h>
#include <MailCore/MCAbstractMultipart.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MessagePart;
    
    class MAILCORE_EXPORT Attachment : public AbstractPart {
    public:
        static String * mimeTypeForFilename(String * filename);
        static Attachment * attachmentWithContentsOfFile(String * filename);
        static Attachment * attachmentWithData(String * filename, Data * data);
        static Attachment * attachmentWithHTMLString(String * htmlString);
        static Attachment * attachmentWithRFC822Message(Data * messageData);
        static Attachment * attachmentWithText(String * text);
        
        Attachment();
        virtual ~Attachment();
        
        virtual void setPartID(String * partID);
        virtual String * partID();

        virtual void setData(Data * data);
        virtual Data * data();
        virtual String * decodedString();
        
    public: // subclass behavior
        Attachment(Attachment * other);
        virtual String * description();
        virtual Object * copy();
        
    public: // private
        static AbstractPart * attachmentsWithMIME(struct mailmime * mime);
        
    private:
        Data * mData;
        String * mPartID;

        void init();
        static void fillMultipartSubAttachments(AbstractMultipart * multipart, struct mailmime * mime);
        static AbstractPart * attachmentsWithMIMEWithMain(struct mailmime * mime, bool isMain);
        static Attachment * attachmentWithSingleMIME(struct mailmime * mime);
        static MessagePart * attachmentWithMessageMIME(struct mailmime * mime);
        static Encoding encodingForMIMEEncoding(struct mailmime_mechanism * mechanism, int defaultMimeEncoding);
        static HashMap * readMimeTypesFile(String * filename);
        void setContentTypeParameters(HashMap * parameters);
    };
    
}

#endif

#endif
