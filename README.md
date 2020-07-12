[//]: # ( vim:set syntax=markdown fileformat=unix shiftwidth=4 softtabstop=4 expandtab textwidth=120: )
[//]: # ( kate: syntax markdown; end-of-line unix; space-indent on; indent-width 4; word-wrap-column 120; )
[//]: # ( kate: word-wrap on; remove-trailing-space on; )

# Deploying large software stacks on HPC clusters using Gentoo Prefix

This project is about how to build and run your own software stack on HPC clusters easily and rapidly with the help of
[Gentoo Linux](https://www.gentoo.org/) and the [Gentoo Prefix](https://wiki.gentoo.org/wiki/Project:Prefix) project.

:warning:
**NOTE:**
The step-by-step guide listed below is work-in-progress! In its current state it resembles more of a personal sketchpad
than a complete guide, it is still missing important steps as I did not have the time to edit them properly and hence
it is not ready for a broad audience yet!
:warning:

**NOTE:** Please, feel free to [open issues](https://github.com/JM1/hbrs-mpl/issues) if you encounter bugs or problems!

## Background

**NOTE:** You might skip to the next paragraph as this is about me and my research only.

I am doing research on generic programming methodology. The ultimate goal is to provide non-HPC-experts and scientists
from other domains, such as math, physics and fluid dynamics, a set of reusable and efficient software components. These
components are declared using domain-specific terms and constraints only without leaking implementation details. E.g.
for linear algebra we define matrices, associated operations like the singular value decomposition and pre- and post-
conditions. We do not make assumptions about e.g. memory layout or memory allocation. These hard-to-get-right details
are handled on lower layers hidden from application developers. Scientists can freely compose these components (and
extend them if necessary) to build parallel, distributed and high performance applications for HPC clusters. They can
focus on their primary research topics again instead of having to get a programming veteran with decent Fortran, MPI
and C skills.

Part of my research involves the development, maintenance and deployment of a growing C++ and Python code base (e.g.
[`hbrs-mpl`](https://github.com/jm1/hbrs-mpl/) and [`hbrs-theta_utils`](https://github.com/JM1/hbrs-theta_utils/)) and
many related tools (e.g. [TAU (and THETA)](http://tau.dlr.de/), [ParaView](https://www.paraview.org/)) and libraries
(e.g. [Boost.Hana](https://github.com/boostorg/hana), [Elemental](https://github.com/elemental/Elemental),
[OpenMPI](https://www.open-mpi.org/), [Visualization Toolkit (VTK)](https://vtk.org/)).

## Motivation

Deploying large software stacks like ours on a HPC cluster takes a considerably amount of time and effort. You have to
download, configure, build and install dozens (hundreds?) of libraries and applications in the correct order, while
trying to satisfy all their dependencies. Some you will identify preliminarily, others you will discover during
the deployment process. You better get a package manager like [apt](https://en.wikipedia.org/wiki/APT_(software)) or
[yum](https://en.wikipedia.org/wiki/Yum_(software))/[dnf](https://en.wikipedia.org/wiki/DNF_(software)) to do this for
you. Unfortunately, you cannot.

On HPC clusters, usually you do not have root/`su`/`sudo` rights to use the OS package manager. But this would not help
anyway because major cluster operating systems, such as [Scientific Linux](https://scientificlinux.org/), probably do
not have the latest or any specific software revision installed that you would like to or have to use. Especially
experimental (and) scientific libraries are often not available from the package repositories at all, examples are
[Elemental](https://github.com/elemental/Elemental) and [libflame](https://github.com/flame/libflame). Other
users might want to use different versions of the same libraries and tools, which is only partly (libraries only)
supported by package managers. Partial workarounds for different software stacks exist, e.g. [Environment
Modules](https://modules.readthedocs.io/en/latest/), but they do not lift the burden of the manual build process and
dependency management.

Containers or virtualization are often not available on HPC clusters, one reason is they require privileged access
regular users do not have. Or they are no feasible alternative to native hardware access because of their negative
impact on performance and latency and their increased memory usage.

## Solution: Gentoo Prefix and HPC clusters

Our [HPC cluster at Bonn-Rhein-Sieg University](https://wr0.wr.inf.h-brs.de/wr/usage.html) runs `Scientific Linux
release 7.8 (Nitrogen)`, does not provide containers or virtualization and lacks most software of our stack listed
above. Using the OS package manager `yum` is not possible due to insufficient permissions. Manually deploying the whole
software stack is best to be avoided due to the amount of work involved. What to do?

[Gentoo Prefix](https://wiki.gentoo.org/wiki/Project:Prefix) comes to the rescue!

**NOTE:** If it is possible to use containers or virtual machines, then deeply think before deciding on Gentoo Prefix!

> To bring out the virtues of Gentoo Linux on different operating systems, the Gentoo Prefix project develops and
> maintains a way of installing Gentoo systems in a non-standard location, designated by a "prefix".
>
> Usually, Gentoo Linux's package manager (portage) installs in the root of the filesystem hierarchy known as /. On
> systems other than Gentoo Linux, this usually results in problems, due to conflicts of software packages, unless the
> OS is adapted like Gentoo FreeBSD. Instead, Gentoo Prefix installs within an offset, known as a prefix, allowing
> users to install Gentoo in another location in the filesystem hierarchy, hence avoiding conflicts. Next to this
> offset, Gentoo Prefix runs unprivileged, meaning no root user or rights are required to use it.
>
> By using an offset (the "prefix" location), it is possible for many "alternative" user groups to benefit from a large
> part of the packages in the Gentoo Linux Portage tree. Currently users of the following systems successfully run
> Gentoo Prefix: Mac OS X on Intel, Linux on x86, x86_64 and arm, Solaris 10 on Sparc, Sparc/64, x86 and x86_64, AIX on
> PPC, Windows on x86 and x86_64. Other platforms have been successfully used in the past.

The Gentoo Prefix project allows users to install [Gentoo Linux](https://www.gentoo.org/), [a complete Linux
distribution](https://en.wikipedia.org/wiki/Gentoo_Linux), quickly and without privileged (root/`su`/`sudo`) rights
to their home directories or any other writeable directory on HPC clusters. It enables you to run Gentoo Linux
natively from within Scientific Linux without any containers or virtualization. Hence, installing ParaView on our HPC
cluster boils down to `emerge sci-visualization/paraview` and then Gentoo Linux will fetch, compile and install dozens
of required libraries and tools automatically.

Actually, the only software used from the host operating system are its kernel, ssh server, bash for user login and
slurmd. The latter, slurmd, is a job system that is required to distribute e.g. MPI applications across all cluster
nodes. Everything else is from Gentoo Linux. Hence it should be straight forward to apply this guide to other HPC
clusters as well. No other Linux distribution (i am aware of) supports this. One reason is, that unlike binary software
distributions such as Debian, Ubuntu, Red Hat Enterprise Linux / CentOS or SUSE Linux Enterprise Server, with Gentoo
Linux (most) source code is compiled locally.

[Gentoo's package repositories](https://packages.gentoo.org/) provide a large collection of software that can be
installed easily using Gentoo's package manager [`Portage`](https://en.wikipedia.org/wiki/Portage_(software)). The
[Gentoo Science Project](https://wiki.gentoo.org/wiki/Project:Science/Overlay) maintains many packages for scientific
and high performance clustering applications. To get new software running on Gentoo, which is not yet available in any
package repository, either build and install it manually or better [write an `ebuild`
file](https://wiki.gentoo.org/wiki/Ebuild) and let `Portage` handle the process.

> An `ebuild` file is a text file, used by Gentoo package managers, which identifies a specific software package and
> how the Gentoo package manager should handle it. It uses a bash-like syntax style and is standardized through the
> EAPI version.

Writing `ebuild` files is well documented in e.g. [Quickstart Ebuild Guide](https://devmanual.gentoo.org/quickstart/)
or [Basic guide to write Gentoo Ebuilds](https://wiki.gentoo.org/wiki/Basic_guide_to_write_Gentoo_Ebuilds), and requires
less effort than developing e.g. `deb` packages for apt-based distributions or `rpm` packages for yum-/dnf-based
distributions. Along with the guide you will find several `ebuild` files for packages that are not available in Gentoo
Linux, such as [Elemental](https://github.com/elemental/Elemental), [libflame](https://github.com/flame/libflame),
[`hbrs-mpl`](https://github.com/jm1/hbrs-mpl/) and [`hbrs-theta_utils`](https://github.com/JM1/hbrs-theta_utils/))

Since the user's setup of Gentoo Linux is highly decoupled from the host operating system, changes to the cluster like
software updates or OS upgrades do not alter the Gentoo Prefix environment. Backup and restore of the environment is
reduced to a plain `tar` of the Gentoo Linux install directory. Hence, the Gentoo Prefix project helps to maintain a
consistent environment on HPC clusters, which otherwise is hard, because e.g. backups of the cluster operating system
is not feasible for regular users in most cases.

Using Gentoo Linux has downsides. First, it is probably faster and easier to setup a container or virtual machine than
installing Gentoo Linux. If you can use those, think twice before choosing Gentoo Prefix. Not all packages from the
official Gentoo reporitories are compatible to Gentoo Prefix out of the box. System integrity is not at risk, because
Gentoo will raise an error before an incompatible package tries to write to non-prefix directories. Most often it is
sufficient to patch the `ebuild` file of broken packages, which is done easily due to Gentoo's source distribution
model. When packages get updated upstream, those patches probably have to be refreshed, so better submit your prefix
patches to Gentoo asap. The biggest issue is software outside of Gentoo Prefix. Depending on the actual software, it
might be difficult to compile and link against code or use software of the host OS. The host OS provides its own set of
e.g. compilers, libraries, environment variables, pkg-config and CMake configurations. Incompatibilities between both
software stacks will cause compilation bugs at best or silently introduce undetected runtime bugs at worst. Please note,
this problem is not specific to Gentoo Prefix but can happen as soon as you use two different C++ compilers for separate
code parts. For example, the Visualization Toolkit (VTK) from Gentoo's package repository failed to compile, because its
CMake-based build scripts erroneously picked up Qt5 headers and CMake exports from the host OS. This has been fixed by
providing a global `CMakeLists.txt`, which excludes paths from outside the Gentoo Prefix installation. You will find
this CMake configuration and all necessary patches for Gentoo along with this project.

Pros:
+ quick setup compared to manual source code deployment
+ simple and powerful package management system `Portage` handles package dependencies, their build and install process
+ no privileged permissions, no root, `su` or `sudo` rights required
+ minimal requirements and dependencies on host operation system and preexisting software:
  kernel, ssh server, bash for user logins and slurmd for job scheduling.
+ native, no performance degredation due to containers or virtualization
+ many packages available in Gentoo's package repositories, also for scientific and HPC software
+ easily extendable package system using bash-like `ebuild` text files
+ consistent environment across host OS changes like software updates or system upgrades
+ simple backup and restore compared to host OS backups

Cons:
- harder than containers or virtual machines, in case those are viable options for you, think twice on Gentoo Prefix
- not all official Gentoo packages are compatible to Gentoo Prefix and require patches
- using software from outside the Gentoo Prefix installation, e.g. from the host OS, is difficult

## Step-by-step guide

File [`INSTALL`](https://github.com/JM1/gentoo-linux-on-hpc-clusters/blob/master/INSTALL) describes how to setup Gentoo
Prefix at an HPC cluster properly, using the example of our university's cluster [`wr0.wr.inf.h-brs.de`](
https://wr0.wr.inf.h-brs.de/). [`USAGE`](https://github.com/JM1/gentoo-linux-on-hpc-clusters/blob/master/USAGE) shows
how to interact with Gentoo Linux while being logged into the HPC cluster, how to run applications from within the
Gentoo Prefix environment and how to schedule jobs with the host OS scheduler.

## License

GNU General Public License v3.0 or later

See [LICENCE.md](https://github.com/JM1/gentoo-linux-on-hpc-clusters/blob/master/LICENSE.md) to see the full text.

## Author

Jakob Meng
@jm1 ([github](https://github.com/jm1), [web](http://www.jakobmeng.de))
