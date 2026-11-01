#ifndef MAILCORE_MCMULTIPART_H

#define MAILCORE_MCMULTIPART_H

#include <MailCore/MCBaseTypes.h>
#include <MailCore/MCAbstractMultipart.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT Multipart : public AbstractMultipart {
    public:
        Multipart();
        virtual ~Multipart();

        virtual void setPartID(String * partID);
        virtual String * partID();

    public: // subclass behavior
        Multipart(Multipart * other);
        virtual Object * copy();

    private:
        String * mPartID;

        void init();
    };
    
}

#endif

#endif
