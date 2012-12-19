#include <signal.h>
#include <stdint.h>
#include <string.h>

/* Use a fixed-width type for portable FFI */
typedef uint32_t bs_sig_t;

#ifdef __MINGW32__

typedef void __cdecl (*sig_handler)(int);
static bs_sig_t ready = 0;
static sig_handler old[32];

static void __cdecl bs_signalled(int signum) {
  ready |= 1 << signum;
  signal(signum, &bs_signalled);
}

void bs_sigpoll(bs_sig_t signum) {
  old[signum] = signal((int)signum, bs_signalled);
}
void bs_sigunpoll(bs_sig_t signum) {
  signal((int)signum, old[signum]);
}
bs_sig_t bs_sigready(bs_sig_t signum) {
  bs_sig_t out = (ready & (1 << signum));
  ready &= ~(1 << signum);
  return out;
}

#else

static sigset_t ready;
static struct sigaction old[NSIG];

static void bs_signalled(int signum) {
  sigaddset(&ready, signum);
}

void bs_sigpoll(bs_sig_t signum) {
  struct sigaction sa;
  memset(&sa, 0, sizeof(sa));
#if defined(SA_ONSTACK)
  sa.sa_flags = SA_ONSTACK;
#endif
  sa.sa_handler = bs_signalled;
  sigaction((int)signum, &sa, old+signum);
}
void bs_sigunpoll(bs_sig_t signum) {
  sigaction((int)signum, old+signum, 0);
}
bs_sig_t bs_sigready(bs_sig_t signum) {
  int out = sigismember(&ready, (int)signum);
  sigdelset(&ready, signum);
  return (bs_sig_t)out;
}

#endif
