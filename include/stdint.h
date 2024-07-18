#ifndef STDINT_H
#define STDINT_H

typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;

typedef signed char        int8_t;
typedef signed short       int16_t;
typedef signed int         int32_t;
typedef signed long long   int64_t;

typedef float              float32_t;
typedef double             float64_t;

typedef uint64_t           size_t;
typedef int64_t            ssize_t;

typedef uint64_t           uintptr_t;
typedef int64_t 		   intptr_t;

typedef int8_t             bool;

#define SIZE_CHECK(type, size) _Static_assert(sizeof(type) == size, "[" #type "] has wrong size")

SIZE_CHECK(uint8_t, 1);
SIZE_CHECK(uint16_t, 2);
SIZE_CHECK(uint32_t, 4);
SIZE_CHECK(uint64_t, 8);
SIZE_CHECK(int8_t, 1);
SIZE_CHECK(int16_t, 2);
SIZE_CHECK(int32_t, 4);
SIZE_CHECK(int64_t, 8);
SIZE_CHECK(float32_t, 4);
SIZE_CHECK(float64_t, 8);

#endif  // STDINT_H
