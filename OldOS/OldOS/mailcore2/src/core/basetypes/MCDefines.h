#ifndef MCDEFINES_H_

#define MCDEFINES_H_

#ifdef _MSC_VER

#pragma section(".CRT$XCU",read)
#define INITIALIZE(name) \
    static void __cdecl initialize_##name(void); \
    __declspec(allocate(".CRT$XCU")) void (__cdecl*initialize_##name##_)(void) = initialize_##name; \
    static void __cdecl initialize_##name(void)

#else

#define INITIALIZE(name) \
   static void initialize(void) __attribute__((constructor)); \
   static void initialize(void)

#endif

#endif
