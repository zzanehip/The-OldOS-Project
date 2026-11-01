#ifndef MAILCORE_MCNNTPGROUPINFO_H

#define MAILCORE_MCNNTPGROUPINFO_H

#include <MailCore/MCBaseTypes.h>

#ifdef __cplusplus

namespace mailcore {
    
    class MAILCORE_EXPORT NNTPGroupInfo : public Object {
    public:
        NNTPGroupInfo();
        virtual ~NNTPGroupInfo();
        
        virtual void setName(String * uid);
        virtual String * name();
        
        virtual void setMessageCount(uint32_t messages);
        virtual uint32_t messageCount();
        
    public: // subclass behavior
        NNTPGroupInfo(NNTPGroupInfo * other);
        virtual String * description();
        virtual Object * copy();
        
    private:
        String * mName;
        uint32_t mMessageCount;
        
        void init();
    };
    
}

#endif

#endif
