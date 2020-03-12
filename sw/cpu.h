
// Interrupt bits
#define TIMER_IRQ (1 << 0)
#define EBREAK_IRQ (1 << 1)
#define BUS_ERROR_IRQ (1 << 2)
#define IRQ_3 (1 << 3)
#define IRQ_4 (1 << 4)
#define IRQ_5 (1 << 5)

// Replace IRQ mask with new_mask
//  An interrupt is masked if its bit is high
//  The original mask is returned in old_mask
#define picorv32_maskirq(old_mask, new_mask) \
    __asm__ __volatile__ (".insn r 11, 6, 3, %0, %1, zero\n" : "=r" (old_mask) : "r" (new_mask))

// Replace timer counter with new_count
// The original counter is returned in old_count
// A count of zero means disable timer
// An interrupt is generated when the timer transitions from 1 to 0.
#define picorv32_timer(old_count, new_count) \
    __asm__ __volatile__ (".insn r 11, 6, 5, %0, %1, zero\n" : "=r" (old_count) : "r" (new_count))

// Wait for an interrupt
// When an interrupt occurs, the bit-list of pending interrupts is returned in pending
#define picorv32_waitirq(pending) \
    __asm__ __volatile__ (".insn r 11, 4, 4, %0, 0, 0\n" : "=r" (pending))
