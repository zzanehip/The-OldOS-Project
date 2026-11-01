#ifndef MAILCORE_MCABSTRACTPART_H

#define MAILCORE_MCABSTRACTPART_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCMessageConstants.h>

#ifdef __cplusplus

namespace mailcore {
    
    class AbstractMessage;
    
    class MAILCORE_EXPORT AbstractPart : public Object {
    public:
        AbstractPart();
        virtual ~AbstractPart();
        
        virtual PartType partType();
        virtual void setPartType(PartType type);
        
        virtual String * filename();
        virtual void setFilename(String * filename);
        
        virtual String * mimeType();
        virtual void setMimeType(String * mimeType);
        
        virtual String * charset();
        virtual void setCharset(String * charset);
        
        virtual String * uniqueID();
        virtual void setUniqueID(String * uniqueID);
        
        virtual String * contentID();
        virtual void setContentID(String * contentID);
        
        virtual String * contentLocation();
        virtual void setContentLocation(String * contentLocation);
        
        virtual String * contentDescription();
        virtual void setContentDescription(String * contentDescription);
        
        virtual bool isInlineAttachment();
        virtual void setInlineAttachment(bool inlineAttachment);
        
        virtual bool isAttachment();
        virtual void setAttachment(bool attachment);

        virtual AbstractPart * partForContentID(String * contentID);
        virtual AbstractPart * partForUniqueID(String * uniqueID);
        
        virtual String * decodedStringForData(Data * data);
        
        void setContentTypeParameters(HashMap * parameters);
        Array * allContentTypeParametersNames();
        void setContentTypeParameter(String * name, String * object);
        void removeContentTypeParameter(String * name);
        String * contentTypeParameterValueForName(String * name);
        
    public: // subclass behavior
        AbstractPart(AbstractPart * other);
        virtual String * description();
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        
    public: // private
        virtual void importIMAPFields(struct mailimap_body_fields * fields,
                                      struct mailimap_body_ext_1part * extension);
        virtual void applyUniquePartID();
        
    private:
        String * mUniqueID;
        String * mFilename;
        String * mMimeType;
        String * mCharset;
        String * mContentID;
        String * mContentLocation;
        String * mContentDescription;
        bool mInlineAttachment;
        bool mAttachment;
        PartType mPartType;
        HashMap * mContentTypeParameters;
        void init();
    };
    
}

#endif

#endif
