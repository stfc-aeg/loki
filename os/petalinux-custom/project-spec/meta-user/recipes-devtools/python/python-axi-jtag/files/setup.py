from setuptools import setup, find_packages

setup(
    name="axi_jtag",
    version="1.0.0",
    packages=find_packages(),
    desription="UIO drivers for JTAG registers",
    author="Callum Lee",
    author_email="callum.lee@stfc.ac.uk",
    python_requires=">=3.7"
)