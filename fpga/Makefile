# Build chip using Lattice Diamond command line tools
#   This is very close to Xilinx ISE command line... both based on NeoCAD

# Project name: used for file name prefix
NAME = ra

# Device family
TECH = ECP5UM5G

# Device part number
PART = LFE5UM5G-85F

# Device package
PACKAGE = CABGA381

# Device speed grade
SPEED = 8

# Source files
SRCS = \
rtl/ra_top.v \
rtl/bus_ram.v \
rtl/bus_reg.v \
rtl/bus_spiflash.v \
rtl/spimemio.v \
rtl/bus_uart.v \
rtl/picorv32.v \
rtl/rom.v \
rtl/simpleuart.v \
rtl/ram_sp_be.v

# Top level module
TOP = ra_top

# Default rules: build .bit file and .twr timing report file
all : gates/${NAME}.twr gates/${NAME}.bit

# Create synplify_pro synthesis script
# Note this gets recreated if any source file is modified
# which triggers a full chip rebuild
syn/${NAME}_syn.tcl : ${SRCS} Makefile
	rm -f ${NAME}_syn.tcl
	rm -rf syn
	rm -rf gates
	mkdir syn
	echo "set_option -technology ${TECH}" >syn/${NAME}_syn.tcl
	echo "set_option -part ${PART}" >>syn/${NAME}_syn.tcl
	echo "set_option -package ${PACKAGE}" >>syn/${NAME}_syn.tcl
	echo "set_option -speed_graed -${SPEED}" >>syn/${NAME}_syn.tcl
	echo "set_option -symbolic_fsm_compiler true" >>syn/${NAME}_syn.tcl
	echo "set_option -resource_sharing true" >>syn/${NAME}_syn.tcl
	echo "set_option -vlog_std v2001" >>syn/${NAME}_syn.tcl
	echo "set_option -frequency 200" >>syn/${NAME}_syn.tcl
	echo "set_option -maxfan 1000" >>syn/${NAME}_syn.tcl
	echo "set_option -auto_constrain_io 0" >>syn/${NAME}_syn.tcl
	echo "set_option -disable_io_insertion false" >>syn/${NAME}_syn.tcl
	echo "set_option -retiming false; set_option -pipe true" >>syn/${NAME}_syn.tcl
	echo "set_option -force_gsr auto" >>syn/${NAME}_syn.tcl
	echo "set_option -compiler_compatible 0" >>syn/${NAME}_syn.tcl
	echo "set_option -dup false" >>syn/${NAME}_syn.tcl
	echo "set_option -default_enum_encoding default" >>syn/${NAME}_syn.tcl
	echo "set_option -num_critical_paths 3" >>syn/${NAME}_syn.tcl
	echo "set_option -write_apr_constraint 1" >>syn/${NAME}_syn.tcl
	echo "set_option -fix_gated_and_generated_clocks 1" >>syn/${NAME}_syn.tcl
	echo "set_option -update_models_cp 0" >>syn/${NAME}_syn.tcl
	echo "set_option -resolve_multiple_driver 0" >>syn/${NAME}_syn.tcl
	echo "set_option -include_path {../rtl}" >>syn/${NAME}_syn.tcl
	(for a in ${SRCS}; do echo "add_file -verilog {../$$a}" >>syn/${NAME}_syn.tcl; done)
	echo "set_option -top_module ${TOP}" >>syn/${NAME}_syn.tcl
	echo "project -result_file {${NAME}.edi}" >>syn/${NAME}_syn.tcl
	echo "project -log_file {${NAME}.srf}" >>syn/${NAME}_syn.tcl
	echo "project -run -clean" >>syn/${NAME}_syn.tcl

# Synthesize
syn/rev_1/${NAME}.edi: syn/${NAME}_syn.tcl
	(cd syn; synpwrap -msg -prj ${NAME}_syn.tcl)

# Convert EDIF to NGO
gates/${NAME}.ngo: syn/rev_1/${NAME}.edi
	mkdir gates && (cd gates; edif2ngd  -l "${TECH}" -d ${PART} ../syn/rev_1/${NAME}.edi ${NAME}.ngo)

# Convert NGO to NGD
gates/${NAME}.ngd: gates/${NAME}.ngo
	(cd gates; ngdbuild  -a "${TECH}" -d ${PART}  -p "/opt/lattice/diamond/3.11_x64/ispfpga/sa5p00g/data" ${NAME}.ngo ${NAME}.ngd)

# Map
gates/${NAME}_map.ncd: gates/${NAME}.ngd ${NAME}.lpf
	(cd gates; map -a "${TECH}" -p ${PART} -t ${PACKAGE} -s ${SPEED} -oc Commercial ${NAME}.ngd -o ${NAME}_map.ncd -pr ${NAME}.prf -mp ${NAME}.mrp -lpf ../${NAME}.lpf)

# Place and route
gates/${NAME}.ncd: gates/${NAME}_map.ncd gates/${NAME}.prf
	(cd gates; mpartrce -p ../${NAME}.p2t -f ../${NAME}.p3t -tf ../${NAME}.pt ${NAME}_map.ncd ${NAME}.ncd)

# Trace (timing check)
gates/${NAME}.twr: gates/${NAME}.ncd gates/${NAME}.prf
	(cd gates; trce -f ../${NAME}.pt -o ${NAME}.twr ${NAME}.ncd ${NAME}.prf)

# Convert .ncd to .bit
gates/${NAME}.bit: gates/${NAME}.ncd gates/${NAME}.prf
	(cd gates; bitgen ${NAME}.ncd -f ../${NAME}.t2b ${NAME}.prf)

clean:
	rm -rf ${NAME}_syn.tcl
	rm -rf syn
	rm -rf gates
