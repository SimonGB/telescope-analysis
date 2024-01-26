#!/bin/bash
do_initialisation=false
initialisation_events=100000

do_alignment=false
ALIGNMENT_MODULE="AlignmentTrackChi2" # AlignmentMillepede or AlignmentTrackChi2
alignment_events=10000
alignment_iterations=5

do_tracking=true
TRACKING_MODULE="TrackingMultiplet" # Tracking4D or TrackingMultiplet
TRACK_MODEL="gbl" # straightLine or gbl
TRACKING_GEOMETRY_FILE="/home/alpide/Simon/marburg/output/AlignmentTrackChi2_Tracking4D_gbl_TEST_2501-target_out/2-AlignmentTrackChi2_Tracking4D_gbl_TEST_2501-target_out_aligned.geo"
tracking_events=100000000
tracking_analysebunch_size=500000

do_dutanalysis=false
dutanalysis_events=500000


# ############################################################### #
target_out=true
MIN_HITS_ON_TRACK=6
DETECTORS=("ALPIDE_0" "ALPIDE_1" "ALPIDE_2" "ALPIDE_3" "ALPIDE_4" "ALPIDE_5")
UPSTREAM_DETECTORS="\"ALPIDE_0\" \"ALPIDE_1\" \"ALPIDE_2\""
DOWNSTREAM_DETECTORS="\"ALPIDE_3\" \"ALPIDE_4\" \"ALPIDE_5\""

OUTPUT_DIR=/home/alpide/Simon/marburg/output

INITIAL_GEOMETRY_FILE="/home/alpide/Simon/marburg/initial_telescope_geometry.geo"
# DATA_FILE="/media/alpide/ALPIDE_data/marburg/run452011329_231107013100.raw"
DATA_PATH="/media/alpide/ALPIDE_data/marburg"
dataset_number=0

get_data_files() {
    OUTPUT_NAME="${ALIGNMENT_MODULE}_${TRACKING_MODULE}_${TRACK_MODEL}_2601"

    if [ $target_out = true ]; then
        # TARGET OUT
        RAW_FILES=(
            "run452011329_231107013100.raw"  
            "run452011330_231107014010.raw"  
            "run452011331_231107014809.raw"  
            "run452011332_231107015636.raw"  
            "run452011333_231107020445.raw"  
            "run452011334_231107021250.raw"
            "run452011335_231107022043.raw"
        )
        MOMENTUM=0.668689         
        LORENTZ_BETA=0.580373
        OUTPUT_NAME="$OUTPUT_NAME-target_out"
    else  # TARGET IN
        # List of .raw files
        RAW_FILES=(
            "run452011337_231107030529.raw" 
            "run452011338_231107031233.raw"  
            "run452011339_231107031859.raw"  
            "run452011340_231107032515.raw"  
            "run452011341_231107033130.raw"  
            "run452011342_231107033751.raw"  
            "run452011343_231107034411.raw"
            "run452011344_231107035026.raw"
        )
        MOMENTUM=0.680970          
        LORENTZ_BETA=0.587376
        OUTPUT_NAME="$OUTPUT_NAME-target_in"
    fi
    DATA_FILE="$DATA_PATH/${RAW_FILES[dataset_number]}"
}

create_init_conf() {
    modules_init=("Corryvreckan" "Metronome" "EventLoaderEUDAQ2" "MaskCreator" "Clustering4D" "Correlations" "Prealignment")
    echo "" > ${OUTPUT_CONF}
    for module in "${modules_init[@]}"
    do
        sed -n '/'"$module"'\]/,/\[/p' /home/alpide/Simon/marburg/module_templates.conf | sed '$d' >> ${OUTPUT_CONF}
    done
}

create_alignment_conf() {
    modules_alignment=("Corryvreckan" "Metronome" "EventLoaderEUDAQ2" "Clustering4D" $TRACKING_MODULE $ALIGNMENT_MODULE)
    echo "" > ${OUTPUT_CONF}
    for module in "${modules_alignment[@]}"
    do
        sed -n '/'"$module"'\]/,/\[/p' /home/alpide/Simon/marburg/module_templates.conf | sed '$d' >> ${OUTPUT_CONF}
    done
}

create_tracking_conf() {
    modules_tracking=("Corryvreckan" "Metronome" "EventLoaderEUDAQ2" "Clustering4D" $TRACKING_MODULE)
    echo "" > ${OUTPUT_CONF}
    for module in "${modules_tracking[@]}"
    do
        sed -n '/'"$module"'\]/,/\[/p' /home/alpide/Simon/marburg/module_templates.conf | sed '$d' >> ${OUTPUT_CONF}
    done
    sed -i '/GEOMETRY_FILE_UPDATED/d' ${OUTPUT_CONF}
}

create_dut_conf() {
    modules_dut=("Corryvreckan" "Metronome" "EventLoaderEUDAQ2" "Clustering4D" $TRACKING_MODULE "DUTAssociation" "AnalysisDUT")
    echo "" > ${OUTPUT_CONF}
    for module in "${modules_dut[@]}"
    do
        sed -n '/'"$module"'\]/,/\[/p' /home/alpide/Simon/marburg/module_templates.conf | sed '$d' >> ${OUTPUT_CONF}
    done
    sed -i '/GEOMETRY_FILE_UPDATED/d' ${OUTPUT_CONF}
}


exchange_placeholders() {
    # Read the template configuration file
    CONFIG_CONTENT=$(cat "$OUTPUT_CONF")

    # Replace the placeholders in the configuration file

    # Corryvreckan
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{OUTPUT_DIR\}\}/\"$OUTPUT_DIR\"}
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{GEOMETRY_FILE\}\}/\"$GEOMETRY_FILE\"}
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{GEOMETRY_FILE_UPDATED\}\}/\"$GEOMETRY_FILE_UPDATED\"}
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{OUTPUT_FILE\}\}/\"$OUTPUT_FILE\"}
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{NUMBER_OF_EVENTS\}\}/$NUMBER_OF_EVENTS}
    # METRONOME
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{SKIP_TRIGGERS\}\}/$SKIP_TRIGGERS}
    # EventLoaderEUDAQ2
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{DATA_FILE\}\}/\"$DATA_FILE\"}
    # Tracking
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{TRACK_MODEL\}\}/\"$TRACK_MODEL\"}
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{MOMENTUM\}\}/$MOMENTUM}
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{LORENTZ_BETA\}\}/$LORENTZ_BETA}
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{MIN_HITS_ON_TRACK\}\}/$MIN_HITS_ON_TRACK}
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{UPSTREAM_DETECTORS\}\}/$UPSTREAM_DETECTORS}
    CONFIG_CONTENT=${CONFIG_CONTENT/\{\{DOWNSTREAM_DETECTORS\}\}/$DOWNSTREAM_DETECTORS}
    
    # Save the modified configuration content to the output file
    echo "$CONFIG_CONTENT" > "$OUTPUT_CONF"
}

execute() {
    ./../../corryvreckan/bin/corry -c "$OUTPUT_CONF" >> "${OUTPUT_DIR}/log.txt" 2>&1
    # echo "${OUTPUT_CONF}" #>> "${OUTPUT_DIR}/log.txt" 2>&1
}

# ############################################################### #
#                                                                 #
#                           MAIN                                  #
#                                                                 #
# ############################################################### #

# OUTPUT_CONF="output_test.conf"
get_data_files
OUTPUT_DIR="$OUTPUT_DIR/$OUTPUT_NAME"
mkdir -p "$OUTPUT_DIR"
echo "" > "${OUTPUT_DIR}/log.txt" 2>&1

# ############################################## INITIALISATION ############################################## #
if [ "$do_initialisation" = true ] ; then
    echo -en "Initialisation ..."
    TEMP_GEO="${OUTPUT_DIR}/0-${OUTPUT_NAME}_prealigned.geo"
    echo "" > ${TEMP_GEO}
    for ((detector_n=0; detector_n<${#DETECTORS[@]}; detector_n++)); do
        module="ALPIDE_$detector_n"
        sed -n '/'"$module"'\]/,/\[/p' "/home/alpide/Simon/marburg/geometry_templates.geo" | sed '$d' >> ${TEMP_GEO}
    done
    GEOMETRY_FILE="${TEMP_GEO}"
    FILE_NAME="0-${OUTPUT_NAME}_prealigned"
    OUTPUT_CONF="${OUTPUT_DIR}/${FILE_NAME}.conf"
    GEOMETRY_FILE_UPDATED="$OUTPUT_DIR/${FILE_NAME}.geo"
    OUTPUT_FILE="${FILE_NAME}.root"

    NUMBER_OF_EVENTS=$initialisation_events
    SKIP_TRIGGERS=0
    create_init_conf
    exchange_placeholders
    execute
    echo -en "\rInitialisation Done!\n"
fi
# ############################################## ALIGNMENT ############################################## #
if [ "$do_alignment" = true ] ; then
    for ((iteration=1; iteration<=$alignment_iterations; iteration++)); do
        echo -en "\rAlignment Iteration $iteration/$alignment_iterations ..."
        GEOMETRY_FILE="$OUTPUT_DIR/0-${OUTPUT_NAME}_prealigned.geo"
        FILE_NAME="2-${OUTPUT_NAME}_aligned"
        if [ $iteration -gt 1 ]; then
                GEOMETRY_FILE="$OUTPUT_DIR/1-${OUTPUT_NAME}_alignment_iteration_$((iteration-1)).geo"
        fi
        if [ $iteration -lt $alignment_iterations ]; then
                FILE_NAME="1-${OUTPUT_NAME}_alignment_iteration_${iteration}"
        fi
        GEOMETRY_FILE_UPDATED="$OUTPUT_DIR/${FILE_NAME}.geo"
        OUTPUT_FILE="${FILE_NAME}.root"
        OUTPUT_CONF="${OUTPUT_DIR}/${FILE_NAME}.conf"
        
        NUMBER_OF_EVENTS=$alignment_events
        SKIP_TRIGGERS=$((initialisation_events+(alignment_events*(iteration-1))))
        create_alignment_conf
        exchange_placeholders
        execute
    done    
    echo -en "\rAlignment ($alignment_iterations Iterations) Done!\n"

fi
# ############################################## TRACKING ############################################## #
if [ "$do_tracking" = true ] ; then
    if [ "$do_alignment" = true ] ; then
        GEOMETRY_FILE="$OUTPUT_DIR/2-${OUTPUT_NAME}_aligned.geo"
    elif [ "$do_alignment" = false ] && [ "$do_initialisation" = false ] ; then
        GEOMETRY_FILE="$TRACKING_GEOMETRY_FILE"  # ADD OWN ALIGNED GEOMETRY FILE
        echo "Using own aligned geometry file: $GEOMETRY_FILE"
        echo "Using own aligned geometry file: $GEOMETRY_FILE" >> "${OUTPUT_DIR}/log.txt"
    else
        echo "No alignment done --> using initial geometry file"
        GEOMETRY_FILE="$INITIAL_GEOMETRY_FILE"
    fi
    NUMBER_OF_EVENTS=$tracking_analysebunch_size
    counter=0
    analysed_events=0
    dataset_size=2000000
    for ((dataset_number = 0; dataset_number < ${#RAW_FILES[@]}; dataset_number++)); do
        get_data_files
        for ((SKIP_TRIGGERS = 0; SKIP_TRIGGERS < dataset_size; SKIP_TRIGGERS += $NUMBER_OF_EVENTS)); do
            echo -en "\rTracking Events $analysed_events/$tracking_events ..."
            FILE_NAME="3-${OUTPUT_NAME}_tracking_${counter}"
            OUTPUT_CONF="${OUTPUT_DIR}/${FILE_NAME}.conf"
            OUTPUT_FILE="${FILE_NAME}.root"
            create_tracking_conf
            exchange_placeholders
            execute
            counter=$((counter+1))
            analysed_events=$((analysed_events+NUMBER_OF_EVENTS))
            if [ $analysed_events -gt $tracking_events ]; then
                break 2
            fi
        done
    done
    TRACKING_GEOMETRY_FILE="$GEOMETRY_FILE"
    echo -en "\rTracking ($analysed_events Events) Done!\n"
fi
# ############################################## DUT ANALYSIS ############################################## #
if [ "$do_dutanalysis" = true ] ; then
    DETECTORS=("ALPIDE_0" "ALPIDE_1" "ALPIDE_2" "ALPIDE_3" "ALPIDE_4" "ALPIDE_5")
    SKIP_TRIGGERS=0
    MIN_HITS_ON_TRACK=5
    if [ $do_initialisation=true ]; then
        SKIP_TRIGGERS=$((SKIP_TRIGGERS+initialisation_events))
    fi
    if [ $do_alignment=true ]; then
        SKIP_TRIGGERS=$((SKIP_TRIGGERS+alignment_events*alignment_iterations))
    fi
    if [ $do_tracking=true ]; then
        SKIP_TRIGGERS=$((SKIP_TRIGGERS+tracking_events))
    fi

    for ((detector=0; detector<${#DETECTORS[@]}; detector++)); do
        detector_string="ALPIDE_$detector"
        if [ $detector -eq 1 ]; then
            echo "Skipping ALPIDE 1, as it is reference"
        else
            echo -en "\rDUT Analysis of ALPIDE $detectos ..."
            FILE_NAME="4-${OUTPUT_NAME}_DUT_$((detector))"
            GEOMETRY_FILE="$TRACKING_GEOMETRY_FILE"
            # GEOMETRY_FILE="/home/alpide/Simon/marburg/geometry_templates.geo"
            OUTPUT_CONF="${OUTPUT_DIR}/${FILE_NAME}.conf"
            TEMP_GEO="${OUTPUT_DIR}/${FILE_NAME}.geo"
            OUTPUT_FILE="${FILE_NAME}.root"
            UPSTREAM_DETECTORS=""
            DOWNSTREAM_DETECTORS=""

            echo "" > ${TEMP_GEO}
            for ((detector_n=0; detector_n<${#DETECTORS[@]}; detector_n++)); do
                module="ALPIDE_$detector_n"
                # sed -n '/'"$module"'\]/,/\[/p' "/home/alpide/Simon/marburg/geometry_templates.geo" | sed '$d' >> ${TEMP_GEO}
                sed -n '/'"$module"'\]/,/\[/p' "${GEOMETRY_FILE}" | sed '$d' >> ${TEMP_GEO}
                if [ $module = $detector_string ]; then
                    # echo 'role = "dut"' >> ${TEMP_GEO}
                    sed -i '$s/.*/role = "dut"/' ${TEMP_GEO}
                    echo "" >> $TEMP_GEO
                else
                    if [ $detector_n -lt 3 ]; then
                        UPSTREAM_DETECTORS="$UPSTREAM_DETECTORS \"$module\""
                    else
                        DOWNSTREAM_DETECTORS="$DOWNSTREAM_DETECTORS \"$module\""
                    fi
                fi
            done

            NUMBER_OF_EVENTS=$dutanalysis_events
            create_dut_conf
            exchange_placeholders
            execute
            echo -en "\rDUT Analysis of ALPIDE $detector Done!\n"
        fi
    done
    echo -en "\rDUT Analysis Done!\n"
fi
# ############################################## END ############################################## #

echo "Please find the output files in: $OUTPUT_DIR"
echo "Done! :)"