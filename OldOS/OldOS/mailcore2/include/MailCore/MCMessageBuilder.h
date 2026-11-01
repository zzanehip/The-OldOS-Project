#ifndef MAILCORE_MCMESSAGEBUILDER_H

#define MAILCORE_MCMESSAGEBUILDER_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCAbstractMessage.h>

#ifdef __cplusplus

namespace mailcore {
    
    class Attachment;
    class HTMLRendererTemplateCallback;
    
    class MAILCORE_EXPORT MessageBuilder : public AbstractMessage {
    public:
        MessageBuilder();
        virtual ~MessageBuilder();
        
        virtual void setHTMLBody(String * htmlBody);
        virtual String * htmlBody();
        
        virtual void setTextBody(String * textBody);
        virtual String * textBody();
        
        virtual void setAttachments(Array * /* Attachment */ attachments);
        virtual Array * /* Attachment */ attachments();
        virtual void addAttachment(Attachment * attachment);
        
        // attachments (usually images) that are included in HTML.
        // a Content-ID should be assigned to these part to be able to reference
        // them in the HTML using a cid: URL.
        virtual void setRelatedAttachments(Array * /* Attachment */ attachments);
        virtual Array * /* Attachment */ relatedAttachments();
        virtual void addRelatedAttachment(Attachment * attachment);
        
        // When boundary needs to be prefixed (to go through spam filters).
        virtual void setBoundaryPrefix(String * boundaryPrefix);
        virtual String * boundaryPrefix();
        
        virtual Data * data();
        virtual Data * dataForEncryption();

        // Store builded message to file.
        virtual ErrorCode writeToFile(String * filename);

        virtual String * htmlRendering(HTMLRendererTemplateCallback * htmlCallback = NULL);
        virtual String * htmlBodyRendering();
        
        virtual String * plainTextRendering();
        virtual String * plainTextBodyRendering(bool stripWhitespace);
        
        virtual Data * openPGPSignedMessageDataWithSignatureData(Data * signature);
        virtual Data * openPGPEncryptedMessageDataWithEncryptedData(Data * encryptedData);
        
    public: // subclass behavior
        MessageBuilder(MessageBuilder * other);
        virtual String * description();
        virtual Object * copy();
        
    public: // private
        virtual String * nextBoundary();
        virtual void resetBoundaries();
        virtual void setBoundaries(Array * boundaries);
        
    private:
        String * mHTMLBody;
        String * mTextBody;
        Array * /* Attachment */ mAttachments;
        Array * /* Attachment */ mRelatedAttachments;
        String * mBoundaryPrefix;
        void init();
        Data * dataAndFilterBccAndForEncryption(bool filterBcc, bool forEncryption);
        struct mailmime * mimeAndFilterBccAndForEncryption(bool filterBcc, bool forEncryption);
        Array * mBoundaries;
        unsigned int mCurrentBoundaryIndex;
    };
    
};

#endif

#endif
