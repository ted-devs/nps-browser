cmake_minimum_required(VERSION 3.10.2)

project("pkg2zip")

add_library(pkg2zip SHARED
    pkg2zip_src/pkg2zip.c
    pkg2zip_src/pkg2zip_aes.c
    pkg2zip_src/pkg2zip_crc32.c
    pkg2zip_src/pkg2zip_out.c
    pkg2zip_src/pkg2zip_psp.c
    pkg2zip_src/pkg2zip_sys.c
    pkg2zip_src/pkg2zip_zip.c
    pkg2zip_src/pkg2zip_zrif.c
    pkg2zip_src/miniz_tdef.c
    pkg2zip_src/puff.c
)

target_compile_options(pkg2zip PRIVATE -std=c99 -Wall -Wextra -DNDEBUG -D_GNU_SOURCE -O2)
target_link_libraries(pkg2zip log)
