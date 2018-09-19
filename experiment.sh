#############################################
# experiment.sh:
#  main program for the experiment
#  input: mus.txt(1) topks.txt(2) alphas.txt(3) data_name(4) response_name(5)  
#  output: AUC.txt table etc.
#############################
# subprograms include:
#################
# preprocess.py 
# description: 
#  prescreening of features: exclude any feature that only has one value 
#  input: data_names,response_name result_path
#  output: preprocess_unused.txt trueY.txt keywords.txt (for ranked precision/recall measure)
################# 
# tsv_to_dta.sh
# description:
#  convert data file to required format for TreeExtra pacakge and generate .attr file 
#  input:  $4(data_name)  $5(response_name)
#          preprocess_unused.txt 
#  output: data_name.dta data_name.attr
#################
# gbt_train
# description:
#   train a GBDT model based on train.dta train.attr,then rank the features and output predictions on test data 
#   for each mu>0 in mus.txt implement the GBFS with penalty mu on new split variables
#   input: train.dta test.dta train.attr topk mu
#   output: feature_score.txt preds.txt
#################
# postprocess.py
# description:
#   take true Y value and preds.txt from different model and 
#   output all kinds of performance (Now only AUC and RMSE) indexes and plots
#   input: all preds.txt and model informations
#   output: AUC.txt RMSE.txt etc.

## all data will be put in /data with form data_name_train.tsv data_name_test.tsv
## result folder will be put in folder result with name "data_name" : /result/data_name/

# naming alias
mus=$1
topks=$2
alphas=$3
data_name=$4
response_name=$5
train_data_ext=data/"$data_name"_train.tsv
test_data_ext=data/"$data_name"_test.tsv
train_data=data/"$data_name"_train
test_data=data/"$data_name"_test

mkdir result/"$data_name"

result_path=result/"$data_name"

convert=/home/cuize/Desktop/experiment/ag_scripts-master/General/tsv_to_dta.sh

GBFS=/home/cuize/Desktop/experiment/TreeExtra/Bin/gbt_train

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

cat "$alphas"|      #read alphas.txt
while read alpha
do
	####GBFS models
	# input: mus traindata testdata attr topk
	# output: preds,attr for GBFStopk 
	cat "$mus"|      #read mus.txt
	while read mu
	      
	do
		"$GBFS" -t "$converted_train_data" -v "$converted_test_data" -r "$all_attr" -mu "$mu" -a "$alpha" -k -1
		mv preds.txt "$result_path"/GBFS_mu"$mu"_preds_alpha"$alpha".txt
		mv boosting_rms.txt "$result_path"/boosting_rms_GBFS_mu"$mu"_alpha"$alpha".txt
		mv log.txt "$result_path"/log_GBFS_mu"$mu"_alpha"$alpha".txt
		rm "$data_name"_train.fs.attr
		if (( $(echo "$mu > 0.0" |bc -l) )); then
			mv feature_scores.txt "$result_path"/feature_scores_GBFS_mu"$mu"_alpha"$alpha".txt
		else
			mv feature_scores.txt "$result_path"/feature_scores_GBDT_alpha"$alpha".txt
			rank_all="$result_path"/feature_scores_GBDT_alpha"$alpha".txt

			cat "$topks"|    #read topks.txt
			while read topk
			do
				python generate_topk.py "$rank_all" "$all_attr" "$topk"    #output temperary .attr file called temp.attr
				"$GBFS" -t "$converted_train_data" -v "$converted_test_data" -r temp.attr -a "$alpha"
				mv preds.txt "$result_path"/GBFSt"$topk"_mu"$mu"_preds_alpha"$alpha".txt
				mv boosting_rms.txt "$result_path"/boosting_rms_GBFSt"$topk"_mu"$mu"_alpha"$alpha".txt
				mv log.txt "$result_path"/log_GBFSt"$topk"_mu"$mu"_alpha"$alpha".txt
			done

		fi


	done
done
rm temp.attr


######## postprocess
