###################
# generate models with tuned parameters
## input: tuned.txt(1) data_name(2) response_name(3) topk(4)
## output: preds.txt boosting_rmse.txt for different tuned parameters
## order in tuned.txt: mu shrink alpha iterN

#alias
par=$1
data_name=$2
response_name=$3
topk=$4
train_data_ext=data/"$data_name"_train.tsv
test_data_ext=data/"$data_name"_test.tsv
train_data=data/"$data_name"_train
test_data=data/"$data_name"_test

mkdir -p result/"$data_name"/tuned

result_path=result/"$data_name"/tuned

convert=/home/cuize/Desktop/experiment/ag_scripts/General/tsv_to_dta.sh

BT=/home/cuize/Desktop/experiment/TreeExtra/Bin/bt_train

GBFS=/home/cuize/Desktop/experiment/TreeExtra/Bin/gbt_train

GBFS_adapt1=/home/cuize/Desktop/experiment/TreeExtra_adaptive/Bin/gbt_train

GBFS_adapt2=/home/cuize/Desktop/experiment/TreeExtra_adaptive2/Bin/gbt_train


######## preprocess

#prescreening of features: exclude any feature that only has one value
#output result_path/preprocess_unused.txt , result_path/trueY.txt and result_path/keywords.txt
python preprocess.py "$train_data_ext" "$test_data_ext" "$response_name" "$result_path"

#converting format
bash "$convert" "$train_data" "$response_name" "$result_path"/preprocess_unused.txt 
bash "$convert" "$test_data" "$response_name" "$result_path"/preprocess_unused.txt
rm "$test_data".attr
mv "$train_data".dta "$result_path"/"$data_name"_train.dta 
mv "$train_data".attr "$result_path"/"$data_name"_train.attr
mv "$test_data".dta "$result_path"/"$data_name"_test.dta
#now $train_data.dta, $train_data.attr and $test_data.dta are in "$result_path" folder
converted_train_data="$result_path"/"$data_name"_train.dta 
converted_test_data="$result_path"/"$data_name"_test.dta
all_attr="$result_path"/"$data_name"_train.attr
######### model training and prediction for different alpha,mu
touch "$result_path"/tuned.txt
output="$result_path"/tuned.txt
echo name mu shrinkage alpha iteration number_of_features RMSE ROC time>> "$output"

cat "$par"|      #read parameters
while read pars
do
	mu="$( echo "$pars" |cut -f 1 -d" " )"
	shrink="$( echo "$pars"|cut -f 2 -d" " )"
	alpha="$( echo "$pars"|cut -f 3 -d" "  )"
	iterN="$( echo "$pars"|cut -f 4 -d" " )"
	if (( $(echo "$mu >= 1.0" |bc -l) )); then  #GBFS
		SECONDS=0
		name=GBFS_model
		"$GBFS" -t "$converted_train_data" -v "$converted_test_data" -r "$all_attr" -mu "$mu" -sh "$shrink" -a "$alpha" -n "$iterN" -k -1 -c roc
		attrn="$(head -1 feature_scores.txt| cut -c  26-)"
		rms="$(tail -1 boosting_rms.txt)"
                roc="$(tail -1 boosting_roc.txt)"
	elif (( $(echo "$mu > 0.0" |bc -l) )); then # GBFS_adapt
		SECONDS=0
		name=GBFS_adapt1_model
		"$GBFS_adapt1" -t "$converted_train_data" -v "$converted_test_data" -r "$all_attr" -mu "$mu" -sh "$shrink" -a "$alpha" -n "$iterN" -k -1 -c roc
		attrn="$(head -1 feature_scores.txt| cut -c  26-)"
		rms="$(tail -1 boosting_rms.txt)"
                roc="$(tail -1 boosting_roc.txt)"
		#echo "$name" "$mu" "$shrink" "$alpha" "$iterN" "$attrn" "$rms" "$roc" "$SECONDS">> "$output"
		#mv preds.txt "$result_path"/"$name"_preds_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
		#mv feature_scores.txt "$result_path"/"$name"_feature_scores_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
		#name=GBFS_adapt2_model
		#"$GBFS_adapt2" -t "$converted_train_data" -v "$converted_test_data" -r "$all_attr" -mu "$mu" -sh "$shrink" -a "$alpha" -n "$iterN" -k -1
		#attrn="$(head -1 feature_scores.txt| cut -c  26-)"
		#rms="$(tail -1 boosting_rms.txt)"
	else  # GBDTBTt
		SECONDS=0
		name=GBDTBTt
		"$BT" -t "$converted_train_data" -v "$converted_test_data" -r "$all_attr" -a "$alpha" -k -1
		rm preds.txt model.bin bagging_rms.txt "$data_name"_train.fs.attr log.txt
		mv feature_scores.txt "$result_path"/feature_scores_BT_alpha"$alpha".txt
		rank_all="$result_path"/feature_scores_BT_alpha"$alpha".txt
		python generate_topk.py "$rank_all" "$all_attr" "$topk" "$data_name"    #output temperary .attr file called "$data_name"_temp.attr
		"$GBFS" -t "$converted_train_data" -v "$converted_test_data" -r "$data_name"_temp.attr -a "$alpha" -sh "$shrink" -n "$iterN" -k -1 -c roc
		attrn="$(head -1 feature_scores.txt| cut -c  26-)"
		rms="$(tail -1 boosting_rms.txt)"
                roc="$(tail -1 boosting_roc.txt)"
	fi
	echo "$name" "$mu" "$shrink" "$alpha" "$iterN" "$attrn" "$rms" "$roc" "$SECONDS">> "$output"
	mv preds.txt "$result_path"/"$name"_preds_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
	mv feature_scores.txt "$result_path"/"$name"_feature_scores_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt

done
rm "$data_name"_temp.attr




