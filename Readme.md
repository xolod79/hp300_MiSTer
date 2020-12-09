# HP9000/300 core for MiSTer

## General description

This implements a basic HP9000/300 core for Mister. It uses a 68030 CPU (W68K30L cpu core) and emulates a HP 98544A graphics card with 1024x768 resolution. It lacks
an MMU so you cannot use it to run HP-UX. HP BASIC booting from ROM is working.

It's lacking I/O (means a GPIB or SCSI controller), so no communication with external devices is possible.

