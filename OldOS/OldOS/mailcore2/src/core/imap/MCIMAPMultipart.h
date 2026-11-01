#ifndef MAILCORE_MCIMAPMULTIPART_H

#define MAILCORE_MCIMAPMULTIPART_H

#include <MailCore/MCAbstractMultipart.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT IMAPMultipart : public AbstractMultipart {
    public:
        IMAPMultipart();
        virtual ~IMAPMultipart();
        
        virtual void setPartID(String * partID);
        virtual String * partID();
        
    public: // subclass behavior
        IMAPMultipart(IMAPMultipart * other);
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        
    private:
        String * mPartID;
        void init();
    };
    
}

#endif

#endif
