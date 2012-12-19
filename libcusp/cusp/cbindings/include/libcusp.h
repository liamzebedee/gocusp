#ifndef __CUSP_ML_H__
#define __CUSP_ML_H__

/* Copyright (C) 2004-2007 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

#ifndef _MLTON_MLTYPES_H_
#define _MLTON_MLTYPES_H_

/* We need these because in header files for exported SML functions, 
 * types.h is included without cenv.h.
 */
#ifndef _ISOC99_SOURCE
#define _ISOC99_SOURCE
#endif
#if (defined (_AIX) || defined (__hpux__) || defined (__OpenBSD__))
#include <inttypes.h>
#elif (defined (__sun__))
#include <sys/int_types.h>
#else
#include <stdint.h>
#endif

/* ML types */
typedef unsigned char PointerAux __attribute__ ((may_alias));
typedef PointerAux* Pointer;
#define Array(t) Pointer
#define Ref(t) Pointer
#define Vector(t) Pointer

typedef int8_t Int8_t;
typedef int8_t Int8;
typedef int16_t Int16_t;
typedef int16_t Int16;
typedef int32_t Int32_t;
typedef int32_t Int32;
typedef int64_t Int64_t;
typedef int64_t Int64;
typedef float Real32_t;
typedef float Real32;
typedef double Real64_t;
typedef double Real64;
typedef uint8_t Word8_t;
typedef uint8_t Word8;
typedef uint16_t Word16_t;
typedef uint16_t Word16;
typedef uint32_t Word32_t;
typedef uint32_t Word32;
typedef uint64_t Word64_t;
typedef uint64_t Word64;

typedef Int8_t WordS8_t;
typedef Int8_t WordS8;
typedef Int16_t WordS16_t;
typedef Int16_t WordS16;
typedef Int32_t WordS32_t;
typedef Int32_t WordS32;
typedef Int64_t WordS64_t;
typedef Int64_t WordS64;

typedef Word8_t WordU8_t;
typedef Word8_t WordU8;
typedef Word16_t WordU16_t;
typedef Word16_t WordU16;
typedef Word32_t WordU32_t;
typedef Word32_t WordU32;
typedef Word64_t WordU64_t;
typedef Word64_t WordU64;

typedef WordU8_t Char8_t;
typedef WordU8_t Char8;
typedef WordU16_t Char16_t;
typedef WordU16_t Char16;
typedef WordU32_t Char32_t;
typedef WordU32_t Char32;

typedef Vector(Char8_t) String8_t;
typedef Vector(Char8_t) String8;
typedef Vector(Char16_t) String16_t;
typedef Vector(Char16_t) String16;
typedef Vector(Char32_t) String32_t;
typedef Vector(Char32_t) String32;

typedef Int32_t Bool_t;
typedef Int32_t Bool;
typedef String8_t NullString8_t;
typedef String8_t NullString8;

typedef void* CPointer;
typedef Pointer Objptr;
#endif /* _MLTON_MLTYPES_H_ */

/* Copyright (C) 1999-2007 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

#ifndef _MLTON_EXPORT_H_
#define _MLTON_EXPORT_H_

/* ------------------------------------------------- */
/*                      Symbols                      */
/* ------------------------------------------------- */

/* An external symbol is something not defined by the module
 * (executable or library) being built. Rather, it is provided
 * from a library dependency (dll, dylib, or shared object).
 *
 * A public symbol is defined in this module as being available
 * to users outside of this module. If building a library, this 
 * means the symbol will be part of the public interface.
 * 
 * A private symbol is defined within this module, but will not
 * be made available outside of it. This is typically used for
 * internal implementation details that should not be accessible.
 */

#if defined(_WIN32) || defined(_WIN64) || defined(__CYGWIN__)
#define EXTERNAL __declspec(dllimport)
#define PUBLIC   __declspec(dllexport)
#define PRIVATE
#else
#if __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 4)
#define EXTERNAL __attribute__((visibility("default")))
#define PUBLIC   __attribute__((visibility("default")))
#define PRIVATE  __attribute__((visibility("hidden")))
#else
#define EXTERNAL
#define PUBLIC
#define PRIVATE
#endif
#endif

#endif /* _MLTON_EXPORT_H_ */

#if !defined(PART_OF_CUSP) && \
    !defined(STATIC_LINK_CUSP) && \
    !defined(DYNAMIC_LINK_CUSP)
#define DYNAMIC_LINK_CUSP
#endif

#if defined(PART_OF_CUSP)
#define MLLIB_PRIVATE(x) PRIVATE x
#define MLLIB_PUBLIC(x) PUBLIC x
#elif defined(STATIC_LINK_CUSP)
#define MLLIB_PRIVATE(x)
#define MLLIB_PUBLIC(x) PUBLIC x
#elif defined(DYNAMIC_LINK_CUSP)
#define MLLIB_PRIVATE(x)
#define MLLIB_PUBLIC(x) EXTERNAL x
#else
#error Must specify linkage for cusp
#define MLLIB_PRIVATE(x)
#define MLLIB_PUBLIC(x)
#endif

#ifdef __cplusplus
extern "C" {
#endif

MLLIB_PUBLIC(void cusp_open(int argc, const char** argv);)
MLLIB_PUBLIC(void cusp_close();)
MLLIB_PUBLIC(void cusp_main ();)
MLLIB_PUBLIC(void cusp_main_sigint ();)
MLLIB_PUBLIC(Int32 cusp_main_running ();)
MLLIB_PUBLIC(void cusp_stop_main ();)
MLLIB_PUBLIC(void cusp_process_events ();)
MLLIB_PUBLIC(Int32 cusp_endpoint_new (Int32 x0, Int32 x1, Int32 x2, Word16 x3, Word16 x4);)
MLLIB_PUBLIC(Int32 cusp_endpoint_destroy (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_endpoint_when_safe_to_destroy (Int32 x0, CPointer x1, CPointer x2);)
MLLIB_PUBLIC(Int32 cusp_endpoint_set_rate (Int32 x0, Int32 x1);)
MLLIB_PUBLIC(Int32 cusp_endpoint_key (Int32 x0);)
MLLIB_PUBLIC(Objptr cusp_endpoint_publickey_str (Int32 x0, Word16 x1, CPointer x2);)
MLLIB_PUBLIC(Int64 cusp_endpoint_bytes_sent (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_endpoint_bytes_received (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_endpoint_contact (Int32 x0, Int32 x1, Word16 x2, CPointer x3, CPointer x4);)
MLLIB_PUBLIC(Int32 cusp_endpoint_hosts (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_endpoint_channels (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_endpoint_advertise (Int32 x0, Word16 x1, CPointer x2, CPointer x3);)
MLLIB_PUBLIC(Int32 cusp_endpoint_unadvertise (Int32 x0, Word16 x1);)
MLLIB_PUBLIC(Int32 cusp_endpoint_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_endpoint_free (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_address_from_string (Objptr x0);)
MLLIB_PUBLIC(Objptr cusp_address_to_string (Int32 x0, CPointer x1);)
MLLIB_PUBLIC(Int32 cusp_address_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_address_free (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_connect (Int32 x0, Word16 x1);)
MLLIB_PUBLIC(Word16 cusp_host_listen (Int32 x0, CPointer x1, CPointer x2);)
MLLIB_PUBLIC(Int32 cusp_host_unlisten (Int32 x0, Word16 x1);)
MLLIB_PUBLIC(Int32 cusp_host_key (Int32 x0);)
MLLIB_PUBLIC(Objptr cusp_host_key_str (Int32 x0, CPointer x1);)
MLLIB_PUBLIC(Int32 cusp_host_address (Int32 x0);)
MLLIB_PUBLIC(Objptr cusp_host_to_string (Int32 x0, CPointer x1);)
MLLIB_PUBLIC(Int32 cusp_host_instreams (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_outstreams (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_queued_out_of_order (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_queued_unread (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_queued_inflight (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_queued_to_retransmit (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_host_bytes_received (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_host_bytes_sent (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_host_last_receive (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_host_last_send (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_free (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_iterator_has_next (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_iterator_next (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_iterator_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_host_iterator_free (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_channel_iterator_has_next (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_channel_iterator_next (Int32 x0, CPointer x1);)
MLLIB_PUBLIC(Int32 cusp_channel_iterator_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_channel_iterator_free (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_instream_read (Int32 x0, Int32 x1, CPointer x2, CPointer x3);)
MLLIB_PUBLIC(Int32 cusp_instream_reset (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_instream_queued_out_of_order (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_instream_queued_unread (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_instream_bytes_received (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_instream_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_instream_free (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_instream_iterator_has_next (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_instream_iterator_next (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_instream_iterator_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_instream_iterator_free (Int32 x0);)
MLLIB_PUBLIC(Real32 cusp_outstream_get_priority (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_outstream_set_priority (Int32 x0, Real32 x1);)
MLLIB_PUBLIC(Int32 cusp_outstream_write (Int32 x0, CPointer x1, Int32 x2, CPointer x3, CPointer x4);)
MLLIB_PUBLIC(Int32 cusp_outstream_shutdown (Int32 x0, CPointer x1, CPointer x2);)
MLLIB_PUBLIC(Int32 cusp_outstream_reset (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_outstream_queued_inflight (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_outstream_queued_to_retransmit (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_outstream_bytes_sent (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_outstream_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_outstream_free (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_outstream_iterator_has_next (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_outstream_iterator_next (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_outstream_iterator_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_outstream_iterator_free (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_event_time ();)
MLLIB_PUBLIC(Int32 cusp_event_new (CPointer x0, CPointer x1);)
MLLIB_PUBLIC(Int32 cusp_event_schedule (Int64 x0, CPointer x1, CPointer x2);)
MLLIB_PUBLIC(Int32 cusp_event_schedule_in (Int64 x0, CPointer x1, CPointer x2);)
MLLIB_PUBLIC(Int32 cusp_event_reschedule (Int32 x0, Int64 x1);)
MLLIB_PUBLIC(Int32 cusp_event_reschedule_in (Int32 x0, Int64 x1);)
MLLIB_PUBLIC(Int32 cusp_event_cancel (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_event_time_of_execution (Int32 x0);)
MLLIB_PUBLIC(Int64 cusp_event_time_till_execution (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_event_is_scheduled (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_event_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_event_free (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_abortable_abort (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_abortable_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_abortable_free (Int32 x0);)
MLLIB_PUBLIC(Word16 cusp_suiteset_publickey_all ();)
MLLIB_PUBLIC(Word16 cusp_suiteset_publickey_defaults ();)
MLLIB_PUBLIC(Word16 cusp_suiteset_publickey_cheapest (Word16 x0);)
MLLIB_PUBLIC(Word16 cusp_suiteset_symmetric_all ();)
MLLIB_PUBLIC(Word16 cusp_suiteset_symmetric_defaults ();)
MLLIB_PUBLIC(Word16 cusp_suiteset_symmetric_cheapest (Word16 x0);)
MLLIB_PUBLIC(Objptr cusp_suite_publickey_name (Word16 x0, CPointer x1);)
MLLIB_PUBLIC(Real32 cusp_suite_publickey_cost (Word16 x0);)
MLLIB_PUBLIC(Objptr cusp_suite_symmetric_name (Word16 x0, CPointer x1);)
MLLIB_PUBLIC(Real32 cusp_suite_symmetric_cost (Word16 x0);)
MLLIB_PUBLIC(Objptr cusp_publickey_to_string (Int32 x0, CPointer x1);)
MLLIB_PUBLIC(Word16 cusp_publickey_suite (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_publickey_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_publickey_free (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_privatekey_new ();)
MLLIB_PUBLIC(Objptr cusp_privatekey_save (Int32 x0, Objptr x1, CPointer x2);)
MLLIB_PUBLIC(Int32 cusp_privatekey_load (Objptr x0, Objptr x1);)
MLLIB_PUBLIC(Int32 cusp_privatekey_pubkey (Int32 x0, Word16 x1);)
MLLIB_PUBLIC(Int32 cusp_privatekey_dup (Int32 x0);)
MLLIB_PUBLIC(Int32 cusp_privatekey_free (Int32 x0);)

#undef MLLIB_PRIVATE
#undef MLLIB_PUBLIC

#ifdef __cplusplus
}
#endif

#endif /* __CUSP_ML_H__ */
