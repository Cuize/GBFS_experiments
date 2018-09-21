#############################################
# gbdt_btfs.sh:
#  main program for generating result for GBDT with BT ranked features (when we already converted the data to dta and attr)
#  input: topks.txt(1) alphas.txt(2) data_name(3) 
#  output: preds.txt indexed by alpha and topk
#############################
# subprograms include:
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
topks=$1
alphas=$2
data_name=$3

mkdir -p result/"$data_name"

result_path=result/"$data_name"
converted_train_data="$result_path"/"$data_name"_train.dta 
converted_test_data="$result_path"/"$data_name"_test.dta
all_attr="$result_path"/"$data_name"_train.attr

GBFS=../TreeExtra/Bin/gbt_train

BT=../TreeExtra/Bin/bt_train


######### model training and prediction for different alpha,mu

cat "$alphas"|      #read alphas.txt
while read alpha
do
	"$BT" -t "$converted_train_data" -v "$converted_test_data" -r "$all_attr" -a "$alpha" -k -1
	rm preds.txt model.bin bagging_rms.txt "$data_name"_train.fs.attr 
	mv log.txt "$result_path"/log_BT_alpha"$alpha".txt
	mv feature_scores.txt "$result_path"/feature_scores_BT_alpha"$alpha".txt
	rank_all="$result_path"/feature_scores_BT_alpha"$alpha".txt
	cat "$topks"|    #read topks.txt
	while read topk
	do
		python generate_topk.py "$rank_all" "$all_attr" "$topk" "$data_name"    #output temperary .attr file called "$data_name"_temp.attr
		"$GBFS" -t "$converted_train_data" -v "$converted_test_data" -r "$data_name"_temp.attr -a "$alpha"
		mv preds.txt "$result_path"/GBDTBTt"$topk"_preds_alpha"$alpha".txt
		mv boosting_rms.txt "$result_path"/boosting_rms_GBDTBTt"$topk"_alpha"$alpha".txt
		mv log.txt "$result_path"/log_GBDTBTt"$topk"_alpha"$alpha".txt
	done
done
rm "$data_name"_temp.attr


######## postprocess
