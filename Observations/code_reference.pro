PRO code_reference,_Extra=extra
except=!except
!except=0 
heap_gc

calibrate_visibilities=1
recalculate_all=0
export_images=1
cleanup=0
git,'rev-parse --abbrev-ref HEAD',repo=rootdir('fhd'),result=branch & branch=branch[0]
git,'describe',result=version,repo_path=rootdir('FHD') & version=version[0]

version=version+'_'+branch
IF N_Elements(extra) GT 0 THEN IF Tag_exist(extra,'version') THEN version=extra.version
data_directory=rootdir('mwa')+filepath('',root='DATA3',subdir=['128T','code_reference'])
vis_file_list=file_search(data_directory,'*.uvfits',count=n_files)
IF n_files EQ 0 THEN vis_file_list=file_search(data_directory,'*.uvfits.sav',count=n_files) ;compatibility with my laptop 
iter=0
version_use=version
test_dir=filepath('',root=data_directory,sub='fhd_'+version_use)
WHILE file_test(test_dir,/directory) EQ 1 DO BEGIN
    iter+=1
    IF iter GE 100 THEN BEGIN
        print,'Could not make fhd directory, too many versions exist: fhd_'+version
        RETURN
    ENDIF
    version_use=version+'_run'+Strn(iter)
    test_dir=filepath(root=data_directory,sub='fhd_'+version_use)
ENDWHILE
fhd_file_list=fhd_path_setup(vis_file_list,version=version_use,_Extra=extra)
undefine_fhd,iter,branch

healpix_path=fhd_path_setup(output_dir=data_directory,subdir='Healpix',output_filename='Combined_obs',version=version,_Extra=extra)
catalog_file_path=filepath('MRC_full_radio_catalog.fits',root=rootdir('FHD'),subdir='catalog_data')
calibration_catalog_file_path=filepath('mwa_commissioning_source_list_add_FHDaug23deconvolve_fornax_and_VLA_pic.sav',root=rootdir('FHD'),subdir='catalog_data')

firstpass=1

calibrate_visibilities=1
recalculate_all=0
export_image=1
cleanup=0
ps_export=0
split_ps_export=1
combine_healpix=0
deconvolve=0
mapfn_recalculate=0
healpix_recalculate=0
flag_visibilities=0
vis_baseline_hist=1
silent=0
save_visibilities=0
calibration_visibilities_subtract=0
return_cal_visibilities=1
snapshot_healpix_export=1
n_avg=2
ps_kbinsize=0.5
ps_kspan=600.
image_filter_fn='filter_uv_uniform'

dimension=2048
max_sources=20000
pad_uv_image=1.
FoV=0
no_ps=1
min_baseline=1.
min_cal_baseline=50.
;ring_radius=10.*pad_uv_image
nfreq_avg=4 ;currently 16 in firstpass
no_rephase=1
combine_obs=0
smooth_width=11.
bandpass_calibrate=1
calibration_polyfit=2
no_restrict_cal_sources=1
cal_mode_fit=1
cal_cable_reflection_fit=150
restrict_hpx_inds=1

kbinsize=0.5
psf_resolution=100

; some new defaults (possibly temporary)
beam_model_version=2
dipole_mutual_coupling_factor=1
calibration_flag_iterate = 0
no_calibration_frequency_flagging=1

;defaults not set in firstpass:
mark_zenith=1
beam_diff_image=1
beam_residual_threshold=0.1
no_fits=1
precess=0 ;set to 1 ONLY for X16 PXX scans (i.e. Drift_X16.pro)
n_pol=2

IF N_Elements(extra) GT 0 THEN cmd_args=extra
extra=var_bundle()
general_obs,_Extra=extra

code_reference_wrapper,file_dirname(fhd_file_list[0])

!except=except
END