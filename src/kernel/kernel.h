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

_Static_assert(sizeof(uint8_t)   == 1, "[u8] has wrong size");
_Static_assert(sizeof(uint16_t)  == 2, "[u16] has wrong size");
_Static_assert(sizeof(uint32_t)  == 4, "[u32] has wrong size");
_Static_assert(sizeof(uint64_t)  == 8, "[u64] has wrong size");
_Static_assert(sizeof(int8_t)    == 1, "[i8] has wrong size");
_Static_assert(sizeof(int16_t)   == 2, "[i16] has wrong size");
_Static_assert(sizeof(int32_t)   == 4, "[i32] has wrong size");
_Static_assert(sizeof(int64_t)   == 8, "[i64] has wrong size");
_Static_assert(sizeof(float32_t) == 4, "[f32] has wrong size");
_Static_assert(sizeof(float64_t) == 8, "[f64] has wrong size");

#ifdef __cplusplus
extern "C"
{
#endif

extern uint8_t* read_disk_sector(uint8_t a_drive, uint64_t a_lhb);

extern void kernel_main(uint8_t a_bootDrive);


#ifdef __cplusplus
}
#endif
