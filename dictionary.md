# FHD Keyword Dictionary
FHD uses keywords to create unique run-specific settings. This dictionary describes the purpose of each keyword, as well as their logic or applicable ranges. Some keywords can override others, which is also documentated.  This is a work in progress; please add keywords as you find them in alphabetical order with their corresponding definition.

## Beam

**beam_offset_time**: calculate the beam at a specific time within the observation. An observation has 112 seconds, with 0 seconds indicating the start of the observation and 112 indicating the end of the observation. <br />
  -*Default*:56 <br />
  -*Range*:0-112 <br />

## Calibration

**allow_sidelobe_cal_sources**: allows FHD to calibrate on sources in the sidelobes. Forces the beam_threshold to 0.01 in order to go down to 1% of the beam to capture sidelobe sources during the generation of a calibration source catalog for the particular observation. <br />
  -*Turn off/on*: 0/1 <br />
  -*Default*: 1 <br />
**amp_degree**: the order of the polynomial fit over the whole band to create calibration solutions for the amplitude of the gain. Setting it to 0 gives a 0th order polynomial fit (one number for the whole band), 1 gives a 1st order polynomial fit (linear fit), 2 gives a 2nd order polynomial fit (quadratic), etc etc. 
  -*Dependency*: calibration_polyfit must be on for the polynomial fitting to occur. <br />
  -*Turn off/on*: undefined/defined <br />
  -*Default*: 2 <br />
**cable_bandpass_fit**: average the calibration solutions across tiles within a cable grouping for the particular instrument. <br />
  -*Dependency*: instrument_config/<instrument>_cable_length.txt <br />
  -*Turn off/on*: 0/1 <br />
  -*Default*: 1 <br />
**cal_mode_fit**: Determines whether calibration will fit for reflection in cables (see following three entries). This will be set if
	`cal_cable_reflection_correct` or `cal_cable_reflection_fit` is set. <br />
  -*Obsolete* - use `cal_cable_reflection_correct` or `cal_cable_reflection_mode_fit` instead. <br />
**cal_cable_reflection_correct**: Use predetermined cable reflection parameters in calibration solutions. <br />
  -*Needs updating*: all cable keywords need a major overhaul <br />
  -Set to 1 to correct all antennas using default tile for instrument (e.g. `FHD/instrument_config/mwa_cable_reflection_coefficients.txt`) <br />
  -OR set to cable length or array of cable lengths to only correct those lengths (e.g. [90,150]), again using default file. <br />
  -OR set to file path with reflection coefficients. <br />
  -*Default*: unset (off) <br />
**cal_cable_reflection_fit**: calculate theoretical cable reflection modes given the velocity and length data stored in a config file. <br />
  -*Needs updating*: all cable keywords need a major overhaul <br />
  -Set to length of cable to fit, or negative length of cable to omit. <br />
  -*Must be used in conjunction with `cal_cable_reflection_mode_fit`* <br />
  -*Default*: 150 <br />
**cal_cable_reflection_mode_fit**: Fits residual gains to reflection mode and coefficient. <br />
  -*Needs updating*: all cable keywords need a major overhaul <br />
  -Takes precidence over `cal_cable_reflection_correct`. <br />
  -*Turn off/on*: 0/1 <br />
  -*Default*: 150 <br />
**calibrate_visibilities**: turn on or turn off calibration of the visilibilities. If turned on, calibration of the dirty, modelling, and subtraction to make a residual occurs. Otherwise, none of these occur. <br />
  -*Turn off/on*: 0/1 <br />
  -*Default*: 1 <br />
**diffuse_calibrate**: a map/model of the diffuse in which to calibrate on. The map/model undergoes a DFT for every pixel, and the contribution from every pixel is added to the model visibilities from which to calibrate on. If no diffuse_model is specified, then this map/model is used for the subtraction model as well. <br />
  -*Default*: filepath('EoR0_diffuse_model_94.sav',root=rootdir('FHD'),subdir='catalog_data') <br />
**phase_degree**: the order of the polynomial fit over the whole band to create calibration solutions for the phase of the gain. Setting it to 0 gives a 0th order polynomial fit (one number for the whole band), 1 gives a 1st order polynomial fit (linear fit), 2 gives a 2nd order polynomial fit (quadratic), etc etc. 
  -*Dependency*: calibration_polyfit must be on for the polynomial fitting to occur. <br />
  -*Turn off/on*: undefined/defined <br />
  -*Default*: 1 <br />
**saved_run_bp**: use a saved bandpass for bandpass calibration. Reads in a text file saved in instrument config which is dependent on pointing number at the moment. Needs updating. <br />
  -*Needs updating*: File name needs more information to descriminate between instruments and bands. Need to have capability to read in saved bandpasses not dependent on cable type.<br />
  -*Dependency*: instrument_config/<pointing number>_bandpass.txt <br />
  -*Turn off/on*: 0/1 <br />
  -*Default*: 1 <br />
**min_cal_baseline**: the minimum baseline length in wavelengths to be used in calibration. <br />
  -*Default*: 50 <br />
**return_cal_visibilities**: <br />
  -*Default*: 1 <br />


catalog_file_path=filepath('MRC_full_radio_catalog.fits',root=rootdir('FHD'),subdir='catalog_data') <br />
calibration_catalog_file_path=filepath('mwa_calibration_source_list.sav',root=rootdir('FHD'),subdir='catalog_data') <br />
bandpass_calibrate=1 <br />
calibration_polyfit=2 <br />
no_restrict_cal_sources=1 <br /> 

## Diffuse

## Model

## Recalculation

**recalculate_all**: <br />
  -*Turn off/on*: 0/1 <br />
  -*Default*:0 <br />

mapfn_recalculate=0
healpix_recalculate=0

## Export

ps_export=0
split_ps_export=1
snapshot_healpix_export=1

cleanup=0
combine_healpix=0
deconvolve=0

flag_visibilities=0
vis_baseline_hist=1
silent=0
save_visibilities=1
calibration_visibilities_subtract=0

n_avg=2
ps_kbinsize=0.5
ps_kspan=600.
image_filter_fn='filter_uv_uniform'
deconvolution_filter='filter_uv_uniform'

uvfits_version=4
uvfits_subversion=1


dimension=2048
max_sources=20000
pad_uv_image=1.
FoV=0
no_ps=1
min_baseline=1.

ring_radius=10.*pad_uv_image
nfreq_avg=16
no_rephase=1
combine_obs=0
smooth_width=32.


restrict_hpx_inds=1

kbinsize=0.5
psf_resolution=100

; some new defaults (possibly temporary)
beam_model_version=2
dipole_mutual_coupling_factor=1
calibration_flag_iterate = 0

no_calibration_frequency_flagging=1

; even newer defaults
export_images=1
;cal_cable_reflection_correct=150
cal_cable_reflection_mode_fit=150
model_catalog_file_path=filepath('mwa_calibration_source_list.sav',root=rootdir('FHD'),subdir='catalog_data')
model_visibilities=0

allow_sidelobe_model_sources=1