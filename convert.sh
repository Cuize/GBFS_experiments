###################
## convert format for train test validate 
## input: data_name(1) response_name(2) 
## output: .dta .attr

#alias
data_name=$1
response_name=$2
train_data_ext=data/"$data_name"_train.tsv
test_data_ext=data/"$data_name"_test.tsv
train_train_data_ext=data/"$data_name"_train_train.tsv
train_validate_data_ext=data/"$data_name"_train_validate.tsv
train_data=data/"$data_name"_train
test_data=data/"$data_name"_test
train_train_data=data/"$data_name"_train_train
train_validate_data=data/"$data_name"_train_validate

mkdir -p result/"$data_name"

result_path=result/"$data_name"

convert=/home/cuize/Desktop/experiment/ag_scripts/General/tsv_to_dta.sh


#BT=/home/cuize/Desktop/experiment/TreeExtra/Bin/bt_train

#GBFS=/home/cuize/Desktop/experiment/TreeExtra/Bin/gbt_train

#GBFS_adapt1=/home/cuize/Desktop/experiment/TreeExtra_adaptive/Bin/gbt_train


#GBFS_adapt2=/home/cuize/Desktop/experiment/TreeExtra_adaptive2/Bin/gbt_train


######## preprocess

#prescreening of features: exclude any feature that only has one value
#output result_path/preprocess_unused.txt , result_path/trueY.txt and result_path/keywords.txt
python preprocess.py "$train_data_ext" "$test_data_ext" "$response_name" "$result_path"

#converting format
bash "$convert" "$train_data" "$response_name" "$result_path"/preprocess_unused.txt 
bash "$convert" "$test_data" "$response_name" "$result_path"/preprocess_unused.txt
bash "$convert" "$train_train_data" "$response_name" "$result_path"/preprocess_unused.txt
bash "$convert" "$train_validate_data" "$response_name" "$result_path"/preprocess_unused.txt
rm "$test_data".attr
rm "$train_train_data".attr
rm "$train_validate_data".attr
mv "$train_data".dta "$result_path"/"$data_name"_train.dta 
mv "$train_data".attr "$result_path"/"$data_name"_train.attr
mv "$test_data".dta "$result_path"/"$data_name"_test.dta
mv "$train_train_data".dta "$result_path"/"$data_name"_train_train.dta
mv "$train_validate_data".dta "$result_path"/"$data_name"_train_validate.dta
#now $train_data.dta, $train_data.attr and $test_data.dta are in "$result_path" folder
#converted_train_data="$result_path"/"$data_name"_train.dta 
#converted_test_data="$result_path"/"$data_name"_test.dta
#all_attr="$result_path"/"$data_name"_train.attr
