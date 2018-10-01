#############################################
# tuning.sh:
#  input: mus.txt(1) shrinkage.txt(2) alphas.txt(3) iterNs.txt(4) data_name(5) response_name(6) topk(7)
#  output: tuning.txt store parameter and rmse each line
#############################

# naming alias
mus=$1
shrinks=$2
alphas=$3
iterNs=$4
data_name=$5
response_name=$6
topk=$7
train_data_ext=data/"$data_name"_train_train.tsv
validate_data_ext=data/"$data_name"_train_validate.tsv
train_data=data/"$data_name"_train_train
validate_data=data/"$data_name"_train_validate

mkdir -p result/"$data_name"

result_path=result/"$data_name"

convert=/home/cuize/Desktop/experiment/ag_scripts/General/tsv_to_dta.sh

BT=/home/cuize/Desktop/experiment/TreeExtra/Bin/bt_train

GBFS=/home/cuize/Desktop/experiment/TreeExtra/Bin/gbt_train

GBFS_adapt=/home/cuize/Desktop/experiment/TreeExtra_adaptive/Bin/gbt_train

######## preprocess

#prescreening of features: exclude any feature that only has one value
#output result_path/preprocess_unused.txt , result_path/trueY.txt and result_path/keywords.txt
python preprocess.py "$train_data_ext" "$validate_data_ext" "$response_name" "$result_path"

#converting format
bash "$convert" "$train_data" "$response_name" "$result_path"/preprocess_unused.txt 
bash "$convert" "$validate_data" "$response_name" "$result_path"/preprocess_unused.txt
rm "$validate_data".attr
mv "$train_data".dta "$result_path"/"$data_name"_train_train.dta 
mv "$train_data".attr "$result_path"/"$data_name"_train_train.attr
mv "$validate_data".dta "$result_path"/"$data_name"_train_validate.dta
#now $train_data.dta, $train_data.attr and $validate_data.dta are in "$result_path" folder
converted_train_data="$result_path"/"$data_name"_train_train.dta 
converted_validate_data="$result_path"/"$data_name"_train_validate.dta
all_attr="$result_path"/"$data_name"_train_train.attr

######### model training and prediction for different alpha,mu,shrinkage,iteration
touch "$result_path"/tuning.txt
output="$result_path"/tuning.txt
echo name mu shrinkage alpha iteration number_of_features RMSE time>> "$output"
SECONDS=0
cat "$alphas"|
while read alpha
do
	cat "$mus"|
	while read mu
	do
		if (( $(echo "$mu == 0.0" |bc -l) )); then  #GBDTBTt
			"$BT" -t "$converted_train_data" -v "$converted_validate_data" -r "$all_attr" -a "$alpha" -k -1
			rm preds.txt model.bin bagging_rms.txt "$data_name"_train_train.fs.attr log.txt
			mv feature_scores.txt "$result_path"/feature_scores_BT_alpha"$alpha".txt
			rank_all="$result_path"/feature_scores_BT_alpha"$alpha".txt

		fi
		cat "$shrinks"|
		while read shrink
		do
			cat "$iterNs"|
			while read iterN
			do
				if (( $(echo "$mu >= 1.0" |bc -l) )); then  #GBFS
					name=GBFS_model
					"$GBFS" -t "$converted_train_data" -v "$converted_validate_data" -r "$all_attr" -mu "$mu" -sh "$shrink" -a "$alpha" -n "$iterN" -k -1
					attrn="$(head -1 feature_scores.txt| cut -c  26-)"
					rms="$(tail -1 boosting_rms.txt)"

				elif (( $(echo "$mu > 0.0" |bc -l) )); then # GBFS_adapt
					name=GBFS_adapt_model
					"$GBFS_adapt" -t "$converted_train_data" -v "$converted_validate_data" -r "$all_attr" -mu "$mu" -sh "$shrink" -a "$alpha" -n "$iterN" -k -1
					attrn="$(head -1 feature_scores.txt| cut -c  26-)"
					rms="$(tail -1 boosting_rms.txt)"
				else  # GBDTBTt
					name=GBDTBTt
					python generate_topk.py "$rank_all" "$all_attr" "$topk" "$data_name"    #output temperary .attr file called "$data_name"_temp.attr
					"$GBFS" -t "$converted_train_data" -v "$converted_validate_data" -r "$data_name"_temp.attr -a "$alpha" -sh "$shrink" -n "$iterN" -k -1
					attrn="$(head -1 feature_scores.txt| cut -c  26-)"
					rms="$(tail -1 boosting_rms.txt)"
				fi
				echo "$name" "$mu" "$shrink" "$alpha" "$iterN" "$attrn" "$rms" "$SECONDS">> "$output"
			done
		done
	done
done
rm "$data_name"_temp.attr



