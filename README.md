Visual tracking algorithms in Matlab
====================================

This repository contains Matlab code for several visual trackers. As you
might imagine the code is mostly used for academic and research purposes,
to facilitate experiment repeatability and extensions.

Release log (major changes)
---------------------------

 * 23-02-2016 - Initial public release, [ANT](ant/README.md) and [LGT](lgt/README.md) trackers
 * 28-10-2016 - Adding adapted original implementation of the [IVT](ivt/README.md) tracker
 * 03-11-2016 - Adding adapted original implementation of the [MEEM](meem/README.md) and [L1-APG](l1apg/README.md) trackers as well as some fixes

Citing and license
------------------

Instructions on citing the code in research publicatons are available in subfolders
of individual trackers. Other than that the code is available under BSD license unless
stated otherwise in the file (some files are imported from other projects).

Reporting problems and contact
------------------------------

If you notice a bug please open an [issue on Github](https://github.com/lukacu/visual-tracking-matlab/issues).
If you have any other questions or problems contact me via email.

Compiling and running
=====================

Disclaimer: the code was developed and tested on Linux-based systems.

You will need need OpenCV installed (at the moment it works with version 3.1,
but also with version 2.4 with some minor modifications) and the
[mexopencv](https://github.com/kyamagu/mexopencv) bindings for Matlab compiled and
added to Matlab path. The code was tested with Matlab versions 2015a. It probably
does not work in Octave, but could perhaps be adapted to do so.

First run the compile_native script in Matlab to compile the native
components. If everything works correctly you should now have compiled
Mex files available for your platform.

You can run trackers by using `run_*` wrappers available in the root directory
as an example. The scripts accept one argument, a path to a [VOT](http://votchallenge.net/)-compatible
sequence directory.

TraX protocol and VOT toolkit
-----------------------------

To run the trackers in the VOT toolkit you can use the TraX wrapper that is
supplied in the repository. You will need traxserver (part of the [TraX reference
implementation](https://github.com/votchallenge/trax)) Mex file visible in the
Matlab path. The TraX mode can be accessed by running the `run_*` wrappers without
the sequence path argument.

