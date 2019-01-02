###################
## test on groupTest and binary search idea (assume data has required format)
## input: tuned_GBFS_a1.txt(1) dataname(2) responseName(3) 
## output: preds.txt boosting_rmse.txt for different tuned parameters
## order in tuned_GBFS_a.txt: mu shrink alpha iterN s

#alias
par1=$1
data_name=$2
response_name=$3
train_data_ext=data/"$data_name"_train.tsv
test_data_ext=data/"$data_name"_test.tsv
train_data=data/"$data_name"_train
test_data=data/"$data_name"_test

mkdir -p result/"$data_name"

result_path=result/"$data_name"

convert=/u/c/u/cuize/GBFS/ag_scripts/General/tsv_to_dta.sh

#BT=/home/cuize/Desktop/experiment/TreeExtra/Bin/bt_train

#GBFS=/home/cuize/Desktop/experiment/TreeExtra/Bin/gbt_train

#GBFS_adapt_r=/home/cuize/Desktop/experiment/TreeExtra_adaptive/Bin/gbt_train

#Adaptive_GBFS_adapt_r=/home/cuize/Desktop/experiment/TreeExtra_adaptive2/Bin/gbt_train

groupTest=/u/c/u/cuize/GBFS/TreeExtra/Bin/gbt_train

#mrr=/home/cuize/Desktop/experiment/ag_scripts/General/mrr
######## preprocess
touch "$result_path"/preprocess_unused.txt
#prescreening of features: exclude any feature that only has one value
#output result_path/preprocess_unused.txt , result_path/trueY.txt and result_path/keywords.txt
#python preprocess.py "$train_data_ext" "$test_data_ext" "$response_name" "$result_path"
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
all_attr=""$result_path"/$data_name"_train.attr

######### model training and prediction for different alpha,mu
touch "$result_path"/groupTest.txt
output="$result_path"/groupTest.txt
echo name mu shrinkage alpha iteration number_of_features s RMSE ROC time>> "$output"

cat "$par1"|      #read parameters
while read pars
do
	mu="$( echo "$pars" |cut -f 1 -d" " )"
	shrink="$( echo "$pars"|cut -f 2 -d" " )"
	alpha="$( echo "$pars"|cut -f 3 -d" "  )"
	iterN="$( echo "$pars"|cut -f 4 -d" " )"
	sIn="$( echo "$pars"|cut -f 5 -d" " )"
#	if (( $(echo "$mu >= 1.0" |bc -l) )); then  #GBFS
#		SECONDS=0
#		name=GBFS_model
#		"$GBFS" -t "$converted_train_data" -v "$converted_test_data" -r "$all_attr" -mu "$mu" -sh "$shrink" -a "$alpha" -n "$iterN" -sub 0.5 -k -1
#		attrn="$(head -1 feature_scores.txt| cut -c  26-)"
#		rms="$(tail -1 boosting_rms.txt)"
 #               mrr_v="$("$mrr" trueY.txt preds.txt groups.txt)"

#	elif (( $(echo "$mu > 0.0" |bc -l) )); then # GBFS_adapt
		SECONDS=0
		name=triggered
		"$groupTest" -t "$converted_train_data" -v "$converted_test_data" -r "$all_attr" -mu "$mu" -sh "$shrink" -a "$alpha" -n "$iterN"  -k 10 -c roc -s "$sIn" 
		attrn="$(head -1 feature_scores.txt| cut -c  26-)"
		rms="$(tail -1 boosting_rms.txt)"
                roc="$(tail -1 boosting_roc.txt)"
                #mrr_v="$("$mrr" trueY.txt preds.txt groups.txt)"
		echo "$name" "$mu" "$shrink" "$alpha" "$iterN" "$attrn" "$sIn"  "$rms" "$roc"  "$SECONDS">> "$output"
		mv preds.txt "$result_path"/"$name"_preds_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
		mv feature_scores.txt "$result_path"/ "$name"_feature_scores_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
                mv time.txt "$result_path"/"$name"_time_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
                mv root_var.txt "$result_path"/"$name"_rootVar_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
                mv boosting_rms.txt "$result_path"/"$name"_boosting_rms_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
                mv boosting_roc.txt "$result_path"/"$name"_boosting_roc_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt

		SECONDS=0
		name=notTriggered
		"$groupTest" -t "$converted_train_data" -v "$converted_test_data" -r "$all_attr" -mu "$mu" -sh "$shrink" -a "$alpha" -n "$iterN"  -k 10 -c roc -s 6000
		attrn="$(head -1 feature_scores.txt| cut -c  26-)"
		rms="$(tail -1 boosting_rms.txt)"
                roc="$(tail -1 boosting_roc.txt)"
 #               mrr_v="$("$mrr" trueY.txt preds.txt groups.txt)"
#	fi
	echo "$name" "$mu" "$shrink" "$alpha" "$iterN" "$attrn" "max" "$rms" "$roc" "$SECONDS">> "$output"
	mv preds.txt "$result_path"/"$name"_preds_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
	mv feature_scores.txt "$result_path"/"$name"_feature_scores_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
        mv time.txt "$result_path"/"$name"_time_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
        mv root_var.txt "$result_path"/"$name"_rootVar_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
        mv boosting_rms.txt "$result_path"/"$name"_boosting_rms_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt
        mv boosting_roc.txt "$result_path"/"$name"_boosting_roc_mu"$mu"_alpha"$alpha"_shrink"$shrink"_itern"$iterN"_attrn"$attrn"_rms"$rms".txt

done

