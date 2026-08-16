# seiscomp-scqc

![CI](https://github.com/platformfuzz/seiscomp-scqc/actions/workflows/ci.yml/badge.svg)
![Build and Release](https://github.com/platformfuzz/seiscomp-scqc/actions/workflows/build-and-release.yml/badge.svg)

Unofficial SeisComP scqc image built with public gsm. Not gempa-supported.

The process computes waveform quality control.

**Package:** [ghcr.io/platformfuzz/seiscomp-scqc](https://github.com/platformfuzz/seiscomp-scqc/pkgs/container/seiscomp-scqc)

## Run

```bash
docker pull ghcr.io/platformfuzz/seiscomp-scqc:latest
docker run --rm ghcr.io/platformfuzz/seiscomp-scqc:latest
```

`SCMASTER_HOST`, `SEEDLINK_HOST`, and `DB_HOST` can be overridden at run time.

## Build

```bash
docker build -t seiscomp-scqc:test .
docker run --rm seiscomp-scqc:test
```
