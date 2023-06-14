.. LOKI documentation master file, created by
   sphinx-quickstart on Fri Jun  2 15:06:42 2023.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to LOKI's documentation!
================================

.. note::
    This project is under active development.

This is the documentation for the LOKI control system repository, a toolflow for producing Yocto-based embedded system images for the LOKI series of control hardware.
This hardware hosts variants of the Trenz TE080x SoM, a series of mezzanine boards based on the Zynq UltraScale+ MPSoC.

The image provides:

* A PetaLinux-based operating system sandbox on which to build
* odin-control and related packages (odin-devices, odin-sequencer) to allow for fast and modular development of control planes.
* A base odin-control adapter class that will present an API for on-carrier application support peripherals, including:

  * GPIO
  * Clock Generation
  * DAC
  * Temperature Monitoring

This repository provides a framework of components that allow an application to:

* Inject custom firmware into the the PL Layer
* Redefine generic application pins as required
* Inject custom Yocto layers for application software
* Construct an application odin-control instance


.. toctree::
   :maxdepth: 2
   :caption: Contents:

Repository Structure
====================
control: carrier adapter base class, and helper python classes
design: firmware
docs: this documentation
os: petalinux os (Yocto)
share: autoconf share


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

Full API
========

.. autosummary::
    :toctree: generated

    adapter

.. autoclass:: adapter.LokiCarrier_TEBF0808_MERCURY
    :members:
    :undoc-members:
    :inherited-members:
