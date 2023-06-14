# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
import sys

# Insert the control adapter path
sys.path.insert(0, os.path.abspath('../../control/loki'))

# Mocking modules:
# Because sphyinx auto-generated documentation actually imports the modules,
# it technically has to be able to import all of the dependencies too. To avoid
# this, I will mock them. This does mean that 'mock' is needed.
import unittest.mock as mock
MOCKED_MODULES = [
    'tornado',
    'tornado.ioloop',
    'odin',
    'odin.adapters',
    'odin.adapters.async_adapter',
    'odin.adapters.parameter_tree',
    'odin_devices',
    'odin_devices.max5306',
    'odin_devices.ltc2986',
    'odin_devices.bme280',
    'odin_devices.si534x',
    'odin_devices.pac1921',
    'odin_devices.firefly',
    'odin_devices.i2c_device',
    'gpiod',
]
for mod_name in MOCKED_MODULES:
    sys.modules[mod_name] = mock.MagicMock()

# -- Project information -----------------------------------------------------

project = 'LOKI'
copyright = '2023, Joseph Nobes'
author = 'Joseph Nobes'


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary'
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'alabaster'

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']
