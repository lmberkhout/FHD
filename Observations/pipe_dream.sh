#!/bin/bash

#
#COMMENTS
#

#Clear input parameters
unset obs_file_name
unset starting_obs
unset ending_obs
unset outdir
unset version
unset resubmit_list
unset resubmit_index

#Parse flags for inputs
while getopts ":f:s:e:o:v:p:w:n:m:t:" option
do
   case $option in
	f) obs_file_name="$OPTARG";;	#text file of observation id's
	s) starting_obs=$OPTARG;;	#starting observation in text file for choosing a range
	e) ending_obs=$OPTARG;;		#ending observation in text file for choosing a range
        o) outdir=$OPTARG;;		#output directory for FHD output folder
        v) version=$OPTARG;;		#FHD folder name and case for eor_firstpass_versions
					#Example: nb_foo creates folder named fhd_nb_foo
        p) priority=$OPTARG;;		#priority level for grid engine qsub 
	w) wallclock_time=$OPTARG;;	#Time for execution in grid engine
	n) nslots=$OPTARG;;		#Number of slots for grid engine
	m) mem=$OPTARG;;		#Memory per core for grid engine
	t) thresh=$OPTARG;;		#Wedge threshold to use to determine whether or not to run
	\?) echo "Unknown option: Accepted flags are -f (obs_file_name), -s (starting_obs), -e (ending obs), -o (output directory), "
	    echo "-v (version input for FHD), -p (priority in grid engine), -w (wallclock time in grid engine), -n (number of slots to use),"
	    echo "and -m (memory per core for grid engine)." 
	    exit 1;;
	:) echo "Missing option argument for input flag"
	   exit 1;;
   esac
done

#Manual shift to the next flag.
shift $(($OPTIND - 1))

#Specify the FHD file path that is used in IDL (generally specified in idl_startup)
FHDpath=$(idl -e 'print,rootdir("fhd")') ### NOTE this only works if idlstartup doesn't have any print statements (e.g. healpix check)

#Throw error if no obs_id file.
if [ -z ${obs_file_name} ]; then
   echo "Need to specify a full filepath to a list of viable observation ids."
   exit 1
fi

#Update the user on which obsids will run given the inputs
if [ -z ${starting_obs} ] 
then
    echo Starting at observation at beginning of file $obs_file_name
else
    echo Starting on observation $starting_obs
fi

if [ -z ${ending_obs} ]
then
    echo Ending at observation at end of file $obs_file_name
else
    echo Ending on observation $ending_obs
fi


#Set default output directory if one is not supplied and update user
if [ -z ${outdir} ]
then
    outdir=/nfs/mwa-09/r1/djc/EoR2013/Aug23
    echo Using default output directory: $outdir
else
    #strip the last / if present in output directory filepath
    outdir=${outdir%/}
    echo Using output directory: $outdir
fi

#Use default version if not supplied.
if [ -z ${version} ]; then
   echo Please specify a version, e.g, yourinitials_test
   exit 1
fi

if grep -q \'${version}\' ${FHDpath}Observations/eor_firstpass_versions.pro
then
    echo Using version $version
else
    echo Version \'${version}\' was not found in ${FHDpath}Observations/eor_firstpass_versions.pro
    exit 1
fi

#Default priority if not set.
if [ -z ${priority} ]; then
    priority=0
fi
#Set typical wallclock_time for standard FHD firstpass if not set.
if [ -z ${wallclock_time} ]; then
    wallclock_time=04:00:00
fi
#Set typical slots needed for standard FHD firstpass if not set.
if [ -z ${nslots} ]; then
    nslots=10
fi
#Set typical memory needed for standard FHD firstpass if not set.
if [ -z ${mem} ]; then
    mem=4G
fi
if [ -z ${thresh} ]; then
    # if thresh is not set, set it to -1 which will cause it to not check for a window power
    thresh=-1
fi

#Make directory if it doesn't already exist
mkdir -p ${outdir}/fhd_${version}
mkdir -p ${outdir}/fhd_${version}/grid_out
echo Output located at ${outdir}/fhd_${version}

#Read the obs file and put into an array, skipping blank lines if they exist
i=0
while read line
do
   if [ ! -z "$line" ]; then
      obs_id_array[$i]=$line
      i=$((i + 1))
   fi
done < "$obs_file_name"

#Find the max and min of the obs id array
max=${obs_id_array[0]}
min=${obs_id_array[0]}

for obs_id in "${obs_id_array[@]}"
do
   #Update max if applicable
   if [[ "$obs_id" -gt "$max" ]]
   then
	max="$obs_id"
   fi

   #Update min if applicable
   if [[ "$obs_id" -lt "$min" ]]
   then
	min="$obs_id"
   fi
done

#If minimum not specified, start at minimum of obs_file
if [ -z ${starting_obs} ]
then
   echo "Starting observation not specified: Starting at minimum of $obs_file_name"
   starting_obs=$min
fi

#If maximum not specified, end at maximum of obs_file
if [ -z ${ending_obs} ]
then
   echo "Ending observation not specified: Ending at maximum of $obs_file_name"
   ending_obs=$max
fi

#Create a list of observations using the specified range, or the full observation id file. 
unset good_obs_list
for obs_id in "${obs_id_array[@]}"; do
    if [ $obs_id -ge $starting_obs ] && [ $obs_id -le $ending_obs ]; then
	good_obs_list+=($obs_id)
    fi
done


#####Submit the firstpass job and wait for output

nobs=${#good_obs_list[@]}

message=$(qsub -p $priority -P FHD -l h_vmem=$mem,h_stack=512k,h_rt=${wallclock_time} -V -v nslots=$nslots,outdir=$outdir,version=$version,thresh=$thresh -e ${outdir}/fhd_${version}/grid_out -o ${outdir}/fhd_${version}/grid_out -t 1:${nobs} -pe chost $nslots -sync y ${FHDpath}Observations/eor_firstpass_job.sh ${good_obs_list[@]})
message=($message)
id=`echo ${message[2]} | cut -f1 -d"."`

####

#Check that output location is not running out of space
if df -h $outdir | awk '{print $4}' | grep M -q; then
   echo There is only "$(df -h $outdir | awk '{print $4}' | grep M)" space left on disk. Exiting
   exit 1
fi

#Check to see if there was any errors in the grid_out files
i=0
for obs_id in "${obs_id_array[@]}"; do
   i=$((i + 1))
   if grep "Execution halted at:" $outdir/fhd_$version/grid_out/firstpass.e$id.$i -q; then
      echo $obs_id encountered code error during firstpass run
      resubmit_list+=($obs_id)
      resubmit_index+=($i)
   fi
done

#Exit if all jobs errored. Otherwise, if not all jobs errored, it is assumed that a pull happened sometime
#during the run, and that resubmission is desired.
n_resubmit=${#resubmit_list[@]}
if [ "$nobs" -eq "$n_resubmit" ]; then
   echo All jobs encountered code errors or halts during firstpass run. Exiting
   exit 1
fi


#Check to see if Healpix cubes exist for all obsids
i=0
rerun_flag=0
for obs_id in "${obs_id_array[@]}"; do
    i=$((i + 1))
    # Check to see if 4 files (even/odd, XX/YY) return from listing for that obsid
    if ! ls -1 ${outdir}/fhd_${version}/Healpix/${obs_id}*cube* 2>/dev/null | wc -l | grep 4 -q; then
	echo Observation $obs_id is missing one or more Healpix cubes
        rerun_flag=1
        [[ $resubmit_list =~ $x ]] || resubmit_list+=($obs_id)
        [[ $resubmit_index =~ $i ]] || resubmit_index+=($i)
    fi

done

#Check to see if Healpix-less cubes ran out of time
wallclock_resubmit_flag=0
for index in "${resubmit_index[@]}"; do
   wallclock_used_total="$(qacct -j $id -t $index | grep ru_wallclock | awk '{print $2}')"
   wallclock_given_hrs="$(echo $wallclock_time | awk -F':' '{print $1}')"
   wallclock_given_min="$(echo $wallclock_time | awk -F':' '{print $2}')"
   wallclock_given_sec="$(echo $wallclock_time | awk -F':' '{print $3}')"
   wallclock_given_total=$(echo ${wallclock_given_hrs} ${wallclock_given_min} ${wallclock_given_sec} | awk '{printf "%8f\n",$1*3600+$2*60+$3}')

#Add two hours if jobs exited because of lack of time
   if [ -n "$wallclock_used_total" -a -n "$wallclock_given_total" ];then
      result=$(awk -vn1="$wallclock_used_total" -vn2="$wallclock_given_total" 'BEGIN{print (n1>n2)?1:0 }')
      if [ "$result" -eq 1 ];then
         wallclock_resubmit="$(($wallclock_given_hrs+2))":00:00
         wallclock_resubmit_flag=1
         echo Adding two more hours to wallclock time for $index
      else
         if [ "$wallclock_resubmit_flag" -ne 1 ];then 
            wallclock_resubmit=$wallclock_time
         fi
      fi
   fi
done

#Check to see if Healpix-less cubes ran out of memory
#First check total alloted memory (mem * nslots)
if echo $mem | grep G -q; then
   totalmem="$((${mem%G}*$nslots))"
elif echo $mem | grep M -q; then
   totalmem=$(echo ${mem%M} $nslots 1000 | awk '{printf "%5.3f\n",$1*$2/$3}')
fi
#Now check what was actually used
resubmit_mem_flag=0
for index in "${resubmit_index[@]}"; do
   taskmem_used_full="$(qacct -j $id -t $index | grep maxvmem | awk '{print $2}')"
   if echo $taskmem_used_full | grep G -q; then
      taskmem_used=${taskmem_used_full%G}
   elif echo $taskmem_used_full | grep M -q; then
      taskmem_used=$(echo ${taskmem_used_full%M} 1000 | awk '{printf "%5.3f\n",$1/$2}')
   else
      taskmem_used=0
   fi

#Check to see if what was used is bigger than the allotment (what happens right before mem error)
#If it is bigger than the allotment, try adding 2G per slot
   if [ -n "$taskmem_used" -a -n "$totalmem" ];then
      result=$(awk -vn1="$taskmem_used" -vn2="$totalmem" 'BEGIN{print (n1>n2)?1:0 }')
      if [ "$result" -eq 1 ];then
         if echo $mem | grep G -q; then
            resubmit_mem="$((${mem%G}+2))"G
            resubmit_mem_flag=1
            echo Adding two more Gigs to memory for $index
         elif echo $mem | grep M -q; then
            resubmit_mem=$(echo ${mem%M} 1000 2 | awk '{printf "%5.3f\n",$1/$2+$3}')G
            resubmit_mem_flag=1
            echo Adding two more Gigs to memory for $index
         fi
      else
         if [ "$resubmit_mem_flag" -ne 1 ];then 
            resubmit_mem=$mem
         fi
      fi
   fi

done


#####Resubmit the firstpass jobs that failed and might benefit from a rerun
if [ "$rerun_flag" -ne 1 ];then 

   nobs=${#resubmit_list[@]}

   message=$(qsub -p $priority -P FHD -l h_vmem=$resubmit_mem,h_stack=512k,h_rt=${wallclock_resubmit} -V -v nslots=$nslots,outdir=$outdir,version=$version,thresh=$thresh -e ${outdir}/fhd_${version}/grid_out -o ${outdir}/fhd_${version}/grid_out -t 1:${nobs} -pe chost $nslots -sync y ${FHDpath}Observations/eor_firstpass_job.sh ${resubmit_list[@]})
   message=($message)
   id=`echo ${message[2]} | cut -f1 -d"."`

####

fi


### NOTE this only works if idlstartup doesn't have any print statements (e.g. healpix check)
PSpath=$(idl -e 'print,rootdir("ps")')

.${PSpath}ps_wrappers/ps_script.sh -f $obs_file_name -d $outdir/fhd_$version


echo "Cube integration and PS submitted"

