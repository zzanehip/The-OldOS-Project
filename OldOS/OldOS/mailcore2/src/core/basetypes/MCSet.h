#ifndef MAILCORE_CSET_H

#define MAILCORE_CSET_H

#include <MailCore/MCObject.h>

#ifdef __cplusplus

namespace mailcore {
    
    class String;
    class Array;
    class HashMap;
    
    class MAILCORE_EXPORT Set : public Object {
    public:
        Set();
        Set(Set * o);
        
        static Set * set();
        static Set * setWithArray(Array * objects);
        
        virtual unsigned int count();
        virtual void addObject(Object * obj);
        virtual void removeObject(Object * obj);
        virtual bool containsObject(Object * obj);
        virtual Object * member(Object * obj);
        
        virtual Array * allObjects();
        virtual void removeAllObjects();
        virtual void addObjectsFromArray(Array * objects);
        
    public: // subclass behavior
        virtual ~Set();
        virtual String * description();
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        
    private:
        HashMap * mHash;
        void init();
    };

}

#endif

#endif
