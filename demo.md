# Demo script (3-4 minutes)

Run this once on Daint before the talk.
Check that the label `prgenv-gnu/26.3:v1` exists (`uenv image find prgenv-gnu`), and replace it everywhere below if it does not.
Paste the real `readelf` output into the "What the cray-mpich package does at install time" slide.

## 1. Find and pull

```bash
uenv image find prgenv-gnu
uenv image pull prgenv-gnu/26.3:v1
uenv image inspect prgenv-gnu/26.3:v1
```

Point out:
- the label `name/version:tag@system%uarch`
- `inspect` reads `meta/env.json` next to the image, without mounting it

## 2. Mount namespace

```bash
readlink /proc/self/ns/mnt        # login shell: note the inode
uenv start prgenv-gnu/26.3:v1 --view=default
readlink /proc/self/ns/mnt        # a different inode
grep user-environment /proc/self/mountinfo
env | grep ^UENV_
```

Point out:
- the mount is `ro,nosuid,nodev`, type `squashfs`, on a `/dev/loopN`
- in a second terminal on the same login node, `/user-environment` is empty
- `UENV_MOUNT_LIST` and `UENV_VIEW` record what is mounted. Slurm uses them.

## 3. How cray-mpich was installed

```bash
mpicc -show
readelf -d $(dirname $(which mpicc))/../lib/libmpi.so | grep -E 'NEEDED|RPATH|RUNPATH'
```

Point out:
- `mpicc -show`: the gcc path from the uenv, and `-lmpi_gtl_cuda` with an rpath (from `@@GTL_LIBRARY@@`)
- `NEEDED` entries added by the Spack package: `libxpmem.so`, `libpmi*.so`, `libmpi_gtl_cuda.so`
- `RPATH` points into `/user-environment/linux-*/...`, including the Spack-built libfabric

```bash
exit
```

## 4. Slurm

```bash
srun -N2 -n8 --uenv=prgenv-gnu/26.3:v1 \
    bash -c 'echo $(hostname) $(readlink /proc/self/ns/mnt)'
```

Point out:
- one mount namespace per node, shared by all ranks on that node
- the mount happened in slurmstepd before the tasks forked

Optional, if there is time:

```bash
uenv start prgenv-gnu/26.3:v1 --view=default
srun -N1 -n2 bash -c 'echo $UENV_VIEW; ls /user-environment | head -3'
exit
```

This shows that `srun` from inside a `uenv start` session forwards the uenv to the compute nodes.
