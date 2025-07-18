# CVMFS Kernel Regression Tester

This repository helps test CVMFS client read functionality across different Linux kernel versions using a lightweight VM environment powered by `virtme-ng`.

The test is designed to work with `git bisect` to identify kernel regressions that affect the ability of a CVMFS client to read files.

---

## Features

- Automates kernel build and test execution in a virtualized environment
- Uses a static test binary to read a large file from a CVMFS repository
- Supports `git bisect run` for kernel regression tracking

---

## Prerequisites

Install these on the host system
(Recommended installation method is building from source):

1. [Linux kernel source](git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git)
2. [virtme-ng](https://github.com/arighi/virtme-ng)
3. [qemu](https://www.qemu.org/download/) - user net support is required

## Setup

Note: Skip to step 3 if host is not already configured to read from the repository

1. Create a `config.sh` from config_tempelate and set the values of the repository to read from

2. Setup CVMFS client - one time setup on host
```bash
sudo ./setup_cvmfs_client.sh
```

3. Clone the linux source on the host machine

4. Update the `KERNEL_DIR` variable inside `build_and_test.sh` script to point to the location of kernel source

5. Build and run test

    a. Manually
    ```bash
    ./build_and_test.sh
    ```
    This will:
    - Build the kernel (bzImage)
    - Compile a static test binary from test.c
    - Boot the kernel in a virtme-ng VM using the rootfs
    - Run the test, which opens and reads a file from /cvmfs/...

    b. Using `git bisect`
    To find the first bad kernel commit cd into the kernel source repository:
    ```bash
    cd linux
    git bisect start
    git bisect bad <bad-commit-or-tag> (e.g. v5.15)
    git bisect good <good-commit-or-tag> (e.g. v5.10)
    git bisect run /absoulte_path_to/build_and_test.sh
    ```
    This will automatically build and boot each kernel version, and use the exit code of the test binary to determine success or failure.