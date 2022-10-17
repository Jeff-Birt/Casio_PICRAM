#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Include project Makefile
ifeq "${IGNORE_LOCAL}" "TRUE"
# do not include local makefile. User is passing all local related variables already
else
include Makefile
# Include makefile containing local settings
ifeq "$(wildcard nbproject/Makefile-local-default.mk)" "nbproject/Makefile-local-default.mk"
include nbproject/Makefile-local-default.mk
endif
endif

# Environment
MKDIR=gnumkdir -p
RM=rm -f 
MV=mv 
CP=cp 

# Macros
CND_CONF=default
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
IMAGE_TYPE=debug
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/Casio_PICRAM.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
else
IMAGE_TYPE=production
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=dist/${CND_CONF}/${IMAGE_TYPE}/Casio_PICRAM.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
endif

ifeq ($(COMPARE_BUILD), true)
COMPARISON_BUILD=
else
COMPARISON_BUILD=
endif

ifdef SUB_IMAGE_ADDRESS

else
SUB_IMAGE_ADDRESS_COMMAND=
endif

# Object Directory
OBJECTDIR=build/${CND_CONF}/${IMAGE_TYPE}

# Distribution Directory
DISTDIR=dist/${CND_CONF}/${IMAGE_TYPE}

# Source Files Quoted if spaced
SOURCEFILES_QUOTED_IF_SPACED=Helper_Functions.s ConfigClkPmd.s ConfigCWG1.s ConfigPins.s ConfigPWM6.s ConfigTMR2.s Main.s PinTwiddling.s ConfigIOC.s ConfigUART.s Casio_Com_Macros.s Helper_Macros.s UART_Com.s Casio_Com.s

# Object Files Quoted if spaced
OBJECTFILES_QUOTED_IF_SPACED=${OBJECTDIR}/Helper_Functions.o ${OBJECTDIR}/ConfigClkPmd.o ${OBJECTDIR}/ConfigCWG1.o ${OBJECTDIR}/ConfigPins.o ${OBJECTDIR}/ConfigPWM6.o ${OBJECTDIR}/ConfigTMR2.o ${OBJECTDIR}/Main.o ${OBJECTDIR}/PinTwiddling.o ${OBJECTDIR}/ConfigIOC.o ${OBJECTDIR}/ConfigUART.o ${OBJECTDIR}/Casio_Com_Macros.o ${OBJECTDIR}/Helper_Macros.o ${OBJECTDIR}/UART_Com.o ${OBJECTDIR}/Casio_Com.o
POSSIBLE_DEPFILES=${OBJECTDIR}/Helper_Functions.o.d ${OBJECTDIR}/ConfigClkPmd.o.d ${OBJECTDIR}/ConfigCWG1.o.d ${OBJECTDIR}/ConfigPins.o.d ${OBJECTDIR}/ConfigPWM6.o.d ${OBJECTDIR}/ConfigTMR2.o.d ${OBJECTDIR}/Main.o.d ${OBJECTDIR}/PinTwiddling.o.d ${OBJECTDIR}/ConfigIOC.o.d ${OBJECTDIR}/ConfigUART.o.d ${OBJECTDIR}/Casio_Com_Macros.o.d ${OBJECTDIR}/Helper_Macros.o.d ${OBJECTDIR}/UART_Com.o.d ${OBJECTDIR}/Casio_Com.o.d

# Object Files
OBJECTFILES=${OBJECTDIR}/Helper_Functions.o ${OBJECTDIR}/ConfigClkPmd.o ${OBJECTDIR}/ConfigCWG1.o ${OBJECTDIR}/ConfigPins.o ${OBJECTDIR}/ConfigPWM6.o ${OBJECTDIR}/ConfigTMR2.o ${OBJECTDIR}/Main.o ${OBJECTDIR}/PinTwiddling.o ${OBJECTDIR}/ConfigIOC.o ${OBJECTDIR}/ConfigUART.o ${OBJECTDIR}/Casio_Com_Macros.o ${OBJECTDIR}/Helper_Macros.o ${OBJECTDIR}/UART_Com.o ${OBJECTDIR}/Casio_Com.o

# Source Files
SOURCEFILES=Helper_Functions.s ConfigClkPmd.s ConfigCWG1.s ConfigPins.s ConfigPWM6.s ConfigTMR2.s Main.s PinTwiddling.s ConfigIOC.s ConfigUART.s Casio_Com_Macros.s Helper_Macros.s UART_Com.s Casio_Com.s



CFLAGS=
ASFLAGS=
LDLIBSOPTIONS=

############# Tool locations ##########################################
# If you copy a project from one host to another, the path where the  #
# compiler is installed may be different.                             #
# If you open this project with MPLAB X in the new host, this         #
# makefile will be regenerated and the paths will be corrected.       #
#######################################################################
# fixDeps replaces a bunch of sed/cat/printf statements that slow down the build
FIXDEPS=fixDeps

.build-conf:  ${BUILD_SUBPROJECTS}
ifneq ($(INFORMATION_MESSAGE), )
	@echo $(INFORMATION_MESSAGE)
endif
	${MAKE}  -f nbproject/Makefile-default.mk dist/${CND_CONF}/${IMAGE_TYPE}/Casio_PICRAM.${IMAGE_TYPE}.${OUTPUT_SUFFIX}

MP_PROCESSOR_OPTION=PIC16F18446
# ------------------------------------------------------------------------------------
# Rules for buildStep: pic-as-assembler
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/Helper_Functions.o: Helper_Functions.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Helper_Functions.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Helper_Functions.o \
	Helper_Functions.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigClkPmd.o: ConfigClkPmd.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigClkPmd.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigClkPmd.o \
	ConfigClkPmd.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigCWG1.o: ConfigCWG1.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigCWG1.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigCWG1.o \
	ConfigCWG1.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigPins.o: ConfigPins.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigPins.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigPins.o \
	ConfigPins.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigPWM6.o: ConfigPWM6.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigPWM6.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigPWM6.o \
	ConfigPWM6.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigTMR2.o: ConfigTMR2.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigTMR2.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigTMR2.o \
	ConfigTMR2.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/Main.o: Main.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Main.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Main.o \
	Main.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/PinTwiddling.o: PinTwiddling.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/PinTwiddling.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/PinTwiddling.o \
	PinTwiddling.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigIOC.o: ConfigIOC.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigIOC.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigIOC.o \
	ConfigIOC.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigUART.o: ConfigUART.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigUART.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigUART.o \
	ConfigUART.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/Casio_Com_Macros.o: Casio_Com_Macros.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Casio_Com_Macros.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Casio_Com_Macros.o \
	Casio_Com_Macros.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/Helper_Macros.o: Helper_Macros.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Helper_Macros.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Helper_Macros.o \
	Helper_Macros.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/UART_Com.o: UART_Com.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/UART_Com.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/UART_Com.o \
	UART_Com.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/Casio_Com.o: Casio_Com.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Casio_Com.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Casio_Com.o \
	Casio_Com.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
else
${OBJECTDIR}/Helper_Functions.o: Helper_Functions.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Helper_Functions.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Helper_Functions.o \
	Helper_Functions.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigClkPmd.o: ConfigClkPmd.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigClkPmd.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigClkPmd.o \
	ConfigClkPmd.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigCWG1.o: ConfigCWG1.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigCWG1.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigCWG1.o \
	ConfigCWG1.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigPins.o: ConfigPins.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigPins.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigPins.o \
	ConfigPins.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigPWM6.o: ConfigPWM6.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigPWM6.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigPWM6.o \
	ConfigPWM6.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigTMR2.o: ConfigTMR2.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigTMR2.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigTMR2.o \
	ConfigTMR2.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/Main.o: Main.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Main.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Main.o \
	Main.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/PinTwiddling.o: PinTwiddling.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/PinTwiddling.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/PinTwiddling.o \
	PinTwiddling.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigIOC.o: ConfigIOC.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigIOC.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigIOC.o \
	ConfigIOC.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/ConfigUART.o: ConfigUART.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/ConfigUART.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/ConfigUART.o \
	ConfigUART.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/Casio_Com_Macros.o: Casio_Com_Macros.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Casio_Com_Macros.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Casio_Com_Macros.o \
	Casio_Com_Macros.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/Helper_Macros.o: Helper_Macros.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Helper_Macros.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Helper_Macros.o \
	Helper_Macros.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/UART_Com.o: UART_Com.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/UART_Com.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/UART_Com.o \
	UART_Com.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
${OBJECTDIR}/Casio_Com.o: Casio_Com.s  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/Casio_Com.o 
	${MP_AS} -mcpu=PIC16F18446 -c \
	-o ${OBJECTDIR}/Casio_Com.o \
	Casio_Com.s \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp -Wa,-Wa,-a
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: pic-as-linker
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
dist/${CND_CONF}/${IMAGE_TYPE}/Casio_PICRAM.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk    
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_LD} -mcpu=PIC16F18446 ${OBJECTFILES_QUOTED_IF_SPACED} \
	-o dist/${CND_CONF}/${IMAGE_TYPE}/Casio_PICRAM.${IMAGE_TYPE}.${OUTPUT_SUFFIX} \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -mcallgraph=std -mno-download-hex
else
dist/${CND_CONF}/${IMAGE_TYPE}/Casio_PICRAM.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk   
	@${MKDIR} dist/${CND_CONF}/${IMAGE_TYPE} 
	${MP_LD} -mcpu=PIC16F18446 ${OBJECTFILES_QUOTED_IF_SPACED} \
	-o dist/${CND_CONF}/${IMAGE_TYPE}/Casio_PICRAM.${IMAGE_TYPE}.${OUTPUT_SUFFIX} \
	 -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -mcallgraph=std -mno-download-hex
endif


# Subprojects
.build-subprojects:


# Subprojects
.clean-subprojects:

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r build/default
	${RM} -r dist/default

# Enable dependency checking
.dep.inc: .depcheck-impl

DEPFILES=$(shell mplabwildcard ${POSSIBLE_DEPFILES})
ifneq (${DEPFILES},)
include ${DEPFILES}
endif
