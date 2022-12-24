NRF5_SDK	= $(nativeBuildInputs)/share/nRF5_SDK
NRF5_LIBS	= delay util
NRF5_MODS       = nrfx

NRF_IC		= nrf52840
CPPFLAGS        += -DNRF52840_XXAA

CPPFLAGS	+= -I$(NRF5_SDK)/config/$(NRF_IC)/config \
		   $(addprefix -I$(NRF5_SDK)/components/libraries/,$(NRF5_LIBS)) \
		   -I$(NRF5_SDK)/modules/nrfx \
		   -I$(NRF5_SDK)/modules/nrfx/mdk \
		   -I$(NRF5_SDK)/integration/nrfx \
		   -I$(NRF5_SDK)/components/toolchain/cmsis/include

