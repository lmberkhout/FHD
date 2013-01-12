PRO beam_setup_init,gain_array_X,gain_array_Y,filename=filename,data_directory=data_directory
IF not Keyword_Set(data_directory) THEN vis_path_default,data_directory,filename ;set default if not supplied
ext='.UVFITS'
tile_gain_x_filename='tile_gains_x'
tile_gain_y_filename='tile_gains_y'

;indices of antenna_gain_arr correspond to these antenna locations (add 1 for gain_array):
;12 13 14 15
;8  9  10 11
;4  5  6  7
;0  1  2  3 
ntiles=32.
nfreq_bin=24. ;by coarse frequency channel
;gain_array=fltarr(17,nfreq_bin*ntiles)+1. ;17 columns: first is tile number, 16 for each dipole in a tile
base_gain=fltarr(16)+1.
base_gain[[0,3,12,15]]=1.
base_gain[[1,2,4,7,8,11,13,14]]=1.
base_gain=[1.,base_gain] ;17 columns: first is tile number, 16 for each dipole in a tile
gain_array=base_gain#(fltarr(nfreq_bin*ntiles)+1.)
gain_array[0,*]=Floor(indgen(nfreq_bin*ntiles)/nfreq_bin)+1

tile_gain_x_filepath=filepath(tile_gain_x_filename,root_dir=rootdir('mwa'),subdir=data_directory)
tile_gain_y_filepath=filepath(tile_gain_y_filename,root_dir=rootdir('mwa'),subdir=data_directory)

;do not overwrite a gain_array if one already exists (it's either real data, or the same default data as this!)
IF file_test(tile_gain_x_filepath) EQ 0 THEN BEGIN
    gain_array_X=gain_array
    textfast,gain_array_X,/write,filename=tile_gain_x_filename,root=rootdir('mwa'),filepathfull=data_directory
ENDIF ELSE textfast,gain_array_X,/read,filename=tile_gain_x_filename,root=rootdir('mwa'),filepathfull=data_directory

IF file_test(tile_gain_y_filepath) EQ 0 THEN BEGIN
    gain_array_Y=gain_array_X
    textfast,gain_array_Y,/write,filename=tile_gain_y_filename,root=rootdir('mwa'),filepathfull=data_directory
ENDIF ELSE textfast,gain_array_Y,/read,filename=tile_gain_y_filename,root=rootdir('mwa'),filepathfull=data_directory

END