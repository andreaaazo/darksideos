# Shared cross-vendor CPU hardening baseline.
# Contains settings that apply equally to Intel and AMD modules.
{
  # Boot namespace for cross-vendor CPU hardening parameters.
  boot = {
    # Shared kernel command-line hardening flags for Intel and AMD.
    kernelParams = [
      # Enforce strict IOMMU TLB invalidation for stronger DMA isolation guarantees.
      "iommu.strict=1"
      # Mitigate Speculative Store Bypass side-channel attacks.
      "spec_store_bypass_disable=on"
      # Disable SLAB allocator object merging to reduce cross-cache attack surface.
      "slab_nomerge"
      # Randomize page allocator freelists to harden heap layout prediction.
      "page_alloc.shuffle=1"
      # Randomize kernel stack offset on syscall entry to reduce ROP reliability.
      "randomize_kstack_offset=on"
    ];

    # Kernel runtime hardening sysctl knobs shared across CPU vendors.
    kernel.sysctl = {
      # Hide kernel pointer values from unprivileged userspace.
      "kernel.kptr_restrict" = 2;
      # Restrict access to kernel ring buffer to privileged users.
      "kernel.dmesg_restrict" = 1;
      # Disable unprivileged eBPF usage.
      "kernel.unprivileged_bpf_disabled" = 1;
      # Keep full userspace ASLR enabled.
      "kernel.randomize_va_space" = 2;
      # Restrict ptrace to parent/child or CAP_SYS_PTRACE processes.
      "kernel.yama.ptrace_scope" = 2;
      # Restrict perf events to highly privileged contexts.
      "kernel.perf_event_paranoid" = 3;
      # Disable loading new kernels via kexec at runtime.
      "kernel.kexec_load_disabled" = 1;
      # Disable unprivileged userfaultfd to reduce exploit primitives.
      "vm.unprivileged_userfaultfd" = 0;
      # Protect against symlink-based TOCTOU attacks in sticky world-writable dirs.
      "fs.protected_symlinks" = 1;
      # Protect against hardlink-based privilege escalation patterns.
      "fs.protected_hardlinks" = 1;
      # Harden FIFO handling in sticky directories.
      "fs.protected_fifos" = 2;
      # Harden regular file handling in sticky directories.
      "fs.protected_regular" = 2;
    };
  };
}
