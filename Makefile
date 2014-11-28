## MAKEFILE FOR Hi-C PROCESSING
## Nicolas Servant

## DO NOT EDIT THE REST OF THIS FILE!!

## special characters
comma := ,
space :=
space +=
slash := |
tick := -
undsc := _

all : init mapping proc_hic build_contact_maps clean

all_qsub : mapping proc_hic

init : configure src_compile

mapping: bowtie_global bowtie_local merge_global_local mapping_stat

proc_hic : bowtie_pairing mapped2HiCFragments 

## Per sample
build_contact_maps: merge_rmdup build_raw_maps ice_norm plots

debug:
	@echo "RAW_DIR="$(RAW_DIR)
	@echo "FASTQ_FILE="$(READSFILE_FQ)
	@echo "RES_FILE="$(RES_FILE_NAME)
	@echo "RES_FILE_OBJ="$(RES_FILE_NAME_OBJ)

######################################
## System
##
######################################
config_check:
ifndef CONFIG_FILE
$(error CONFIG_FILE is not defined)
else
include $(CONFIG_FILE)
endif

make_torque_script: config_check init
	@$(SCRIPTS)/make_torque_script.sh -c $(CONFIG_FILE) $(TORQUE_SUFFIX)

clean: config_check 
ifdef BOWTIE2_OUTPUT_DIR
	/bin/rm -f $(BOWTIE2_OUTPUT_DIR)/*/*/*.sam
endif

reset: 
ifdef LOGS_DIR
	/bin/rm -f $(LOGS_DIR)/*
endif
	/bin/rm -rf bowtie_results hic_results


######################################
## Configure outputs
##
######################################

## Create output folders
configure:  config_check
	mkdir -p $(BOWTIE2_OUTPUT_DIR)
	mkdir -p $(MAPC_OUTPUT)
	mkdir -p $(TMP_DIR)
	mkdir -p $(LOGS_DIR)
	@echo "## Hi-C Mapping $(VERSION)" > $(LOGFILE)
	@date >> $(LOGFILE)

######################################
## Compile
##
######################################

## Build C++ code
src_compile: $(SOURCES)/build_matrix.cpp
	(g++ -Wall -O2 -std=c++0x -o build_matrix ${SOURCES}/build_matrix.cpp; mv build_matrix ${SCRIPTS})
	(cp $(SOURCES)/ice_mod/iced/scripts/ice ${SCRIPTS}; cd $(SOURCES)/ice_mod/; python setup.py install --user;)

######################################
## Bowtie2 Global Alignment
##
######################################

## Global Alignement
bowtie_global:  config_check
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Bowtie2 global alignment ..." >> $(LOGFILE)
	$(SCRIPTS)/bowtie_wrap.sh -c $(CONFIG_FILE) -u

######################################
##  Bowtie2 Local Alignment
##
######################################

## Local Alignement
bowtie_local:  config_check
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Bowtie2 local alignment ..." >> $(LOGFILE)
	$(SCRIPTS)/bowtie_wrap.sh -c $(CONFIG_FILE) -l

######################################
## Merge Bowtie2 local and global mapping
## 
######################################

## Merge global and local alignment in a single file
merge_global_local:  config_check
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Merge both alignment ..." >> $(LOGFILE)
	$(SCRIPTS)/bowtie_combine.sh -c $(CONFIG_FILE)

## Compute mapping statistics
mapping_stat:  config_check
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Bowtie2 mapping statistics for R1 and R2 tags ..." >> $(LOGFILE)
	$(SCRIPTS)/mapping_stat.sh -c $(CONFIG_FILE)

plots:
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Make plots per sample ..." >> $(LOGFILE)
	$(SCRIPTS)/make_plots.sh -c $(CURDIR)/$(CONFIG_FILE)


######################################
## Hi-C processing 
##
######################################

## Pairing of R1 and R2 mates and reads filtering
bowtie_pairing:  config_check
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Pairing of R1 and R2 tags ..." >> $(LOGFILE)
	$(SCRIPTS)/bowtie_pairing.sh -c $(CONFIG_FILE)

## Assign alignments to regions segmented by HindIII sites
mapped2HiCFragments:  config_check
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Assign alignments to HindIII sites ..." >> $(LOGFILE)
	$(SCRIPTS)/overlapMapped2HiCFragments.sh -c $(CONFIG_FILE) > $(LOGS_DIR)/overlapRS.log

## Combine multiple BAM files from the same sample, and remove duplicates
merge_rmdup:  config_check
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Merge multiple files from the same sample ..." >> $(LOGFILE)
	$(SCRIPTS)/mergeValidInteractions.sh -c $(CONFIG_FILE) > $(LOGS_DIR)/mergeMulti.log

# merge_rmdup2:
# 	@echo "--------------------------------------------" >> $(LOGFILE)
# 	@date >> $(LOGFILE)
# 	@echo "Merge multiple files from the same sample ..." >> $(LOGFILE)
# 	$(SCRIPTS)/mergeValidInteractions_v2.sh -c $(CONFIG_FILE) > $(LOGS_DIR)/mergeMulti_v2.log

build_raw_maps:  config_check
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Generate binned matrix files ..." >> $(LOGFILE)
	$(SCRIPTS)/assignRead2bins.sh -c $(CONFIG_FILE) 2> $(LOGS_DIR)/build_raw_maps.log

######################################
## Normalization
##
######################################

## Apply ICE normalization
ice_norm:
	@echo "--------------------------------------------" >> $(LOGFILE)
	@date >> $(LOGFILE)
	@echo "Run ICE Normalization ..." >> $(LOGFILE)
	$(SCRIPTS)/normContactMaps.sh -c $(CONFIG_FILE) 2> $(LOGS_DIR)/normICE.log

